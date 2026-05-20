const express = require("express");
const { requireAuth } = require("../middleware/auth");
const authController = require("../controllers/auth.controller");

const router = express.Router();

router.post("/register", authController.register);
router.post("/login", authController.login);
router.get("/profile", requireAuth, authController.profile);

module.exports = router;
