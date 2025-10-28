//
//  shopifyAdmin.ts
//  POS-app-shopify
//
//  Created by Jakob Buhs on 27/10/2025.
//

import fetch from "node-fetch";
import { cfg } from "../config";

export async function createOrderInShopify(args: {
  cart: any[], customer: any, amountMinor: number, currency: string,
  transactionId: string, approvalCode?: string, scheme?: string, last4?: string
}) {
  const url = `https://${cfg.shopify.shop}/admin/api/${cfg.shopify.version}/graphql.json`;

  const noteAttrs = [
    { name: "sumup_transaction_id", value: args.transactionId },
    { name: "sumup_scheme", value: args.scheme || "" },
    { name: "sumup_approval_code", value: args.approvalCode || "" },
    { name: "sumup_last4", value: args.last4 || "" },
  ];

  const lineItems = args.cart.map(i => ({
    title: i.title, quantity: i.qty, originalUnitPrice: String(i.unitPrice),
    // If you have variant/product IDs from Shopify, pass their IDs for perfect attribution
  }));

  const mutation = `
    mutation CreateOrder($input: OrderInput!) {
      orderCreate(input: $input) {
        order { id name }
        userErrors { field message }
      }
    }`;

  const variables = {
    input: {
      email: args.customer.email,
      phone: args.customer.phone,
      customer: { firstName: args.customer.firstName || args.customer.first_name },
      noteAttributes: noteAttrs,
      lineItems,
      transactions: [{
        kind: "SALE",
        status: "SUCCESS",
        amount: String(args.amountMinor / 100),
        gateway: "External - SumUp",
        authorizationCode: args.approvalCode || null,
        receiptJson: JSON.stringify({ transactionId: args.transactionId, scheme: args.scheme, last4: args.last4 }),
      }]
    }
  };

  const res = await fetch(url, {
    method: "POST",
    headers: {
      "X-Shopify-Access-Token": cfg.shopify.token,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({ query: mutation, variables })
  });

  const json = await res.json();
  if (json.errors || json.data?.orderCreate?.userErrors?.length) {
    throw new Error("Shopify orderCreate failed: " + JSON.stringify(json));
  }
  return json.data.orderCreate.order;
}
