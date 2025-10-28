//
//  config.ts
//  POS-app-shopify
//
//  Created by Jakob Buhs on 27/10/2025.
//

import 'dotenv/config';

export const cfg = {
  port: Number(process.env.PORT || 4000),
  sumup: {
    base: process.env.SUMUP_API_BASE!,
    apiKey: process.env.SUMUP_API_KEY!,
    affiliateKey: process.env.SUMUP_AFFILIATE_KEY!,
    merchantCode: process.env.SUMUP_MERCHANT_CODE!
  },
  shopify: {
    shop: process.env.SHOPIFY_SHOP!,
    token: process.env.SHOPIFY_ADMIN_TOKEN!,
    version: process.env.SHOPIFY_API_VERSION!
  },
  jwtSecret: process.env.DEVICE_JWT_SECRET!,
  features: {
    useWebhooks: !!process.env.USE_WEBHOOKS
  }
};
