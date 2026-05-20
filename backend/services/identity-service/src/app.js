const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../../../.env") });
const express = require("express");
const cors = require("cors");

const authRoutes = require("./routes/auth.routes");
const supplierRoutes = require("./routes/suppliers.routes");
const { errorHandler } = require("./middleware/error-handler");

const app = express();
const port = Number(process.env.PORT || 3001);

app.use(cors());
app.use(express.json());

// Serve Swagger documentation
app.use("/docs", express.static(path.resolve(__dirname, "../../../docs")));

app.get("/health", (req, res) => {
  return res.status(200).json({ success: true, service: "identity-service" });
});

app.use("/auth", authRoutes);
app.use("/suppliers", supplierRoutes);
app.use(errorHandler);

app.listen(port, () => {
  console.log(`identity-service listening on port ${port}`);
});
