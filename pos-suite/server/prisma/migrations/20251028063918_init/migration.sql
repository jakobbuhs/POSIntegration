/*
  Warnings:

  - You are about to alter the column `clientTransactionId` on the `PaymentAttempt` table. The data in that column could be lost. The data in that column will be cast from `Text` to `VarChar(128)`.
  - You are about to alter the column `transactionId` on the `PaymentAttempt` table. The data in that column could be lost. The data in that column will be cast from `Text` to `VarChar(128)`.
  - You are about to alter the column `readerId` on the `PaymentAttempt` table. The data in that column could be lost. The data in that column will be cast from `Text` to `VarChar(128)`.
  - You are about to alter the column `currency` on the `PaymentAttempt` table. The data in that column could be lost. The data in that column will be cast from `Text` to `VarChar(12)`.
  - You are about to alter the column `scheme` on the `PaymentAttempt` table. The data in that column could be lost. The data in that column will be cast from `Text` to `VarChar(32)`.
  - You are about to alter the column `last4` on the `PaymentAttempt` table. The data in that column could be lost. The data in that column will be cast from `Text` to `VarChar(4)`.
  - You are about to alter the column `approvalCode` on the `PaymentAttempt` table. The data in that column could be lost. The data in that column will be cast from `Text` to `VarChar(32)`.
  - You are about to alter the column `shopifyOrderId` on the `PaymentAttempt` table. The data in that column could be lost. The data in that column will be cast from `Text` to `VarChar(128)`.

*/
-- AlterTable
ALTER TABLE "PaymentAttempt" ADD COLUMN     "cartJson" JSONB,
ADD COLUMN     "customerJson" JSONB,
ALTER COLUMN "clientTransactionId" SET DATA TYPE VARCHAR(128),
ALTER COLUMN "transactionId" SET DATA TYPE VARCHAR(128),
ALTER COLUMN "readerId" SET DATA TYPE VARCHAR(128),
ALTER COLUMN "currency" SET DATA TYPE VARCHAR(12),
ALTER COLUMN "scheme" SET DATA TYPE VARCHAR(32),
ALTER COLUMN "last4" SET DATA TYPE VARCHAR(4),
ALTER COLUMN "approvalCode" SET DATA TYPE VARCHAR(32),
ALTER COLUMN "shopifyOrderId" SET DATA TYPE VARCHAR(128);

-- CreateTable
CREATE TABLE "PaymentEvent" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "orderRef" TEXT NOT NULL,
    "source" VARCHAR(32) NOT NULL,
    "eventType" VARCHAR(64) NOT NULL,
    "payload" JSONB NOT NULL,

    CONSTRAINT "PaymentEvent_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "PaymentEvent_orderRef_createdAt_idx" ON "PaymentEvent"("orderRef", "createdAt");

-- CreateIndex
CREATE INDEX "PaymentAttempt_clientTransactionId_idx" ON "PaymentAttempt"("clientTransactionId");

-- CreateIndex
CREATE INDEX "PaymentAttempt_readerId_idx" ON "PaymentAttempt"("readerId");

-- CreateIndex
CREATE INDEX "PaymentAttempt_status_createdAt_idx" ON "PaymentAttempt"("status", "createdAt");
