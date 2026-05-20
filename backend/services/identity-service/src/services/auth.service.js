const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../../../.env"), override: true });
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
const userRepository = require("../repositories/user.repository");
const { logUserActivity } = require("../integrations/firestore");

const JWT_SECRET = process.env.JWT_SECRET || "dev-secret-change-me";

async function registerUser({ username, password, role }) {
  if (!username || !password || !role) {
    return { status: 400, body: { success: false, message: "Missing required fields" } };
  }

  const existingUser = await userRepository.findByUsername(username);
  if (existingUser) {
    return { status: 409, body: { success: false, message: "Username already exists" } };
  }

  const passwordHash = await bcrypt.hash(password, 10);
  const user = await userRepository.createUser({ username, passwordHash, role });

  try {
    await logUserActivity({
      userId: user.id,
      username: user.username,
      action: "REGISTER_SUCCESS",
      metadata: { role: user.role },
    });
  } catch (error) {
    console.error("Failed to write user activity log", error);
  }

  return {
    status: 201,
    body: {
      success: true,
      message: "User registered",
      data: {
        id: user.id,
        username: user.username,
        role: user.role,
      },
    },
  };
}

async function loginUser({ username, password }) {
  if (!username || !password) {
    return { status: 400, body: { success: false, message: "Missing credentials" } };
  }

  const user = await userRepository.findByUsername(username);
  if (!user) {
    return { status: 401, body: { success: false, message: "Invalid credentials" } };
  }

  const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
  if (!isPasswordValid) {
    return { status: 401, body: { success: false, message: "Invalid credentials" } };
  }

  const token = jwt.sign({ userId: user.id, role: user.role, username: user.username }, JWT_SECRET, {
    expiresIn: "1d",
  });

  try {
    await logUserActivity({
      userId: user.id,
      username: user.username,
      action: "LOGIN_SUCCESS",
      metadata: { role: user.role },
    });
  } catch (error) {
    console.error("Failed to write user activity log", error);
  }

  return {
    status: 200,
    body: {
      success: true,
      message: "Login success",
      data: {
        token,
        user: {
          id: user.id,
          username: user.username,
          role: user.role,
        },
      },
    },
  };
}

async function getProfile(userId) {
  const user = await userRepository.findById(userId);
  if (!user) {
    return { status: 404, body: { success: false, message: "User not found" } };
  }

  return {
    status: 200,
    body: {
      success: true,
      message: "Profile fetched",
      data: {
        id: user.id,
        username: user.username,
        role: user.role,
        createdAt: user.createdAt,
      },
    },
  };
}

module.exports = {
  JWT_SECRET,
  registerUser,
  loginUser,
  getProfile,
};
