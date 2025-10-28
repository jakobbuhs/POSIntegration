//
//  api.ts
//  POS-app-shopify
//
//  Created by Jakob Buhs on 27/10/2025.
//

export async function api(path: string, init: RequestInit = {}) {
  const base = process.env.NEXT_PUBLIC_BRIDGE_BASE!;
  const res = await fetch(`${base}${path}`, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      "X-Admin-Token": process.env.ADMIN_API_TOKEN!,
      ...(init.headers || {})
    }
  });
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}
