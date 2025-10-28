//
//  health.ts
//  POS-app-shopify
//
//  Created by Jakob Buhs on 27/10/2025.
//

import { Router } from "express";
const r = Router();
r.get("/", (_req, res) => res.json({ ok: true }));
export default r;
