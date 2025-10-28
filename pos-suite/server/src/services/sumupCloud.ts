// server/src/services/sumupCloud.ts
import fetch from "node-fetch";
import { cfg } from "../config";

export async function createReaderCheckout(args: {
  readerId: string;
  amountMinor: number;
  currency: string;
  foreignId: string;    // your orderRef
  appId: string;        // your iOS bundle id, e.g. no.miljit.posapp
  affiliateKey: string; // SUMUP_AFFILIATE_KEY
  description?: string;
}) {
  const url = `${cfg.sumup.base}/v0.1/merchants/${cfg.sumup.merchantCode}/readers/${args.readerId}/checkout`;
  const res = await fetch(url, {
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
  });
  if (!res.ok) throw new Error(`SumUp checkout start failed ${res.status} ${await res.text()}`);
  return res.json(); // expect client_transaction_id
}

export async function terminateReaderCheckout(readerId: string) {
  const url = `${cfg.sumup.base}/v0.1/merchants/${cfg.sumup.merchantCode}/readers/${readerId}/terminate`;
  const res = await fetch(url, {
    method: "POST",
    headers: { "Authorization": `Bearer ${cfg.sumup.apiKey}` }
  });
  if (!res.ok) throw new Error(`Terminate failed ${res.status} ${await res.text()}`);
  return res.json();
}

// Polling fallback: get status by client_transaction_id (or filter recent)
export async function getCheckoutStatusByClientId(clientTxnId: string) {
  // Some tenants allow filtering by client_transaction_id; if not, you can narrow by date/limit and filter locally.
  const url = `${cfg.sumup.base}/v0.1/merchants/${cfg.sumup.merchantCode}/transactions?client_transaction_id=${encodeURIComponent(clientTxnId)}`;
  const res = await fetch(url, { headers: { "Authorization": `Bearer ${cfg.sumup.apiKey}` } });
  if (!res.ok) throw new Error(`Status fetch failed ${res.status} ${await res.text()}`);
  return res.json(); // { items: [...] }
}

export function mapSumUpStatus(s: string | undefined) {
  const key = (s || "").toUpperCase();
  if (["SUCCESSFUL", "APPROVED", "PAID"].includes(key)) return "APPROVED";
  if (key === "DECLINED") return "DECLINED";
  if (key === "CANCELLED" || key === "CANCELED") return "CANCELLED";
  if (key === "ERROR" || key === "FAILED") return "ERROR";
  return "PENDING";
}
// Get recent transactions and filter locally by foreign_transaction_id (your orderRef)
export async function findTransactionByForeignId(foreignId: string) {
  // Pull recent txs; adjust limit or add date filters if needed
  const url = `${cfg.sumup.base}/v0.1/merchants/${cfg.sumup.merchantCode}/transactions?limit=50`;
  const res = await fetch(url, { headers: { "Authorization": `Bearer ${cfg.sumup.apiKey}` } });
  if (!res.ok) throw new Error(`Tx list failed ${res.status} ${await res.text()}`);
  const j = await res.json(); // { items: [...] }
  const items = Array.isArray(j.items) ? j.items : [];
  // Match either explicit foreign id or metadata field names used by your tenant
  return items.find((tx: any) =>
    tx.foreign_transaction_id === foreignId ||
    tx.foreignId === foreignId ||
    tx.metadata?.foreign_transaction_id === foreignId
  ) || null;
}
