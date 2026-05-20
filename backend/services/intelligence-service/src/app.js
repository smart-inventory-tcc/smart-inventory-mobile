const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../../../.env") });
const express = require("express");
const cors = require("cors");

const analyticsRoutes = require("./routes/analytics.routes");
const alertsRoutes = require("./routes/alerts.routes");
const { errorHandler } = require("./middleware/error-handler");

const app = express();
const port = Number(process.env.PORT || 3003);

app.use(cors());
app.use(express.json());

app.get("/health", (req, res) => {
  return res.status(200).json({ success: true, service: "intelligence-service" });
});

app.use("/analytics", analyticsRoutes);
app.use("/alerts", alertsRoutes);
app.use(errorHandler);

app.listen(port, () => {
  console.log(`intelligence-service listening on port ${port}`);
});
