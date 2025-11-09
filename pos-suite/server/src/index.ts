import express from "express";
import cors from "cors";
import { cfg } from "./config";
import health from "./routes/health";
import sumup from "./routes/sumup";
import products from "./routes/products";
import webhooks from "./routes/webhooks";
import { ensureWebhookRegistered } from "./services/sumupWebhooks";

const app = express();
app.use(cors());
app.use(express.json());

app.use("/health", health);
app.use("/payments", sumup);
app.use("/products", products);
app.use("/webhooks", webhooks);

const PORT = process.env.PORT || 4000;

app.listen(Number(PORT), "0.0.0.0", async () => {
  console.log(`🚀 Bridge server running on http://0.0.0.0:${cfg.port}`);
  console.log(`📍 Health check: http://localhost:${cfg.port}/health`);
  
  // Automatically register SumUp webhook on startup (Option A)
  if (cfg.sumup.returnUrl) {
    try {
      console.log(`\n📡 Registering SumUp webhook...`);
      console.log(`   Target URL: ${cfg.sumup.returnUrl}`);
      
      const webhook = await ensureWebhookRegistered(
        cfg.sumup.returnUrl,
        ["solo.transaction.updated", "solo.transaction.created"]
      );
      
      console.log(`✅ SumUp webhook registered successfully!`);
      console.log(`   Webhook ID: ${webhook.id}`);
      console.log(`   URL: ${webhook.url}`);
      console.log(`   Events: ${webhook.events.join(", ")}`);
      console.log(`   Active: ${webhook.active}`);
      console.log(`\n💡 Your terminal payments will now trigger real-time webhooks\n`);
    } catch (e) {
      console.error(`\n❌ Failed to register SumUp webhook:`);
      console.error(`   Error: ${(e as Error).message}`);
      console.error(`\n⚠️  Payment notifications will fall back to polling`);
      console.error(`   This may cause delays in order processing\n`);
    }
  } else {
    console.warn(`\n⚠️  SUMUP_RETURN_URL not configured`);
    console.warn(`   Webhook registration skipped - using polling only\n`);
  }
});
