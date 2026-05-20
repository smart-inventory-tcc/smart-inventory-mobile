const express = require("express");
const { requireAuth } = require("../middleware/auth");
const transactionController = require("../controllers/transaction.controller");

const router = express.Router();

router.post("/in", requireAuth, transactionController.stockIn);
router.post("/out", requireAuth, transactionController.stockOut);
router.get("/history", requireAuth, transactionController.history);

module.exports = router;
