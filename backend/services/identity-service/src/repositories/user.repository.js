const { prisma } = require("../lib/prisma");

async function findByUsername(username) {
  return prisma.user.findUnique({ where: { username } });
}

async function findById(id) {
  return prisma.user.findUnique({ where: { id } });
}

async function createUser(payload) {
  return prisma.user.create({ data: payload });
}

module.exports = {
  findByUsername,
  findById,
  createUser,
};
