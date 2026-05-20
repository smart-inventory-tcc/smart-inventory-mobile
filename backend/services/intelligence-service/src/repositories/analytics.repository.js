const { prisma } = require("../lib/prisma");

async function countItems() {
  return prisma.item.count();
}

async function countSuppliers() {
  return prisma.supplier.count();
}

async function countTransactionsByTypeToday(type) {
  const start = new Date();
  start.setHours(0, 0, 0, 0);

  return prisma.stockTransaction.count({
    where: {
      type,
      createdAt: {
        gte: start,
      },
    },
  });
}

async function listLowStockItems() {
  const items = await prisma.item.findMany({
    select: {
      id: true,
      name: true,
      stock: true,
      minStock: true,
      updatedAt: true,
    },
    orderBy: {
      updatedAt: "desc",
    },
  });

  return items.filter((entry) => entry.stock <= entry.minStock);
}

module.exports = {
  countItems,
  countSuppliers,
  countTransactionsByTypeToday,
  listLowStockItems,
};
