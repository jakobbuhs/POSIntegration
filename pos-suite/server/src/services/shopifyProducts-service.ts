//
//  shopifyProducts.ts
//  POS-app-shopify
//
//  Syncs products from Shopify to local cache
//

import fetch from "node-fetch";
import { cfg } from "../config";

export interface ShopifyProduct {
  id: string;
  title: string;
  handle: string;
  variants: ShopifyVariant[];
  images?: Array<{ src: string }>;
  vendor?: string;
  product_type?: string;
  tags?: string[];
  status: "active" | "archived" | "draft";
}

export interface ShopifyVariant {
  id: string;
  product_id: string;
  title: string;
  price: string;
  sku?: string;
  barcode?: string;
  inventory_quantity?: number;
  inventory_item_id?: string;
}

export interface SimplifiedProduct {
  id: string;
  title: string;
  priceMinor: number;
  currency: string;
  sku: string | null;
  variantId?: string;
  imageUrl?: string;
  vendor?: string;
  productType?: string;
}

/**
 * Fetch all active products from Shopify
 * Uses REST Admin API for simplicity
 */
export async function fetchShopifyProducts(
  options: {
    status?: "active" | "archived" | "draft";
    limit?: number;
    fields?: string;
  } = {}
): Promise<ShopifyProduct[]> {
  const { status = "active", limit = 250 } = options;
  
  const url = `https://${cfg.shopify.shop}/admin/api/${cfg.shopify.version}/products.json`;
  const params = new URLSearchParams({
    status,
    limit: String(limit),
  });

  console.log(`🛍️  Fetching products from Shopify: ${url}?${params}`);

  const res = await fetch(`${url}?${params}`, {
    headers: {
      "X-Shopify-Access-Token": cfg.shopify.token,
      "Content-Type": "application/json",
    },
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Shopify products fetch failed: ${res.status} ${body}`);
  }

  const data = (await res.json()) as { products: ShopifyProduct[] };
  
  console.log(`✅ Fetched ${data.products?.length || 0} products from Shopify`);
  
  return data.products || [];
}

/**
 * Convert Shopify products to simplified POS format
 * Each variant becomes a separate product in POS
 */
export function simplifyProducts(
  shopifyProducts: ShopifyProduct[],
  currency: string = "NOK"
): SimplifiedProduct[] {
  const simplified: SimplifiedProduct[] = [];

  console.log(`🔄 Simplifying ${shopifyProducts.length} Shopify products...`);

  for (const product of shopifyProducts) {
    if (product.status !== "active") {
      continue;
    }

    // Handle products without variants
    if (!product.variants || product.variants.length === 0) {
      console.warn(`⚠️  Product ${product.title} has no variants, skipping`);
      continue;
    }

    for (const variant of product.variants) {
      const priceFloat = parseFloat(variant.price || "0");
      const priceMinor = Math.round(priceFloat * 100);

      // If variant title is "Default Title", just use product title
      const title = variant.title === "Default Title"
        ? product.title
        : `${product.title} - ${variant.title}`;

      simplified.push({
        id: variant.id,
        title,
        priceMinor,
        currency,
        sku: variant.sku || null,
        variantId: variant.id,
        imageUrl: product.images?.[0]?.src,
        vendor: product.vendor,
        productType: product.product_type,
      });
    }
  }

  console.log(`✅ Simplified to ${simplified.length} POS products`);

  return simplified;
}

/**
 * Fetch and simplify products in one call
 */
export async function getSimplifiedProducts(
  currency: string = "NOK"
): Promise<SimplifiedProduct[]> {
  try {
    const products = await fetchShopifyProducts();
    return simplifyProducts(products, currency);
  } catch (error) {
    console.error("❌ Error getting simplified products:", error);
    throw error;
  }
}

/**
 * GraphQL alternative for more control
 * Use this if you need inventory levels, locations, etc.
 */
export async function fetchProductsGraphQL(
  query: string = DEFAULT_PRODUCT_QUERY
): Promise<any> {
  const url = `https://${cfg.shopify.shop}/admin/api/${cfg.shopify.version}/graphql.json`;

  console.log(`🔍 Running GraphQL query on Shopify`);

  const res = await fetch(url, {
    method: "POST",
    headers: {
      "X-Shopify-Access-Token": cfg.shopify.token,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ query }),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`GraphQL query failed: ${res.status} ${body}`);
  }

  return res.json();
}

const DEFAULT_PRODUCT_QUERY = `
  query GetProducts($first: Int!) {
    products(first: $first, query: "status:active") {
      edges {
        node {
          id
          title
          handle
          vendor
          productType
          status
          variants(first: 10) {
            edges {
              node {
                id
                title
                price
                sku
                barcode
                inventoryQuantity
                image {
                  url
                }
              }
            }
          }
          images(first: 1) {
            edges {
              node {
                url
              }
            }
          }
        }
      }
    }
  }
`;
