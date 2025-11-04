import fetch, { Response } from "node-fetch";
import type { PaymentAttempt } from "@prisma/client";
import { cfg } from "../config";
import { prisma } from "../db/client";
import { findTransactionByForeignId, mapSumUpStatus } from "./sumupCloud";

const FINAL_STATUSES = new Set<PaymentAttempt["status"]>([
  "APPROVED",
  "DECLINED",
  "CANCELLED",
  "ERROR",
  "TIMEOUT"
]);

type SumUpTransaction = {
  transaction_id?: string;
  id?: string;
  status?: string;
  amount?: { currency?: string; value?: number };
  foreign_transaction_id?: string;
  foreignId?: string;
  metadata?: Record<string, unknown>;
  [key: string]: unknown;
};

type NotifyOptions = {
  source?: string;
  sumupTx?: SumUpTransaction | null;
};

export async function maybeSendTerminalConfirmation(
  attempt: PaymentAttempt,
  options: NotifyOptions = {}
) {
  const url = cfg.webhooks.terminalConfirmationUrl?.trim();
  if (!url) {
    return { sent: false, reason: "missing-url" } as const;
  }

  if (!FINAL_STATUSES.has(attempt.status)) {
    return { sent: false, reason: "non-final-status" } as const;
  }

  if (attempt.terminalWebhookNotifiedAt) {
    return { sent: false, reason: "already-notified" } as const;
  }

  const verification = await buildVerification(attempt, options.sumupTx);

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

  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload)
  });

  if (!res.ok) {
    const body = await safeRead(res);
    throw new Error(`Terminal confirmation webhook failed ${res.status}: ${body}`);
  }

  const notified = await prisma.paymentAttempt.update({
    where: { id: attempt.id },
    data: { terminalWebhookNotifiedAt: new Date() }
  });

  return { sent: true, attempt: notified } as const;
}

async function buildVerification(
  attempt: PaymentAttempt,
  provided?: SumUpTransaction | null
) {
  let tx: SumUpTransaction | null | undefined = provided ?? null;
  let source: "provided" | "sumup-api" = provided ? "provided" : "sumup-api";
  let error: string | null = null;

  if (!tx) {
    try {
      tx = await findTransactionByForeignId(attempt.orderRef);
    } catch (e) {
      error = (e as Error).message;
      tx = null;
    }
  }

  if (!tx) {
    return {
      confirmed: false,
      source,
      error: error ?? "not-found"
    } as const;
  }

  const status = tx.status ? mapSumUpStatus(tx.status) : null;
  const matchesOrderRef =
    tx.foreign_transaction_id === attempt.orderRef ||
    (tx as any).foreignId === attempt.orderRef ||
    tx.metadata?.foreign_transaction_id === attempt.orderRef;

  return {
    confirmed: true,
    source,
    status,
    matchesOrderRef,
    transactionId: tx.transaction_id || tx.id || null,
    amount: {
      currency: tx.amount?.currency ?? null,
      value: tx.amount?.value ?? null
    }
  } as const;
}

async function safeRead(res: Response) {
  try {
    return await res.text();
  } catch {
    return "<no-body>";
  }
}
