const itemRepository = require("../repositories/item.repository");
const categoryRepository = require("../repositories/category.repository");
const { prisma } = require("../lib/prisma");
const { uploadItemImage } = require("../integrations/gcs");

async function getItems() {
  const items = await itemRepository.listItems();
  return { status: 200, body: { success: true, data: items } };
}

async function getItemById(id) {
  const item = await itemRepository.findById(id);
  if (!item) {
    return { status: 404, body: { success: false, message: "Item not found" } };
  }
  return { status: 200, body: { success: true, data: item } };
}

async function getItemByBarcode(barcode) {
  const item = await itemRepository.findByBarcode(barcode);
  if (!item) {
    return { status: 404, body: { success: false, message: "Item not found" } };
  }
  return { status: 200, body: { success: true, data: item } };
}

async function createItem(payload) {
  const { barcode, name, price, stock, minStock, categoryId, supplierId, imageFile, imageUrl } = payload;
  if (!barcode || !name || price === undefined || stock === undefined || minStock === undefined) {
    return { status: 400, body: { success: false, message: "Missing required fields" } };
  }

  if (categoryId !== undefined && categoryId !== null) {
    const category = await categoryRepository.findCategoryById(Number(categoryId));
    if (!category) {
      return { status: 404, body: { success: false, message: "Category not found" } };
    }
  }

  if (supplierId !== undefined && supplierId !== null) {
    const supplier = await prisma.supplier.findUnique({ where: { id: Number(supplierId) } });
    if (!supplier) {
      return { status: 404, body: { success: false, message: "Supplier not found" } };
    }
  }

  const uploadedUrl = imageUrl || (await uploadItemImage(imageFile));

  try {
    const item = await itemRepository.createItem({
      barcode,
      name,
      price: Number(price),
      stock: Number(stock),
      minStock: Number(minStock),
      categoryId: categoryId ? Number(categoryId) : null,
      supplierId: supplierId ? Number(supplierId) : null,
      imageUrl: uploadedUrl || null,
    });

    return { status: 201, body: { success: true, message: "Item created", data: item } };
  } catch (error) {
    // Handle Prisma P2002 error: Unique constraint failed on barcode field
    if (error.code === "P2002") {
      return { status: 409, body: { success: false, message: "Barcode already registered in the system" } };
    }
    // Re-throw other errors to be caught by middleware
    throw error;
  }
}

async function updateItem(id, payload) {
  const item = await itemRepository.findById(id);
  if (!item) {
    return { status: 404, body: { success: false, message: "Item not found" } };
  }

  if (payload.categoryId !== undefined && payload.categoryId !== null) {
    const category = await categoryRepository.findCategoryById(Number(payload.categoryId));
    if (!category) {
      return { status: 404, body: { success: false, message: "Category not found" } };
    }
  }

  if (payload.supplierId !== undefined && payload.supplierId !== null) {
    const supplier = await prisma.supplier.findUnique({ where: { id: Number(payload.supplierId) } });
    if (!supplier) {
      return { status: 404, body: { success: false, message: "Supplier not found" } };
    }
  }

  const updated = await itemRepository.updateItem(id, {
    name: payload.name,
    price: payload.price !== undefined ? Number(payload.price) : undefined,
    minStock: payload.minStock !== undefined ? Number(payload.minStock) : undefined,
    categoryId: payload.categoryId !== undefined ? Number(payload.categoryId) : undefined,
    supplierId: payload.supplierId !== undefined ? Number(payload.supplierId) : undefined,
    imageUrl: payload.imageUrl,
  });

  return { status: 200, body: { success: true, message: "Item updated", data: updated } };
}

async function removeItem(id) {
  const item = await itemRepository.findById(id);
  if (!item) {
    return { status: 404, body: { success: false, message: "Item not found" } };
  }

  if (!item.isActive) {
    return { status: 400, body: { success: false, message: "Item is already archived" } };
  }

  await itemRepository.deleteItem(id);
  return { status: 200, body: { success: true, message: "Item archived successfully" } };
}

module.exports = {
  getItems,
  getItemById,
  getItemByBarcode,
  createItem,
  updateItem,
  removeItem,
};
