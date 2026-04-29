const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    passwordHash: { type: String, required: true },
    displayName: { type: String, required: true, trim: true },
    role: { type: String, enum: ['tourist', 'admin'], default: 'tourist' },
    fcmToken: { type: String },
    language: { type: String, default: 'en', trim: true },
    lastLoginAt: { type: Date },
    resetPasswordTokenHash: { type: String },
    resetPasswordExpiresAt: { type: Date }
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

module.exports = mongoose.model('User', userSchema);
