import express from "express";
import cors from "cors";
import { cfg } from "./config";
import health from "./routes/health";
import sumup from "./routes/sumup";
import webhooks from "./routes/webhooks";

const app = express();
app.use(cors());
app.use(express.json());

app.use("/health", health);
app.use("/payments", sumup);
if (cfg.features.useWebhooks) {
  app.use("/webhooks", webhooks);
}

const PORT = process.env.PORT || 4000;
app.listen(Number(PORT), "0.0.0.0", () => {
  console.log(`Bridge up on http://0.0.0.0:${cfg.port}`);
});
