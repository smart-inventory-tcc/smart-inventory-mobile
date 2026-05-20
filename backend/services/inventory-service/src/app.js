const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../../../.env") });
const express = require("express");
const cors = require("cors");

const itemRoutes = require("./routes/items.routes");
const transactionRoutes = require("./routes/transactions.routes");
const { errorHandler } = require("./middleware/error-handler");

const app = express();
const port = Number(process.env.PORT || 3002);

app.use(cors());
app.use(express.json());

app.get("/health", (req, res) => {
  return res.status(200).json({ success: true, service: "inventory-service" });
});

app.use("/items", itemRoutes);
app.use("/transactions", transactionRoutes);
app.use(errorHandler);

app.listen(port, () => {
  console.log(`inventory-service listening on port ${port}`);
});
