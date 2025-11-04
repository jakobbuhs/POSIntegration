import type { NextFunction, Request, Response } from "express";

export function errorHandler(err: unknown, _req: Request, res: Response, next: NextFunction) {
  if (res.headersSent) {
    return next(err);
  }

  const status = typeof (err as any)?.status === "number" ? (err as any).status : 500;
  const message = ((err as Error)?.message || "Internal server error").trim();

  if (status >= 500) {
    console.error("Unhandled error", err);
  }

  res.status(status).json({ error: message || "Internal server error" });
}
