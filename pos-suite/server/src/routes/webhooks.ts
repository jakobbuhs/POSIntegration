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

const r = Router();

// Simple HMAC header check (confirm header name & algorithm in your dashboard docs)
function verifySignature(raw: string, signature: string, secret: string) {
  if (!signature || !secret) return false;
  const expected = crypto.createHmac("sha256", secret).update(raw).digest("hex");
  const actual = Buffer.from(signature);
  const expectedBuf = Buffer.from(expected);
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

  const data = (evt.data || {}) as SumUpTransaction;
  const foreignId = data.foreign_transaction_id || data.foreignId || ""; // your orderRef
  const statusMap: Record<string, "APPROVED"|"DECLINED"|"CANCELLED"|"ERROR"> = {
    "SUCCESSFUL": "APPROVED", "APPROVED": "APPROVED",
    "DECLINED": "DECLINED", "FAILED": "ERROR", "CANCELLED": "CANCELLED"
  };
  const mapped = statusMap[(data.status || "").toUpperCase()] || "ERROR";

  // Upsert the attempt
  let attempt = await prisma.paymentAttempt.upsert({
    where: { orderRef: foreignId },
    update: {
      status: mapped,
      transactionId: data.transaction_id || null,
      clientTransactionId: data.client_transaction_id || null,
      amountMinor: data.amount?.value ?? undefined,
      currency: data.amount?.currency ?? undefined,
      readerId: data.reader_id || undefined,
      scheme: data.scheme || undefined,
      last4: data.last4 || undefined,
      approvalCode: (data as any).approval_code || undefined,
      message: (data as any).message || null,
    },
    create: {
      orderRef: foreignId,
      readerId: data.reader_id || "unknown",
      amountMinor: data.amount?.value ?? 0,
      currency: data.amount?.currency ?? "NOK",
      status: mapped,
      transactionId: data.transaction_id || null,
      clientTransactionId: data.client_transaction_id || null,
      scheme: data.scheme || undefined,
      last4: data.last4 || undefined,
      approvalCode: (data as any).approval_code || undefined,
      message: (data as any).message || null,
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
      attempt = await prisma.paymentAttempt.update({
        where: { id: attempt.id },
        data: { shopifyOrderId: order.id }
      });
    } catch (e) {
      // keep webhook success, the POS can retry order creation with /recover later
      console.error("Shopify order create failed:", e);
    }
  }

  try {
    const result = await maybeSendTerminalConfirmation(attempt, {
      source: "sumup-webhook",
      sumupTx: data
    });
    if (result.sent) {
      attempt = result.attempt;
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
