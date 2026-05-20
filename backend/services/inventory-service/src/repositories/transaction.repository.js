const { prisma } = require("../lib/prisma");

async function createStockTransaction(payload) {
  return prisma.stockTransaction.create({ data: payload });
}

async function listStockTransactions() {
  return prisma.stockTransaction.findMany({ orderBy: { createdAt: "desc" } });
}

module.exports = {
  createStockTransaction,
  listStockTransactions,
};
