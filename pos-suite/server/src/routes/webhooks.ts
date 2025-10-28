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

const r = Router();

// Simple HMAC header check (confirm header name & algorithm in your dashboard docs)
function verifySignature(raw: string, signature: string, secret: string) {
  if (!signature || !secret) return false;
  const expected = crypto.createHmac("sha256", secret).update(raw).digest("hex");
  return crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(signature));
}

r.post("/sumup", expressRawJson, async (req, res) => {
  const rawBody = (req as any).rawBody as string;
  const sig = req.header("x-sumup-signature") || "";
  const secret = process.env.SUMUP_WEBHOOK_SECRET || "";

  if (!verifySignature(rawBody, sig, secret)) {
    return res.status(401).send("Invalid signature");
  }

  const evt = JSON.parse(rawBody);

  // Example payload shape (adjust fields to what SumUp actually posts)
  // evt.data: { foreign_transaction_id, client_transaction_id, transaction_id, status, amount, currency,
  //             reader_id, scheme, last4, approval_code }

  const data = evt.data || {};
  const foreignId = data.foreign_transaction_id || data.foreignId || ""; // your orderRef
  const statusMap: Record<string, "APPROVED"|"DECLINED"|"CANCELLED"|"ERROR"> = {
    "SUCCESSFUL": "APPROVED", "APPROVED": "APPROVED",
    "DECLINED": "DECLINED", "FAILED": "ERROR", "CANCELLED": "CANCELLED"
  };
  const mapped = statusMap[(data.status || "").toUpperCase()] || "ERROR";

  // Upsert the attempt
  const attempt = await prisma.paymentAttempt.upsert({
    where: { orderRef: foreignId },
    update: {
      status: mapped,
      transactionId: data.transaction_id || null,
      clientTransactionId: data.client_transaction_id || null,
      amountMinor: data.amount?.value || undefined,
      currency: data.amount?.currency || undefined,
      readerId: data.reader_id || undefined,
      scheme: data.scheme || undefined,
      last4: data.last4 || undefined,
      approvalCode: data.approval_code || undefined,
      message: data.message || null,
    },
    create: {
      orderRef: foreignId,
      readerId: data.reader_id || "unknown",
      amountMinor: data.amount?.value || 0,
      currency: data.amount?.currency || "NOK",
      status: mapped,
      transactionId: data.transaction_id || null,
      clientTransactionId: data.client_transaction_id || null,
      scheme: data.scheme || undefined,
      last4: data.last4 || undefined,
      approvalCode: data.approval_code || undefined,
      message: data.message || null,
    }
  });

  // On success → create Shopify order if not already created
  if (attempt.status === "APPROVED" && !attempt.shopifyOrderId) {
    try {
      const order = await createOrderInShopify({
        cart: [], // If you need cart lines, store them in PaymentAttempt at checkout start
        customer: {}, // same as above: store minimal customer info at start
        amountMinor: attempt.amountMinor,
        currency: attempt.currency,
        transactionId: attempt.transactionId!,
        approvalCode: attempt.approvalCode || undefined,
        scheme: attempt.scheme || undefined,
        last4: attempt.last4 || undefined,
      });
      await prisma.paymentAttempt.update({
        where: { id: attempt.id },
        data: { shopifyOrderId: order.id }
      });
    } catch (e) {
      // keep webhook success, the POS can retry order creation with /recover later
      console.error("Shopify order create failed:", e);
    }
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
