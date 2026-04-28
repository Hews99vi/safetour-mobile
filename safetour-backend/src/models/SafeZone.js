const mongoose = require('mongoose');

const safeZoneSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    type: {
      type: String,
      enum: ['police', 'hospital', 'embassy', 'safe_area', 'landmark'],
      required: true
    },
    location: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point',
        required: true
      },
      coordinates: {
        type: [Number],
        required: true
      }
    },
    address: { type: String, trim: true },
    phone: { type: String, trim: true },
    isVerified: { type: Boolean, default: false },
    addedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    }
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

safeZoneSchema.index({ location: '2dsphere' });

module.exports = mongoose.model('SafeZone', safeZoneSchema);
