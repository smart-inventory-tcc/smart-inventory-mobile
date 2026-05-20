const express = require("express");
const { requireAuth } = require("../middleware/auth");
const analyticsController = require("../controllers/analytics.controller");

const router = express.Router();

router.get("/summary", requireAuth, analyticsController.summary);

module.exports = router;
