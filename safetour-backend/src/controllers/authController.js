const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const { validationResult } = require('express-validator');
const User = require('../models/User');

const BCRYPT_ROUNDS = 12;
const ACCESS_TOKEN_TTL = '15m';
const REFRESH_TOKEN_TTL = '30d';

function sendValidationErrors(req, res) {
  const errors = validationResult(req);

  if (errors.isEmpty()) {
    return false;
  }

  return res.status(400).json({
    error: 'ValidationError',
    message: errors.array().map((item) => item.msg).join(', '),
    statusCode: 400
  });
}

function getJwtSecret(secretName) {
  const secret = process.env[secretName];

  if (!secret) {
    const error = new Error(`${secretName} is required`);
    error.statusCode = 500;
    throw error;
  }

  return secret;
}

function signAccessToken(user) {
  return jwt.sign(
    { userId: user._id.toString(), role: user.role },
    getJwtSecret('JWT_SECRET'),
    { expiresIn: ACCESS_TOKEN_TTL }
  );
}

function signRefreshToken(user) {
  return jwt.sign(
    { userId: user._id.toString(), role: user.role },
    getJwtSecret('JWT_REFRESH_SECRET'),
    { expiresIn: REFRESH_TOKEN_TTL }
  );
}

function toAuthResponse(user) {
  return {
    token: signAccessToken(user),
    refreshToken: signRefreshToken(user),
    user: {
      id: user._id.toString(),
      email: user.email,
      displayName: user.displayName,
      role: user.role
    }
  };
}

function toAccessTokenResponse(user) {
  return {
    token: signAccessToken(user)
  };
}

async function register(req, res, next) {
  try {
    if (sendValidationErrors(req, res)) return;

    const email = req.body.email.toLowerCase();
    const { password } = req.body;
    const displayName = req.body.displayName || email.split('@')[0];
    const role = req.body.role || 'tourist';

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(409).json({ error: 'Conflict', message: 'Email already registered', statusCode: 409 });
    }

    const passwordHash = await bcrypt.hash(password, BCRYPT_ROUNDS);
    const user = await User.create({
      email,
      passwordHash,
      displayName,
      role,
      language: 'en'
    });

    res.status(201).json(toAuthResponse(user));
  } catch (error) {
    next(error);
  }
}

async function login(req, res, next) {
  try {
    if (sendValidationErrors(req, res)) return;

    const email = req.body.email.toLowerCase();
    const { password } = req.body;

    const user = await User.findOne({ email });
    const isPasswordValid = user ? await bcrypt.compare(password, user.passwordHash) : false;

    if (!user || !isPasswordValid) {
      return res.status(401).json({ error: 'Unauthorized', message: 'Invalid credentials', statusCode: 401 });
    }

    user.lastLoginAt = new Date();
    await user.save();

    res.json(toAuthResponse(user));
  } catch (error) {
    next(error);
  }
}

async function refresh(req, res, next) {
  try {
    if (sendValidationErrors(req, res)) return;

    const { refreshToken } = req.body;

    let decoded;
    try {
      decoded = jwt.verify(refreshToken, getJwtSecret('JWT_REFRESH_SECRET'));
    } catch (error) {
      return res.status(401).json({ error: 'Unauthorized', message: 'Invalid or expired refresh token', statusCode: 401 });
    }

    const user = await User.findById(decoded.userId);
    if (!user) {
      return res.status(401).json({ error: 'Unauthorized', message: 'Invalid refresh token', statusCode: 401 });
    }

    res.json(toAccessTokenResponse(user));
  } catch (error) {
    next(error);
  }
}

async function logout(req, res, next) {
  try {
    if (sendValidationErrors(req, res)) return;

    const { fcmToken } = req.body;

    if (fcmToken) {
      await User.updateOne(
        { _id: req.user.userId, fcmToken },
        { $unset: { fcmToken: '' } }
      );
    }

    res.json({ success: true });
  } catch (error) {
    next(error);
  }
}

async function updateFcmToken(req, res, next) {
  try {
    if (sendValidationErrors(req, res)) return;

    await User.findByIdAndUpdate(req.user.userId, {
      fcmToken: req.body.token
    });

    res.json({ success: true });
  } catch (error) {
    next(error);
  }
}

module.exports = { register, login, refresh, logout, updateFcmToken };
