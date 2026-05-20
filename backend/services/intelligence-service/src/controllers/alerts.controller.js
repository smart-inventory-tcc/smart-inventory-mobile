const alertsService = require("../services/alerts.service");

async function lowStock(req, res, next) {
  try {
    const result = await alertsService.getLowStockAlerts(req.query);
    return res.status(result.status).json(result.body);
  } catch (error) {
    return next(error);
  }
}

module.exports = { lowStock };
