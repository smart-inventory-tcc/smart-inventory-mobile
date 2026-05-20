const authService = require("../services/auth.service");

async function register(req, res, next) {
  try {
    const result = await authService.registerUser(req.body);
    return res.status(result.status).json(result.body);
  } catch (error) {
    return next(error);
  }
}

async function login(req, res, next) {
  try {
    const result = await authService.loginUser(req.body);
    return res.status(result.status).json(result.body);
  } catch (error) {
    return next(error);
  }
}

async function profile(req, res, next) {
  try {
    const result = await authService.getProfile(req.user.userId);
    return res.status(result.status).json(result.body);
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  register,
  login,
  profile,
};
