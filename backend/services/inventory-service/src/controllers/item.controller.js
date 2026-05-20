const itemService = require("../services/item.service");

async function list(req, res, next) {
  try {
    const result = await itemService.getItems();
    return res.status(result.status).json(result.body);
  } catch (error) {
    return next(error);
  }
}

async function getById(req, res, next) {
  try {
    const result = await itemService.getItemById(Number(req.params.id));
    return res.status(result.status).json(result.body);
  } catch (error) {
    return next(error);
  }
}

async function getByBarcode(req, res, next) {
  try {
    const result = await itemService.getItemByBarcode(req.params.barcode);
    return res.status(result.status).json(result.body);
  } catch (error) {
    return next(error);
  }
}

async function create(req, res, next) {
  try {
    const result = await itemService.createItem(req.body);
    return res.status(result.status).json(result.body);
  } catch (error) {
    return next(error);
  }
}

async function update(req, res, next) {
  try {
    const result = await itemService.updateItem(Number(req.params.id), req.body);
    return res.status(result.status).json(result.body);
  } catch (error) {
    return next(error);
  }
}

async function remove(req, res, next) {
  try {
    const result = await itemService.removeItem(Number(req.params.id));
    return res.status(result.status).json(result.body);
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  list,
  getById,
  getByBarcode,
  create,
  update,
  remove,
};
