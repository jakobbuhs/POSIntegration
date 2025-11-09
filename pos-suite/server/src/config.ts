//
//  config.ts
//  POS-app-shopify
//
//  Server configuration with environment variables
//

import 'dotenv/config';

export const cfg = {
  port: Number(process.env.PORT || 4000),
  
  sumup: {
    base: process.env.SUMUP_API_BASE || 'https://api.sumup.com',
    apiKey: process.env.SUMUP_API_KEY!,
    affiliateKey: process.env.SUMUP_AFFILIATE_KEY!,
    merchantCode: process.env.SUMUP_MERCHANT_CODE!,
    // Your actual webhook endpoint
    returnUrl: process.env.SUMUP_RETURN_URL ||
      'https://api.jbuhs.no/api/sumup/webhook/wtlK7QZFzwebLMNEI-CLw7XJhtNQyn8VaSEwKzdhpOE'
  },
  
  shopify: {
    shop: process.env.SHOPIFY_SHOP!,
    token: process.env.SHOPIFY_ADMIN_TOKEN!,
    version: process.env.SHOPIFY_API_VERSION || '2024-10'
  },
  
  webhooks: {
    // Your terminal confirmation webhook (optional)
    terminalConfirmationUrl: process.env.TERMINAL_CONFIRMATION_WEBHOOK_URL
  },
  
  jwtSecret: process.env.DEVICE_JWT_SECRET || 'dev-secret-change-in-prod',
  
  features: {
    useWebhooks: process.env.USE_WEBHOOKS !== 'false' // true by default
  }
};

// Validate required config
const required = [
  'SUMUP_API_KEY',
  'SUMUP_AFFILIATE_KEY',
  'SUMUP_MERCHANT_CODE',
  'SHOPIFY_SHOP',
  'SHOPIFY_ADMIN_TOKEN'
];

for (const key of required) {
  if (!process.env[key]) {
    console.error(`❌ Missing required environment variable: ${key}`);
    process.exit(1);
  }
}
