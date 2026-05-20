const supplierRepository = require("../repositories/supplier.repository");

async function getSuppliers() {
  const suppliers = await supplierRepository.listSuppliers();
  return { status: 200, body: { success: true, data: suppliers } };
}

async function createSupplier(payload) {
  if (!payload.name) {
    return { status: 400, body: { success: false, message: "name is required" } };
  }

  const supplier = await supplierRepository.createSupplier({
    name: payload.name,
    phone: payload.phone || null,
    address: payload.address || null,
    email: payload.email || null,
  });

  return { status: 201, body: { success: true, message: "Supplier created", data: supplier } };
}

async function updateSupplier(id, payload) {
  const supplier = await supplierRepository.findSupplierById(id);
  if (!supplier) {
    return { status: 404, body: { success: false, message: "Supplier not found" } };
  }

  const updated = await supplierRepository.updateSupplier(id, {
    name: payload.name,
    phone: payload.phone,
    address: payload.address,
    email: payload.email,
  });

  return { status: 200, body: { success: true, message: "Supplier updated", data: updated } };
}

async function removeSupplier(id) {
  const supplier = await supplierRepository.findSupplierById(id);
  if (!supplier) {
    return { status: 404, body: { success: false, message: "Supplier not found" } };
  }

  await supplierRepository.deleteSupplier(id);
  return { status: 200, body: { success: true, message: "Supplier deleted" } };
}

module.exports = {
  getSuppliers,
  createSupplier,
  updateSupplier,
  removeSupplier,
};
