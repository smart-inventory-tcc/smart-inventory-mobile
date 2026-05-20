const analyticsService = require("../services/analytics.service");

async function summary(req, res, next) {
  try {
    const result = await analyticsService.getSummary();
    return res.status(result.status).json(result.body);
  } catch (error) {
    return next(error);
  }
}

module.exports = { summary };
