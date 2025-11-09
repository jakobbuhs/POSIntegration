//
//  webhooks.ts
//  POS-app-shopify
//
//  Webhook handlers for SumUp payment events
//

import { Router } from "express";
import crypto from "crypto";
import { prisma } from "../db/client";
import { createOrderInShopify } from "../services/shopifyAdmin";
import { maybeSendTerminalConfirmation } from "../services/terminalWebhook";
import { mapSumUpStatus } from "../services/sumupCloud";
import type { SumUpTransaction } from "../services/sumupCloud";

const r = Router();

/**
 * Verify SumUp webhook signature
 * SumUp sends: X-SumUp-Signature: sha256=<hex>
 */
function verifySignature(raw: string, signature: string, secret: string): boolean {
  if (!signature || !secret) return false;
  
  // Remove "sha256=" prefix if present
  const signaturePart = signature.startsWith("sha256=")
    ? signature.slice(7)
    : signature;
  
  const expected = crypto
    .createHmac("sha256", secret)
    .update(raw, "utf8")
    .digest("hex");
  
  try {
    const actual = Buffer.from(signaturePart, "hex");
    const expectedBuf = Buffer.from(expected, "hex");
    
    if (actual.length !== expectedBuf.length) {
      return false;
    }
    
    return crypto.timingSafeEqual(expectedBuf, actual);
  } catch (e) {
    console.error("Signature verification error:", e);
    return false;
  }
}

/**
 * POST /webhooks/sumup/:token
 * Receives payment status updates from SumUp Cloud API
 *
 * Your endpoint: https://api.jbuhs.no/api/sumup/webhook/wtlK7QZFzwebLMNEI-CLw7XJhtNQyn8VaSEwKzdhpOE
 *
 * Event types:
 * - solo.transaction.updated: Terminal payment completed/failed
 * - solo.transaction.created: Terminal payment initiated
 */
r.post("/sumup/:token?", expressRawJson, async (req, res) => {
  const startTime = Date.now();
  const rawBody = (req as any).rawBody as string;
  const sig = req.header("x-sumup-signature") || "";
  const secret = process.env.SUMUP_WEBHOOK_SECRET || "";
  
  // Optional token validation (if you want to add extra security)
  const { token } = req.params;
  const expectedToken = "wtlK7QZFzwebLMNEI-CLw7XJhtNQyn8VaSEwKzdhpOE";
  
  if (token && token !== expectedToken) {
    console.warn(`⚠️  Webhook called with invalid token: ${token}`);
    return res.status(401).json({ error: "Invalid token" });
  }

  // Verify signature if secret is configured
  if (secret) {
    if (!verifySignature(rawBody, sig, secret)) {
      console.warn("⚠️  SumUp webhook signature verification failed");
      console.warn(`   Signature: ${sig}`);
      console.warn(`   Body length: ${rawBody.length}`);
      return res.status(401).json({ error: "Invalid signature" });
    }
  } else {
    console.warn("⚠️  SUMUP_WEBHOOK_SECRET not set - skipping signature verification");
  }

  // Parse webhook payload
  let evt: any;
  try {
    evt = JSON.parse(rawBody || "{}");
  } catch (err) {
    console.error("❌ Failed to parse SumUp webhook payload", err);
    return res.status(400).json({ error: "Invalid JSON" });
  }

  console.log(`\n📨 Webhook received at ${new Date().toISOString()}`);
  console.log(`   Event ID: ${evt.id || "N/A"}`);
  console.log(`   Event Type: ${evt.event_type || evt.eventType || "unknown"}`);

  // Log webhook for debugging
  await logWebhookEvent(evt);

  // Extract transaction data (handle both payload and data structures)
  const data = (evt.payload || evt.data || {}) as SumUpTransaction;
  const eventType = evt.event_type || evt.eventType || "unknown";
  
  // Get the foreign_transaction_id (your orderRef)
  const foreignId =
    data.foreign_transaction_id ||
    (data as any).foreignId ||
    (data.metadata?.foreign_transaction_id as string) ||
    "";
  
  console.log(`   Order Ref: ${foreignId || "MISSING"}`);
  console.log(`   Transaction ID: ${data.transaction_id || "N/A"}`);
  console.log(`   Status: ${data.status || "N/A"}`);
  
  if (!foreignId) {
    console.warn("⚠️  SumUp webhook missing foreign_transaction_id");
    console.warn("   This payment cannot be matched to an order");
    return res.status(202).json({
      ok: false,
      reason: "missing-order-ref",
      hint: "Ensure foreign_transaction_id is set in checkout request"
    });
  }

  // Map SumUp status to internal status
  const mapped = mapSumUpStatus(data.status);
  console.log(`   Mapped Status: ${mapped}`);

  try {
    // Upsert payment attempt
    let attempt = await prisma.paymentAttempt.upsert({
      where: { orderRef: foreignId },
      update: {
        status: mapped,
        transactionId: data.transaction_id || undefined,
        clientTransactionId: data.client_transaction_id || undefined,
        amountMinor: data.amount?.value ?? undefined,
        currency: data.amount?.currency ?? undefined,
        readerId: data.reader_id || undefined,
        scheme: data.scheme || undefined,
        last4: data.last4 || undefined,
        approvalCode: (data as any).approval_code || undefined,
        message: (data as any).message || (data as any).failure_message || null,
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
        message: (data as any).message || (data as any).failure_message || null,
      }
    });

    console.log(`✅ Payment attempt updated in database`);
    console.log(`   DB ID: ${attempt.id}`);
    console.log(`   Status: ${attempt.status}`);

    // Create Shopify order on successful payment
    if (attempt.status === "APPROVED" && !attempt.shopifyOrderId) {
      console.log(`\n📦 Creating Shopify order...`);
      
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
          console.log(`✅ Shopify order created: ${order.id}`);
        }
      } catch (e) {
        console.error("❌ Shopify order creation failed:", (e as Error).message);
        // Continue - terminal notification should still be sent
      }
    } else if (attempt.shopifyOrderId) {
      console.log(`   Shopify order already exists: ${attempt.shopifyOrderId}`);
    }

    // Send terminal confirmation webhook (optional)
    try {
      const result = await maybeSendTerminalConfirmation(attempt, {
        source: "sumup-webhook",
        sumupTx: data
      });
      
      if (result.sent) {
        attempt = result.attempt;
        console.log(`✅ Terminal confirmation sent`);
      } else {
        console.log(`   Terminal confirmation skipped: ${result.reason}`);
      }
    } catch (e) {
      console.error("❌ Terminal confirmation webhook failed:", (e as Error).message);
      // Don't fail webhook response
    }

    const duration = Date.now() - startTime;
    console.log(`\n⏱️  Webhook processed in ${duration}ms\n`);

    return res.json({
      ok: true,
      orderRef: foreignId,
      status: attempt.status,
      shopifyOrderId: attempt.shopifyOrderId || null,
      processedInMs: duration
    });
    
  } catch (e) {
    console.error("❌ Error processing webhook:", e);
    const duration = Date.now() - startTime;
    
    return res.status(500).json({
      ok: false,
      error: (e as Error).message,
      processedInMs: duration
    });
  }
});

/**
 * GET /webhooks/sumup/test
 * Test endpoint to verify webhook is reachable
 */
r.get("/sumup/test", (req, res) => {
  res.json({
    ok: true,
    message: "SumUp webhook endpoint is reachable",
    timestamp: new Date().toISOString(),
    headers: req.headers
  });
});

/**
 * Log webhook events for debugging and audit
 */
async function logWebhookEvent(evt: any) {
  try {
    const data = evt.payload || evt.data || {};
    const foreignId =
      data.foreign_transaction_id ||
      data.foreignId ||
      data.metadata?.foreign_transaction_id ||
      "unknown";
    
    await prisma.paymentEvent.create({
      data: {
        orderRef: foreignId,
        source: "webhook",
        eventType: evt.event_type || evt.eventType || "unknown",
        payload: evt,
      }
    });
  } catch (e) {
    console.error("Failed to log webhook event:", e);
  }
}

/**
 * Middleware to capture raw body for signature verification
 */
function expressRawJson(req: any, res: any, next: any) {
  let data = "";
  req.setEncoding("utf8");
  req.on("data", (chunk: string) => (data += chunk));
  req.on("end", () => {
    (req as any).rawBody = data;
    try {
      req.body = JSON.parse(data || "{}");
    } catch {
      req.body = {};
    }
    next();
  });
}

export default r;
