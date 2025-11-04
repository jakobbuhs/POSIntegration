import type { PaymentAttempt } from "@prisma/client";
import { cfg } from "../config";
import { prisma } from "../db/client";
import {
  findTransactionByClientId,
  findTransactionByForeignId,
  mapSumUpStatus,
  SumUpTransaction
} from "./sumupCloud";
import { fetchWithTimeout, Response, HttpTimeoutError } from "./http";

const FINAL_STATUSES = new Set<PaymentAttempt["status"]>([
  "APPROVED",
  "DECLINED",
  "CANCELLED",
  "ERROR",
  "TIMEOUT"
]);

type NotifyOptions = {
  source?: string;
  sumupTx?: SumUpTransaction | null;
};

export type TerminalVerificationResult =
  | {
      confirmed: true;
      source: "provided" | "sumup-api";
      status: PaymentAttempt["status"] | null;
      matchesOrderRef: boolean;
      matchesClientTransactionId: boolean;
      transactionId: string | null;
      clientTransactionId: string | null;
      amount: { currency: string | null; value: number | null };
    }
  | {
      confirmed: false;
      source: "provided" | "sumup-api";
      error: string;
    };

type NotificationResult =
  | { sent: true; attempt: PaymentAttempt; verification: TerminalVerificationResult }
  | {
      sent: false;
      reason:
        | "missing-url"
        | "non-final-status"
        | "already-notified"
        | "verification-failed";
      verification?: TerminalVerificationResult;
    };

export type TerminalConfirmationResult = NotificationResult;

export async function maybeSendTerminalConfirmation(
  attempt: PaymentAttempt,
  options: NotifyOptions = {}
): Promise<TerminalConfirmationResult> {
  const url = cfg.webhooks.terminalConfirmationUrl?.trim();
  if (!url) {
    return { sent: false, reason: "missing-url" };
  }

  if (!FINAL_STATUSES.has(attempt.status)) {
    return { sent: false, reason: "non-final-status" };
  }

  if (attempt.terminalWebhookNotifiedAt) {
    return { sent: false, reason: "already-notified" };
  }

  const verification = await buildVerification(attempt, options.sumupTx);

  if (!verification.confirmed) {
    return { sent: false, reason: "verification-failed", verification };
  }

  const payload = {
    attemptId: attempt.id,
    orderRef: attempt.orderRef,
    status: attempt.status,
    transactionId: attempt.transactionId,
    clientTransactionId: attempt.clientTransactionId,
    readerId: attempt.readerId,
    amountMinor: attempt.amountMinor,
    currency: attempt.currency,
    message: attempt.message,
    scheme: attempt.scheme,
    last4: attempt.last4,
    approvalCode: attempt.approvalCode,
    shopifyOrderId: attempt.shopifyOrderId,
    verification,
    source: options.source ?? "unknown",
    sentAt: new Date().toISOString(),
  };

  let res: Response;
  try {
    res = await fetchWithTimeout(
      url,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
      },
      10000
    );
  } catch (err) {
    if (err instanceof HttpTimeoutError) {
      throw new Error(`Terminal confirmation webhook timed out after ${err.timeoutMs}ms`);
    }
    throw err;
  }

  if (!res.ok) {
    const body = await safeRead(res);
    throw new Error(`Terminal confirmation webhook failed ${res.status}: ${body}`);
  }

  const notified = await prisma.paymentAttempt.update({
    where: { id: attempt.id },
    data: { terminalWebhookNotifiedAt: new Date() }
  });

  return { sent: true, attempt: notified, verification };
}

async function buildVerification(
  attempt: PaymentAttempt,
  provided?: SumUpTransaction | null
): Promise<TerminalVerificationResult> {
  let tx: SumUpTransaction | null | undefined = provided ?? null;
  let source: "provided" | "sumup-api" = provided ? "provided" : "sumup-api";
  const errors: string[] = [];

  if (!tx && attempt.clientTransactionId) {
    try {
      tx = await findTransactionByClientId(attempt.clientTransactionId);
    } catch (e) {
      errors.push(`client-id lookup failed: ${(e as Error).message}`);
      tx = null;
    }
  }

  if (!tx) {
    try {
      tx = await findTransactionByForeignId(attempt.orderRef);
    } catch (e) {
      errors.push(`foreign-id lookup failed: ${(e as Error).message}`);
      tx = null;
    }
  }

  if (!tx) {
    return {
      confirmed: false,
      source,
      error: errors.join("; ") || "not-found"
    };
  }

  const status = tx.status ? mapSumUpStatus(tx.status) : null;
  const matchesOrderRef =
    tx.foreign_transaction_id === attempt.orderRef ||
    (tx as any).foreignId === attempt.orderRef ||
    tx.metadata?.foreign_transaction_id === attempt.orderRef;
  const matchesClientTransactionId = attempt.clientTransactionId
    ? tx.client_transaction_id === attempt.clientTransactionId ||
      (tx as any).clientTransactionId === attempt.clientTransactionId
    : false;

  return {
    confirmed: true,
    source,
    status,
    matchesOrderRef,
    matchesClientTransactionId,
    transactionId: tx.transaction_id || tx.id || null,
    clientTransactionId: tx.client_transaction_id || (tx as any).clientTransactionId || null,
    amount: {
      currency: tx.amount?.currency ?? (tx as any).currency ?? null,
      value: tx.amount?.value ?? null
    }
  };
}

async function safeRead(res: Response) {
  try {
    return await res.text();
  } catch {
    return "<no-body>";
  }
}
