// server/src/services/sumupCloud.ts
import type { PaymentStatus } from "@prisma/client";
import { cfg } from "../config";
import { fetchWithTimeout, HttpTimeoutError, Response } from "./http";

export type SumUpTransaction = {
  transaction_id?: string;
  id?: string;
  status?: string;
  amount?: { currency?: string; value?: number };
  foreign_transaction_id?: string;
  foreignId?: string;
  metadata?: Record<string, unknown>;
  scheme?: string;
  last4?: string;
  approval_code?: string;
  message?: string;
  reader_id?: string;
  client_transaction_id?: string;
  [key: string]: unknown;
};

type SumUpCheckoutStartResponse = {
  client_transaction_id?: string;
  [key: string]: unknown;
};

type SumUpTransactionList = {
  items?: SumUpTransaction[];
};

export async function createReaderCheckout(args: {
  readerId: string;
  amountMinor: number;
  currency: string;
  foreignId: string;    // your orderRef
  appId: string;        // your iOS bundle id, e.g. no.miljit.posapp
  affiliateKey: string; // SUMUP_AFFILIATE_KEY
  description?: string;
}): Promise<SumUpCheckoutStartResponse> {
  const url = `${cfg.sumup.base}/v0.1/merchants/${cfg.sumup.merchantCode}/readers/${args.readerId}/checkout`;
  let res: Response;
  try {
    res = await fetchWithTimeout(url, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${cfg.sumup.apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        total_amount: { currency: args.currency, minor_unit: 2, value: args.amountMinor },
        affiliate: {
          app_id: args.appId,
          key: args.affiliateKey,
          foreign_transaction_id: args.foreignId
        },
        description: args.description || "POS checkout"
      })
    }, 15000);
  } catch (err) {
    if (err instanceof HttpTimeoutError) {
      throw new Error(`SumUp checkout start timed out after ${err.timeoutMs}ms`);
    }
    throw err;
  }
  if (!res.ok) throw new Error(`SumUp checkout start failed ${res.status} ${await res.text()}`);
  return res.json() as Promise<SumUpCheckoutStartResponse>; // expect client_transaction_id
}

export async function terminateReaderCheckout(readerId: string) {
  const url = `${cfg.sumup.base}/v0.1/merchants/${cfg.sumup.merchantCode}/readers/${readerId}/terminate`;
  let res: Response;
  try {
    res = await fetchWithTimeout(
      url,
      {
        method: "POST",
        headers: { "Authorization": `Bearer ${cfg.sumup.apiKey}` }
      },
      10000
    );
  } catch (err) {
    if (err instanceof HttpTimeoutError) {
      throw new Error(`Terminate checkout timed out after ${err.timeoutMs}ms`);
    }
    throw err;
  }
  if (!res.ok) throw new Error(`Terminate failed ${res.status} ${await res.text()}`);
  return res.json();
}

// Polling fallback: get status by client_transaction_id (or filter recent)
export async function getCheckoutStatusByClientId(clientTxnId: string): Promise<SumUpTransactionList> {
  // Some tenants allow filtering by client_transaction_id; if not, you can narrow by date/limit and filter locally.
  const url =
    `${cfg.sumup.base}/v0.1/merchants/${cfg.sumup.merchantCode}/transactions?client_transaction_id=${encodeURIComponent(
      clientTxnId
    )}`;
  let res: Response;
  try {
    res = await fetchWithTimeout(
      url,
      { headers: { "Authorization": `Bearer ${cfg.sumup.apiKey}` } },
      10000
    );
  } catch (err) {
    if (err instanceof HttpTimeoutError) {
      throw new Error(`Checkout status fetch timed out after ${err.timeoutMs}ms`);
    }
    throw err;
  }
  if (!res.ok) throw new Error(`Status fetch failed ${res.status} ${await res.text()}`);
  return res.json() as Promise<SumUpTransactionList>; // { items: [...] }
}

export function mapSumUpStatus(s: string | undefined): PaymentStatus {
  const key = (s || "").toUpperCase();
  if (["SUCCESSFUL", "APPROVED", "PAID"].includes(key)) return "APPROVED";
  if (key === "DECLINED") return "DECLINED";
  if (key === "CANCELLED" || key === "CANCELED") return "CANCELLED";
  if (key === "ERROR" || key === "FAILED") return "ERROR";
  return "PENDING";
}
// Get recent transactions and filter locally by foreign_transaction_id (your orderRef)
export async function findTransactionByForeignId(foreignId: string): Promise<SumUpTransaction | null> {
  // Pull recent txs; adjust limit or add date filters if needed
  const url = `${cfg.sumup.base}/v0.1/merchants/${cfg.sumup.merchantCode}/transactions?limit=50`;
  let res: Response;
  try {
    res = await fetchWithTimeout(
      url,
      { headers: { "Authorization": `Bearer ${cfg.sumup.apiKey}` } },
      10000
    );
  } catch (err) {
    if (err instanceof HttpTimeoutError) {
      throw new Error(`Transaction lookup timed out after ${err.timeoutMs}ms`);
    }
    throw err;
  }
  if (!res.ok) throw new Error(`Tx list failed ${res.status} ${await res.text()}`);
  const j = (await res.json()) as SumUpTransactionList; // { items: [...] }
  const items = Array.isArray(j.items) ? j.items : [];
  // Match either explicit foreign id or metadata field names used by your tenant
  return (
    items.find((tx: SumUpTransaction) =>
      tx.foreign_transaction_id === foreignId ||
      tx.foreignId === foreignId ||
      tx.metadata?.foreign_transaction_id === foreignId
    ) || null
  );
}
