const transactionService = require("../services/transaction.service");

async function stockIn(req, res, next) {
  try {
    const userId = Number(req.user.userId || 0);
    const result = await transactionService.stockIn(req.body, userId);
    return res.status(result.status).json(result.body);
  } catch (error) {
    return next(error);
  }
}

async function stockOut(req, res, next) {
  try {
    const userId = Number(req.user.userId || 0);
    const result = await transactionService.stockOut(req.body, userId);
    return res.status(result.status).json(result.body);
  } catch (error) {
    return next(error);
  }
}

async function history(req, res, next) {
  try {
    const result = await transactionService.getHistory();
    return res.status(result.status).json(result.body);
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  stockIn,
  stockOut,
  history,
};
