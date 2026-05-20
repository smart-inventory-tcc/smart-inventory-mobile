const supplierService = require("../services/supplier.service");

async function list(req, res, next) {
  try {
    const result = await supplierService.getSuppliers();
    return res.status(result.status).json(result.body);
  } catch (error) {
    return next(error);
  }
}

async function create(req, res, next) {
  try {
    const result = await supplierService.createSupplier(req.body);
    return res.status(result.status).json(result.body);
  } catch (error) {
    return next(error);
  }
}

async function update(req, res, next) {
  try {
    const result = await supplierService.updateSupplier(Number(req.params.id), req.body);
    return res.status(result.status).json(result.body);
  } catch (error) {
    return next(error);
  }
}

async function remove(req, res, next) {
  try {
    const result = await supplierService.removeSupplier(Number(req.params.id));
    return res.status(result.status).json(result.body);
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  list,
  create,
  update,
  remove,
};
