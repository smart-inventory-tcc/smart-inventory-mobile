function errorHandler(err, req, res, next) {
  if (err && err.code === "P2002") {
    const target = Array.isArray(err.meta?.target) ? err.meta.target.join(", ") : err.meta?.target;
    const message = target && String(target).includes("barcode") ? "Barcode already registered in the system" : "Unique value already exists";

    return res.status(409).json({ success: false, message });
  }

  const status = err.status || err.statusCode || 500;
  const message = err.message || "Internal server error";
  const body = { success: false, message };

  if (process.env.NODE_ENV !== "production" && err.details) {
    body.details = err.details;
  }

  return res.status(status).json(body);
}

module.exports = { errorHandler };
