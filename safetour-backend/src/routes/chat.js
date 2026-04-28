const express = require('express');
const { param } = require('express-validator');

const authMiddleware = require('../middleware/authMiddleware');
const chatController = require('../controllers/chatController');

const router = express.Router();

router.get(
  '/:roomId/history',
  authMiddleware,
  [
    param('roomId')
      .isString()
      .trim()
      .notEmpty()
      .withMessage('roomId is required')
  ],
  chatController.getHistory
);

module.exports = router;
