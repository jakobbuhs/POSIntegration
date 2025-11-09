// server/src/routes/sumup.ts
import { Router } from "express";
import { prisma } from "../db/client";
import { cfg } from "../config";
import {
  createReaderCheckout,
  getCheckoutStatusByClientId,
  findTransactionByForeignId,
  mapSumUpStatus
} from "../services/sumupCloud";
import { createOrderInShopify } from "../services/shopifyAdmin";
import { maybeSendTerminalConfirmation } from "../services/terminalWebhook";

const r = Router();
const MIN_POLL_AGE_MS = 6500;

// POST /payments/checkout
r.post("/checkout", async (req, res, next) => {
  try {
    const { terminalId, amountMinor, currency, orderRef, customer, cart } = req.body;

    // Persist initial attempt (store cart/customer snapshots if you want to build the Shopify order later)
    await prisma.paymentAttempt.create({
      data: {
        orderRef,
        readerId: terminalId,
        amountMinor,
        currency,
        status: "PENDING",
        cartJson: cart ?? undefined,
        customerJson: customer ?? undefined
      }
    });

    try {
      const start = await createReaderCheckout({
        readerId: terminalId,
        amountMinor,
        currency,
        foreignId: orderRef,
        appId: "no.miljit.posapp", // your bundle id
        affiliateKey: cfg.sumup.affiliateKey
      });

      if (start.client_transaction_id) {
        await prisma.paymentAttempt.update({
          where: { orderRef },
          data: { clientTransactionId: start.client_transaction_id }
        });
      }

      return res.json({
        status: "PENDING",
        client_transaction_id: start.client_transaction_id || null
      });
    } catch (err) {
      const message = buildCheckoutError(err);
      try {
        await prisma.paymentAttempt.update({
          where: { orderRef },
          data: { status: "ERROR", message }
        });
      } catch (updateErr) {
        console.warn("Failed to persist checkout error", updateErr);
      }

      return res.status(502).json({ status: "ERROR", message });
    }
  } catch (e) { next(e); }
});

// GET /payments/status?orderRef=...
r.get("/status", async (req, res, next) => {
  try {
    const { orderRef } = req.query as { orderRef: string };
    let attempt = await prisma.paymentAttempt.findUnique({ where: { orderRef } });
    if (!attempt) return res.status(404).json({ status: "UNKNOWN" });

    const createdAt = attempt.createdAt instanceof Date
      ? attempt.createdAt
      : new Date(attempt.createdAt as unknown as string);
    const ageMs = Date.now() - createdAt.getTime();
    const shouldPoll = attempt.status === "PENDING" && ageMs >= MIN_POLL_AGE_MS;
    let pollAfterMs =
      attempt.status === "PENDING" && !shouldPoll ? Math.max(0, MIN_POLL_AGE_MS - ageMs) : 0;

    if (shouldPoll) {
      try {
        let tx: SumUpTransaction | null = null;

        if (attempt.clientTransactionId) {
          // your earlier code path using client_transaction_id (keep it)
          const j = await getCheckoutStatusByClientId(attempt.clientTransactionId);
          tx = j.items?.[0] ?? null;
        }

        // Fallback when client_transaction_id is null or didn’t return anything yet
        if (!tx) {
          tx = await findTransactionByForeignId(orderRef);
        }

        if (tx) {
          const mapped = mapSumUpStatus(tx.status);
          if (mapped !== "PENDING") {
            attempt = await prisma.paymentAttempt.update({
              where: { orderRef },
              data: {
                status: mapped as any,
                transactionId: tx.transaction_id ?? attempt.transactionId ?? null,
                clientTransactionId:
                  attempt.clientTransactionId ?? tx.client_transaction_id ?? (tx as any).clientTransactionId ?? null,
                scheme: tx.scheme ?? attempt.scheme ?? null,
                last4: tx.last4 ?? attempt.last4 ?? null,
                approvalCode: tx.approval_code ?? attempt.approvalCode ?? null,
                message: (tx.message as string | undefined) ?? attempt.message ?? null
              }
            });

            // If approved and no Shopify order yet, create it now
            if (mapped === "APPROVED" && !attempt.shopifyOrderId) {
              try {
                const order = await createOrderInShopify({
                  cart: (attempt.cartJson as any) || [],
                  customer: (attempt.customerJson as any) || {},
                  amountMinor: attempt.amountMinor,
                  currency: attempt.currency,
                  transactionId: attempt.transactionId!,
                  approvalCode: attempt.approvalCode || undefined,
                  scheme: attempt.scheme || undefined,
                  last4: attempt.last4 || undefined
                });
                if (order?.id) {
                  attempt = await prisma.paymentAttempt.update({
                    where: { orderRef },
                    data: { shopifyOrderId: order.id }
                  });
                }
              } catch (e) {
                console.error("Shopify orderCreate (poll path) failed", e);
              }
            }

            try {
              const result = await maybeSendTerminalConfirmation(attempt, {
                source: "status-poll",
                sumupTx: tx as any
              });
              if (result.sent) {
                attempt = result.attempt;
              }
            } catch (e) {
              console.error("Terminal confirmation webhook (poll path) failed", e);
            }
          }
        }
      } catch (e) {
        console.warn("SumUp status fetch error:", (e as Error).message);
      }

      pollAfterMs = attempt.status === "PENDING" ? 2000 : 0;
    }

    return res.json({
      status: attempt.status,
      transactionId: attempt.transactionId,
      approvalCode: attempt.approvalCode,
      scheme: attempt.scheme,
      last4: attempt.last4,
      shopifyOrderId: attempt.shopifyOrderId,
      message: attempt.message,
      clientTransactionId: attempt.clientTransactionId,
      pollAfterMs
    });
  } catch (e) { next(e); }
});

function buildCheckoutError(err: unknown): string {
  if (err instanceof HttpTimeoutError) {
    return `Timed out contacting SumUp after ${err.timeoutMs}ms`;
  }
  const message = (err as Error)?.message?.trim();
  if (!message) {
    return "Failed to start checkout with terminal";
  }
  return message.length > 300 ? message.slice(0, 300) : message;
}

export default r;
