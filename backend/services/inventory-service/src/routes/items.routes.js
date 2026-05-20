const express = require("express");
const { requireAuth } = require("../middleware/auth");
const itemController = require("../controllers/item.controller");

const router = express.Router();

router.get("/", requireAuth, itemController.list);
router.get("/barcode/:barcode", requireAuth, itemController.getByBarcode);
router.get("/:id", requireAuth, itemController.getById);
router.post("/", requireAuth, itemController.create);
router.put("/:id", requireAuth, itemController.update);
router.delete("/:id", requireAuth, itemController.remove);

module.exports = router;
