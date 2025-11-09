//
//  sumupWebhooks.ts
//  POS-app-shopify
//
//  Manages SumUp webhook registration and verification
//

import fetch from "node-fetch";
import { cfg } from "../config";

export type WebhookEvent =
  | "solo.transaction.updated"
  | "solo.transaction.created"
  | "checkout.completed"
  | "checkout.failed";

export interface WebhookSubscription {
  id: string;
  url: string;
  events: WebhookEvent[];
  active: boolean;
}

interface WebhooksListResponse {
  items?: WebhookSubscription[];
}

/**
 * Register a webhook with SumUp Cloud API
 * Call this on server startup or via admin endpoint
 */
export async function registerWebhook(
  webhookUrl: string,
  events: WebhookEvent[] = ["solo.transaction.updated"]
): Promise<WebhookSubscription> {
  const url = `${cfg.sumup.base}/v0.1/merchants/${cfg.sumup.merchantCode}/webhooks`;
  
  console.log(`📡 Registering SumUp webhook...`);
  console.log(`   URL: ${url}`);
  console.log(`   Target: ${webhookUrl}`);
  console.log(`   Events: ${events.join(", ")}`);
  
  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${cfg.sumup.apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      url: webhookUrl,
      events,
      active: true
    })
  });

  if (!res.ok) {
    const body = await res.text();
    console.error(`❌ Failed to register webhook: ${res.status}`);
    console.error(`   Response: ${body}`);
    throw new Error(`Failed to register webhook: ${res.status} ${body}`);
  }

  const webhook = await res.json() as WebhookSubscription;
  console.log(`✅ Webhook registered successfully: ${webhook.id}`);
  
  return webhook;
}

/**
 * List all registered webhooks
 */
export async function listWebhooks(): Promise<WebhookSubscription[]> {
  const url = `${cfg.sumup.base}/v0.1/merchants/${cfg.sumup.merchantCode}/webhooks`;
  
  console.log(`📋 Listing SumUp webhooks...`);
  
  const res = await fetch(url, {
    headers: {
      "Authorization": `Bearer ${cfg.sumup.apiKey}`,
    }
  });

  if (!res.ok) {
    const body = await res.text();
    console.error(`❌ Failed to list webhooks: ${res.status}`);
    console.error(`   Response: ${body}`);
    throw new Error(`Failed to list webhooks: ${res.status} ${body}`);
  }

  const data = await res.json() as WebhooksListResponse;
  const webhooks = data.items || [];
  
  console.log(`✅ Found ${webhooks.length} registered webhooks`);
  
  return webhooks;
}

/**
 * Delete a webhook subscription
 */
export async function deleteWebhook(webhookId: string): Promise<void> {
  const url = `${cfg.sumup.base}/v0.1/merchants/${cfg.sumup.merchantCode}/webhooks/${webhookId}`;
  
  console.log(`🗑️  Deleting webhook: ${webhookId}`);
  
  const res = await fetch(url, {
    method: "DELETE",
    headers: {
      "Authorization": `Bearer ${cfg.sumup.apiKey}`,
    }
  });

  if (!res.ok) {
    const body = await res.text();
    console.error(`❌ Failed to delete webhook: ${res.status}`);
    console.error(`   Response: ${body}`);
    throw new Error(`Failed to delete webhook: ${res.status} ${body}`);
  }
  
  console.log(`✅ Webhook deleted: ${webhookId}`);
}

/**
 * Ensure webhook is registered (idempotent)
 * Deletes existing webhooks for the same URL and re-registers
 */
export async function ensureWebhookRegistered(
  webhookUrl: string,
  events: WebhookEvent[] = ["solo.transaction.updated"]
): Promise<WebhookSubscription> {
  try {
    console.log(`\n🔍 Checking existing webhooks...`);
    
    const existing = await listWebhooks();
    
    // Remove any existing webhooks with same URL
    for (const webhook of existing) {
      if (webhook.url === webhookUrl) {
        console.log(`🔄 Found existing webhook with same URL: ${webhook.id}`);
        console.log(`   Removing to avoid duplicates...`);
        
        try {
          await deleteWebhook(webhook.id);
        } catch (e) {
          console.warn(`⚠️  Failed to delete existing webhook: ${(e as Error).message}`);
          // Continue anyway - might not be critical
        }
      }
    }
    
    // Register new webhook
    console.log(`\n📝 Registering new webhook...`);
    const webhook = await registerWebhook(webhookUrl, events);
    
    return webhook;
    
  } catch (error) {
    console.error(`\n❌ Error in webhook registration:`);
    console.error(`   ${(error as Error).message}`);
    throw error;
  }
}

/**
 * Get webhook by ID
 */
export async function getWebhook(webhookId: string): Promise<WebhookSubscription> {
  const url = `${cfg.sumup.base}/v0.1/merchants/${cfg.sumup.merchantCode}/webhooks/${webhookId}`;
  
  console.log(`🔍 Getting webhook: ${webhookId}`);
  
  const res = await fetch(url, {
    headers: {
      "Authorization": `Bearer ${cfg.sumup.apiKey}`,
    }
  });

  if (!res.ok) {
    const body = await res.text();
    console.error(`❌ Failed to get webhook: ${res.status}`);
    console.error(`   Response: ${body}`);
    throw new Error(`Failed to get webhook: ${res.status} ${body}`);
  }

  const webhook = await res.json() as WebhookSubscription;
  console.log(`✅ Retrieved webhook: ${webhook.id}`);
  
  return webhook;
}

/**
 * Update webhook (change URL or events)
 */
export async function updateWebhook(
  webhookId: string,
  updates: {
    url?: string;
    events?: WebhookEvent[];
    active?: boolean;
  }
): Promise<WebhookSubscription> {
  const url = `${cfg.sumup.base}/v0.1/merchants/${cfg.sumup.merchantCode}/webhooks/${webhookId}`;
  
  console.log(`✏️  Updating webhook: ${webhookId}`);
  console.log(`   Updates:`, JSON.stringify(updates, null, 2));
  
  const res = await fetch(url, {
    method: "PATCH",
    headers: {
      "Authorization": `Bearer ${cfg.sumup.apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(updates)
  });

  if (!res.ok) {
    const body = await res.text();
    console.error(`❌ Failed to update webhook: ${res.status}`);
    console.error(`   Response: ${body}`);
    throw new Error(`Failed to update webhook: ${res.status} ${body}`);
  }

  const webhook = await res.json() as WebhookSubscription;
  console.log(`✅ Webhook updated: ${webhook.id}`);
  
  return webhook;
}
