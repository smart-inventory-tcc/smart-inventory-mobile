const { prisma } = require("../lib/prisma");

async function findCategoryById(id) {
  return prisma.category.findUnique({ where: { id } });
}

module.exports = {
  findCategoryById,
};