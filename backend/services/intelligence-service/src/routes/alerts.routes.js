const express = require("express");
const { requireAuth } = require("../middleware/auth");
const alertsController = require("../controllers/alerts.controller");

const router = express.Router();

router.get("/low-stock", requireAuth, alertsController.lowStock);

module.exports = router;
