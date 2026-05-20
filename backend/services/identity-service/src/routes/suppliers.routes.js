const express = require("express");
const { requireAuth } = require("../middleware/auth");
const supplierController = require("../controllers/supplier.controller");

const router = express.Router();

router.get("/", requireAuth, supplierController.list);
router.post("/", requireAuth, supplierController.create);
router.put("/:id", requireAuth, supplierController.update);
router.delete("/:id", requireAuth, supplierController.remove);

module.exports = router;
