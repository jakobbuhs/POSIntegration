//
//  webhooks.ts
//  POS-app-shopify
//
//  Created by Jakob Buhs on 28/10/2025.
//

import { Router } from "express";
import crypto from "crypto";
import { prisma } from "../db/client";
import { createOrderInShopify } from "../services/shopifyAdmin";
import { maybeSendTerminalConfirmation } from "../services/terminalWebhook";
import { findTransactionByClientId, mapSumUpStatus } from "../services/sumupCloud";
import type { SumUpTransaction } from "../services/sumupCloud";

const r = Router();

// Simple HMAC header check (confirm header name & algorithm in your dashboard docs)
function verifySignature(raw: string, signature: string, secret: string) {
  if (!signature || !secret) return false;
  const expected = crypto.createHmac("sha256", secret).update(raw).digest("hex");
  const expectedBuf = Buffer.from(expected, "hex");
  const hexCandidate = /^[0-9a-f]+$/i.test(signature)
    ? Buffer.from(signature, "hex")
    : null;
  const base64Candidate = /^[0-9A-Za-z+/=]+$/.test(signature)
    ? Buffer.from(signature, "base64")
    : null;
  const actual =
    hexCandidate && hexCandidate.length === expectedBuf.length
      ? hexCandidate
      : base64Candidate;
  if (!actual || actual.length !== expectedBuf.length) {
    return false;
  }
  if (actual.length !== expectedBuf.length) {
    return false;
  }
  return crypto.timingSafeEqual(expectedBuf, actual);
}

r.post("/sumup", expressRawJson, async (req, res) => {
  const rawBody = (req as any).rawBody as string;
  const sig = req.header("x-sumup-signature") || "";
  const secret = process.env.SUMUP_WEBHOOK_SECRET || "";

  if (secret && !verifySignature(rawBody, sig, secret)) {
    return res.status(401).send("Invalid signature");
  }

  let evt: any;
  try {
    evt = JSON.parse(rawBody || "{}");
  } catch (err) {
    console.error("Failed to parse SumUp webhook payload", err);
    return res.status(400).send("Invalid JSON");
  }

  const payload = (evt.payload || evt.data || {}) as SumUpTransaction;
  const clientTxnId =
    payload.client_transaction_id || (payload as any).clientTransactionId || null;
  const statusRaw = ((payload.status as string | undefined) || "").trim() ||
    ((evt.status as string | undefined) || "").trim();
  const mapped = mapSumUpStatus(statusRaw || undefined);

  let attempt = clientTxnId
    ? await prisma.paymentAttempt.findFirst({ where: { clientTransactionId: clientTxnId } })
    : null;

  if (!attempt && payload.transaction_id) {
    attempt = await prisma.paymentAttempt.findFirst({ where: { transactionId: payload.transaction_id } });
  }

  let hydratedTx: SumUpTransaction = { ...payload };

  if (!attempt && clientTxnId) {
    try {
      const lookedUp = await findTransactionByClientId(clientTxnId);
      if (lookedUp) {
        hydratedTx = { ...lookedUp, ...payload };
        const foreignId =
          lookedUp.foreign_transaction_id ||
          (lookedUp as any).foreignId ||
          lookedUp.metadata?.foreign_transaction_id;
        if (foreignId) {
          attempt = await prisma.paymentAttempt.findUnique({ where: { orderRef: foreignId } });
        }
      }
    } catch (lookupErr) {
      console.warn("SumUp transaction lookup from webhook failed", lookupErr);
    }
  }

  if (!attempt) {
    console.warn("SumUp webhook received without matching attempt", {
      clientTransactionId: clientTxnId,
      transactionId: payload.transaction_id,
      status: statusRaw
    });
    return res.status(202).json({ ok: false, reason: "attempt-not-found" });
  }

  const resolvedStatus = mapped === "PENDING" ? attempt.status : mapped;

  const updateData: any = {
    status: resolvedStatus,
    transactionId: hydratedTx.transaction_id ?? attempt.transactionId ?? null,
    clientTransactionId:
      attempt.clientTransactionId ??
      hydratedTx.client_transaction_id ??
      (hydratedTx as any).clientTransactionId ??
      clientTxnId,
    scheme: hydratedTx.scheme ?? attempt.scheme ?? null,
    last4: hydratedTx.last4 ?? attempt.last4 ?? null,
    approvalCode: (hydratedTx as any).approval_code ?? attempt.approvalCode ?? null,
    message: (hydratedTx as any).message ?? attempt.message ?? null
  };

  if (hydratedTx.reader_id) {
    updateData.readerId = hydratedTx.reader_id;
  }
  if (hydratedTx.amount?.value != null) {
    updateData.amountMinor = hydratedTx.amount.value;
  }
  if (hydratedTx.amount?.currency) {
    updateData.currency = hydratedTx.amount.currency;
  } else if (hydratedTx.currency) {
    updateData.currency = hydratedTx.currency;
  }

  attempt = await prisma.paymentAttempt.update({
    where: { id: attempt.id },
    data: updateData
  });

  // On success → create Shopify order if not already created
  if (attempt.status === "APPROVED" && !attempt.shopifyOrderId) {
    try {
      const order = await createOrderInShopify({
        cart: (attempt.cartJson as any) || [],
        customer: (attempt.customerJson as any) || {},
        amountMinor: attempt.amountMinor,
        currency: attempt.currency,
        transactionId: attempt.transactionId!,
        approvalCode: attempt.approvalCode || undefined,
        scheme: attempt.scheme || undefined,
        last4: attempt.last4 || undefined,
      });
      if (order?.id) {
        attempt = await prisma.paymentAttempt.update({
          where: { id: attempt.id },
          data: { shopifyOrderId: order.id }
        });
      }
    } catch (e) {
      // keep webhook success, the POS can retry order creation with /recover later
      console.error("Shopify order create failed:", e);
    }
  }

  try {
    const result = await maybeSendTerminalConfirmation(attempt, {
      source: "sumup-webhook",
      sumupTx: hydratedTx
    });
    if (result.sent) {
      attempt = result.attempt;
    } else if (result.reason !== "already-notified") {
      console.info("Skipped terminal confirmation", {
        orderRef: attempt.orderRef,
        reason: result.reason,
        verification: result.verification
      });
    }
  } catch (e) {
    console.error("Terminal confirmation webhook (sumup webhook) failed", e);
  }

  return res.json({ ok: true });
});

// Helper to capture raw body for HMAC verify
function expressRawJson(req: any, res: any, next: any) {
  let data = "";
  req.setEncoding("utf8");
  req.on("data", (chunk: string) => (data += chunk));
  req.on("end", () => {
    (req as any).rawBody = data;
    try { req.body = JSON.parse(data || "{}"); } catch { req.body = {}; }
    next();
  });
}

export default r;
