const { prisma } = require("../lib/prisma");

async function listSuppliers() {
  return prisma.supplier.findMany({ orderBy: { id: "asc" } });
}

async function findSupplierById(id) {
  return prisma.supplier.findUnique({ where: { id } });
}

async function createSupplier(payload) {
  return prisma.supplier.create({ data: payload });
}

async function updateSupplier(id, payload) {
  return prisma.supplier.update({ where: { id }, data: payload });
}

async function deleteSupplier(id) {
  return prisma.supplier.delete({ where: { id } });
}

module.exports = {
  listSuppliers,
  findSupplierById,
  createSupplier,
  updateSupplier,
  deleteSupplier,
};
