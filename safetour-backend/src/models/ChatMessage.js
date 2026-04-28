const mongoose = require('mongoose');

const chatMessageSchema = new mongoose.Schema(
  {
    roomId: {
      type: String,
      required: true,
      index: true,
      trim: true
    },
    senderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    senderRole: {
      type: String,
      enum: ['tourist', 'authority'],
      required: true
    },
    content: {
      type: String,
      required: true,
      maxlength: 2000,
      trim: true
    },
    messageType: {
      type: String,
      enum: ['text', 'location', 'image'],
      default: 'text'
    },
    locationData: {
      lat: { type: Number },
      lng: { type: Number }
    },
    isRead: { type: Boolean, default: false }
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

module.exports = mongoose.model('ChatMessage', chatMessageSchema);
