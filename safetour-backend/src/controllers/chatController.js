const { validationResult } = require('express-validator');

const ChatMessage = require('../models/ChatMessage');

function hasRoomAccess(req, roomId) {
  if (req.user.role === 'admin') {
    return true;
  }

  return roomId === `tourist_${req.user.userId}`;
}

async function getHistory(req, res, next) {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'ValidationError',
        message: errors.array().map((item) => item.msg).join(', '),
        statusCode: 400
      });
    }

    const { roomId } = req.params;

    if (!hasRoomAccess(req, roomId)) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'You do not have access to this room.',
        statusCode: 403
      });
    }

    const messages = await ChatMessage.find({ roomId })
      .sort({ createdAt: -1 })
      .limit(50);

    res.json(messages.reverse());
  } catch (error) {
    next(error);
  }
}

module.exports = { getHistory };
