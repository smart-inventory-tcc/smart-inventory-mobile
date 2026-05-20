const { prisma } = require("../lib/prisma");
const itemRepository = require("../repositories/item.repository");
const transactionRepository = require("../repositories/transaction.repository");
const { createLowStockArtifacts, upsertTempScanSession } = require("../integrations/firestore");

async function stockIn(payload, userId) {
  const { itemId, quantity, scanSessionId } = payload;
  const item = await itemRepository.findById(Number(itemId));

  if (!item) {
    return { status: 404, body: { success: false, message: "Item not found" } };
  }

  const qty = Number(quantity);
  if (!qty || qty <= 0) {
    return { status: 400, body: { success: false, message: "quantity must be greater than 0" } };
  }

  const result = await prisma.$transaction(async (tx) => {
    const updatedItem = await tx.item.update({
      where: { id: item.id },
      data: { stock: item.stock + qty },
    });

    const trx = await tx.stockTransaction.create({
      data: {
        itemId: item.id,
        userId,
        type: "IN",
        quantity: qty,
      },
    });

    return { updatedItem, trx };
  });

  if (scanSessionId) {
    try {
      await upsertTempScanSession({
        scanSessionId,
        itemId: item.id,
        barcode: item.barcode,
        userId,
        quantity: qty,
        transactionId: result.trx.id,
        currentStock: result.updatedItem.stock,
      });
    } catch (sessionError) {
      console.error("Failed to persist temp scan session", sessionError);
    }
  }

  return {
    status: 201,
    body: { success: true, message: "Transaction IN recorded", data: result.trx },
  };
}

async function stockOut(payload, userId) {
  const { itemId, quantity, scanSessionId } = payload;
  const item = await itemRepository.findById(Number(itemId));

  if (!item) {
    return { status: 404, body: { success: false, message: "Item not found" } };
  }

  const qty = Number(quantity);
  if (!qty || qty <= 0) {
    return { status: 400, body: { success: false, message: "quantity must be greater than 0" } };
  }

  if (item.stock < qty) {
    return { status: 400, body: { success: false, message: "Insufficient stock" } };
  }

  const previousStock = item.stock;

  const result = await prisma.$transaction(async (tx) => {
    const updatedItem = await tx.item.update({
      where: { id: item.id },
      data: { stock: item.stock - qty },
    });

    const trx = await tx.stockTransaction.create({
      data: {
        itemId: item.id,
        userId,
        type: "OUT",
        quantity: qty,
      },
    });

    return { updatedItem, trx };
  });

  let lowStockTriggered = false;
  let lowStockAlertCreated = false;
  let lowStockAlertError = null;
  if (result.updatedItem.stock <= result.updatedItem.minStock) {
    lowStockTriggered = true;
    try {
      await createLowStockArtifacts(result.updatedItem, result.updatedItem.stock, scanSessionId || null);
      lowStockAlertCreated = true;
    } catch (alertError) {
      lowStockAlertError = alertError.message || "Failed to persist low stock alert";
      console.error("Failed to persist low stock alert", alertError);
    }
  }

  return {
    status: 201,
    body: {
      success: true,
      message: "Transaction OUT recorded",
      data: {
        transaction: result.trx,
        previousStock,
        currentStock: result.updatedItem.stock,
        lowStockTriggered,
        lowStockAlertCreated,
        lowStockAlertError,
      },
    },
  };
}

async function getHistory() {
  const transactions = await transactionRepository.listStockTransactions();
  return { status: 200, body: { success: true, data: transactions } };
}

module.exports = {
  stockIn,
  stockOut,
  getHistory,
};
