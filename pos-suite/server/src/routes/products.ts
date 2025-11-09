
//
//  products.ts
//  POS-app-shopify
//
//  Product catalog endpoints
//

import { Router } from "express";
import {
  getSimplifiedProducts,
  fetchShopifyProducts,
  type ShopifyProduct,
  type SimplifiedProduct
} from "../services/shopifyProducts";

const r = Router();

/**
 * GET /products
 * Returns simplified product list for POS
 * Query params:
 *   - currency: NOK (default), EUR, etc.
 *   - refresh: true to bypass cache
 */
r.get("/", async (req, res, next) => {
  try {
    const { currency = "NOK", refresh } = req.query;
    
    console.log(`📦 Fetching products (currency: ${currency}, refresh: ${refresh || false})`);
    
    // TODO: Add caching layer (Redis, in-memory, etc.)
    // For now, fetch fresh every time
    const products = await getSimplifiedProducts(currency as string);
    
    console.log(`✅ Returning ${products.length} products`);
    
    res.json({
      products,
      count: products.length,
      currency,
      cachedAt: new Date().toISOString(),
    });
  } catch (e) {
    console.error("❌ Error fetching products:", (e as Error).message);
    next(e);
  }
});

/**
 * POST /products/sync
 * Force a full product sync from Shopify
 * Admin only endpoint
 */
r.post("/sync", async (req, res, next) => {
  try {
    console.log("🔄 Starting product sync from Shopify...");
    
    // TODO: Add admin authentication
    
    const shopifyProducts = await fetchShopifyProducts();
    
    const variantCount = shopifyProducts.reduce<number>(
      (sum, product: ShopifyProduct) => sum + (product.variants?.length ?? 0),
      0
    );
    
    console.log(`✅ Synced ${shopifyProducts.length} products (${variantCount} variants)`);
    
    // TODO: Persist to database if needed
    // For now, just return sync summary
    
    res.json({
      success: true,
      synced: shopifyProducts.length,
      variants: variantCount,
      syncedAt: new Date().toISOString(),
    });
  } catch (e) {
    console.error("❌ Error syncing products:", (e as Error).message);
    next(e);
  }
});

/**
 * GET /products/:id
 * Get single product details
 */
r.get("/:id", async (req, res, next) => {
  try {
    const { id } = req.params;
    const { currency = "NOK" } = req.query;
    
    console.log(`📦 Fetching product ${id}`);
    
    const products = await getSimplifiedProducts(currency as string);
    const product = products.find((p: SimplifiedProduct) => p.id === id);
    
    if (!product) {
      console.warn(`⚠️  Product ${id} not found`);
      return res.status(404).json({ error: "Product not found" });
    }
    
    res.json(product);
  } catch (e) {
    console.error("❌ Error fetching product:", (e as Error).message);
    next(e);
  }
});

export default r;
