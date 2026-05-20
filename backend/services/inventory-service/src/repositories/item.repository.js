const { prisma } = require("../lib/prisma");

async function listItems() {
  return prisma.item.findMany({ where: { isActive: true }, orderBy: { id: "asc" } });
}

async function findById(id) {
  return prisma.item.findUnique({ where: { id }, include: { category: true, supplier: true } });
}

async function findByBarcode(barcode) {
  return prisma.item.findFirst({ where: { barcode, isActive: true } });
}

async function createItem(payload) {
  return prisma.item.create({ data: payload });
}

async function updateItem(id, payload) {
  return prisma.item.update({ where: { id }, data: payload });
}

async function deleteItem(id) {
  // Soft delete: set isActive to false instead of hard delete
  return prisma.item.update({
    where: { id },
    data: { isActive: false },
  });
}

module.exports = {
  listItems,
  findById,
  findByBarcode,
  createItem,
  updateItem,
  deleteItem,
};
