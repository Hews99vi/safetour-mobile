const express = require('express');
const { body } = require('express-validator');
const authController = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

const emailValidation = body('email')
  .isEmail()
  .withMessage('Enter a valid email')
  .normalizeEmail();

const passwordValidation = body('password')
  .isLength({ min: 8 })
  .withMessage('Password must be at least 8 characters');

router.post(
  '/register',
  [
    emailValidation,
    passwordValidation,
    body('displayName')
      .optional()
      .isString()
      .trim()
      .notEmpty()
      .withMessage('Display name cannot be empty'),
    body('role')
      .optional()
      .isIn(['tourist', 'admin'])
      .withMessage('Role must be tourist or admin')
  ],
  authController.register
);

router.post(
  '/login',
  [emailValidation, passwordValidation],
  authController.login
);

router.post(
  '/refresh',
  [
    body('refreshToken')
      .isString()
      .trim()
      .notEmpty()
      .withMessage('Refresh token is required')
  ],
  authController.refresh
);

router.post(
  '/forgot-password',
  [emailValidation],
  authController.forgotPassword
);

router.post(
  '/reset-password',
  [
    body('token')
      .isString()
      .trim()
      .notEmpty()
      .withMessage('Reset token is required'),
    passwordValidation
  ],
  authController.resetPassword
);

router.post(
  '/logout',
  authMiddleware,
  [
    body('fcmToken')
      .optional()
      .isString()
      .trim()
      .notEmpty()
      .withMessage('FCM token cannot be empty')
  ],
  authController.logout
);

router.post(
  '/fcm-token',
  authMiddleware,
  [
    body('token')
      .isString()
      .trim()
      .notEmpty()
      .withMessage('FCM token is required')
  ],
  authController.updateFcmToken
);

module.exports = router;
