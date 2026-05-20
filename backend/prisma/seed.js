const { PrismaClient } = require("@prisma/client");
const bcrypt = require("bcryptjs");

const prisma = new PrismaClient();

async function main() {
  console.log("Seeding database...");

  // Clear existing data to avoid unique constraint errors
  console.log("Clearing existing data...");
  await prisma.stockTransaction.deleteMany({});
  await prisma.item.deleteMany({});
  await prisma.category.deleteMany({});
  await prisma.supplier.deleteMany({});
  await prisma.user.deleteMany({});
  console.log("✓ Old data cleared");

  // Create user
  const user = await prisma.user.create({
    data: {
      username: "admin",
      passwordHash: await bcrypt.hash("admin123", 10),
      role: "OWNER",
    },
  });
  console.log("✓ User created:", user.username);

  // Create supplier
  const supplier = await prisma.supplier.create({
    data: {
      name: "PT Mitra Utama",
      phone: "082123456789",
      email: "contact@mitramaju.com",
    },
  });
  console.log("✓ Supplier created:", supplier.name);

  // Create category
  const category = await prisma.category.create({
    data: {
      categoryName: "Elektronik",
      description: "Elektronik dan Komputer",
    },
  });
  console.log("✓ Category created:", category.categoryName);

  // Create items with different stock levels
  const item1 = await prisma.item.create({
    data: {
      barcode: "ITEM001",
      name: "Laptop Dell XPS 13",
      price: 15000000,
      stock: 25,
      minStock: 5,
      categoryId: category.id,
      supplierId: supplier.id,
      imageUrl: "https://example.com/laptop.jpg",
    },
  });
  console.log("✓ Item 1 created:", item1.barcode, "(stock: 25)");

  const item2 = await prisma.item.create({
    data: {
      barcode: "ITEM002",
      name: "Mouse Logitech MX Master",
      price: 800000,
      stock: 3,
      minStock: 10,
      categoryId: category.id,
      supplierId: supplier.id,
      imageUrl: "https://example.com/mouse.jpg",
    },
  });
  console.log("✓ Item 2 created:", item2.barcode, "(stock: 3, min: 10 - LOW STOCK)");

  const item3 = await prisma.item.create({
    data: {
      barcode: "ITEM003",
      name: "Keyboard Mechanical RGB",
      price: 1200000,
      stock: 0,
      minStock: 5,
      categoryId: category.id,
      supplierId: supplier.id,
      imageUrl: "https://example.com/keyboard.jpg",
    },
  });
  console.log("✓ Item 3 created:", item3.barcode, "(stock: 0, min: 5 - OUT OF STOCK)");

  // Create sample transaction (stock in)
  const transaction1 = await prisma.stockTransaction.create({
    data: {
      itemId: item1.id,
      userId: user.id,
      type: "IN",
      quantity: 25,
    },
  });
  console.log("✓ Transaction 1 created (IN):", item1.barcode, "+25 units");

  const transaction2 = await prisma.stockTransaction.create({
    data: {
      itemId: item2.id,
      userId: user.id,
      type: "IN",
      quantity: 5,
    },
  });
  console.log("✓ Transaction 2 created (IN):", item2.barcode, "+5 units");

  const transaction3 = await prisma.stockTransaction.create({
    data: {
      itemId: item2.id,
      userId: user.id,
      type: "OUT",
      quantity: 2,
    },
  });
  console.log("✓ Transaction 3 created (OUT):", item2.barcode, "-2 units (now at low stock)");

  console.log("\n✅ Database seeded successfully!");
  console.log("\nSample credentials for testing:");
  console.log("  Username: admin");
  console.log("  Password: admin123");
  console.log("\nLow-stock item (ITEM002) is already below min_stock threshold");
}

main()
  .catch((e) => {
    console.error("❌ Seeding failed:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
