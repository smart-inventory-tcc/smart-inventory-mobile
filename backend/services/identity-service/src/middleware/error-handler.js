function errorHandler(err, req, res, next) {
  const status = err.status || err.statusCode || 500;
  const message = err.message || "Internal server error";
  const body = { success: false, message };

  if (process.env.NODE_ENV !== "production" && err.details) {
    body.details = err.details;
  }

  return res.status(status).json(body);
}

module.exports = { errorHandler };
