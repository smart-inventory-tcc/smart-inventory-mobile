const analyticsRepository = require("../repositories/analytics.repository");
const { ensureSystemConfig } = require("../integrations/firestore");

async function getLowStockAlerts(query) {
  try {
    await ensureSystemConfig();
  } catch (error) {
    console.error("Failed to ensure system_config", error);
  }

  const isReadParam = query.isRead;
  const lowStockItems = await analyticsRepository.listLowStockItems();

  const alerts = lowStockItems.map((item) => ({
    id: `item-${item.id}`,
    itemId: item.id,
    itemName: item.name,
    message: `Low stock alert for ${item.name}. Current stock: ${item.stock}`,
    level: item.stock <= Math.max(0, Math.floor(item.minStock / 2)) ? "danger" : "warning",
    isRead: false,
    timestamp: item.updatedAt,
  }));

  let result = alerts;
  if (isReadParam === "true") {
    result = alerts.filter((entry) => entry.isRead);
  }
  if (isReadParam === "false") {
    result = alerts.filter((entry) => !entry.isRead);
  }

  return { status: 200, body: { success: true, data: result } };
}

module.exports = { getLowStockAlerts };
