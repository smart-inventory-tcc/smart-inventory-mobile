const analyticsRepository = require("../repositories/analytics.repository");
const { ensureSystemConfig } = require("../integrations/firestore");

async function getSummary() {
  try {
    await ensureSystemConfig();
  } catch (error) {
    console.error("Failed to ensure system_config", error);
  }

  const [totalItems, totalSuppliers, todayIn, todayOut, lowStockItems] = await Promise.all([
    analyticsRepository.countItems(),
    analyticsRepository.countSuppliers(),
    analyticsRepository.countTransactionsByTypeToday("IN"),
    analyticsRepository.countTransactionsByTypeToday("OUT"),
    analyticsRepository.listLowStockItems(),
  ]);

  return {
    status: 200,
    body: {
      success: true,
      data: {
        totalItems,
        totalSuppliers,
        todayIn,
        todayOut,
        lowStockCount: lowStockItems.length,
      },
    },
  };
}

module.exports = { getSummary };
