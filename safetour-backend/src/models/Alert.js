const mongoose = require('mongoose');

const alertSchema = new mongoose.Schema(
  {
    type: {
      type: String,
      enum: ['crime', 'accident', 'weather', 'scam', 'unsafe_area'],
      required: true
    },
    title: { type: String, required: true, trim: true },
    description: { type: String, trim: true },
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
    severity: {
      type: String,
      enum: ['low', 'medium', 'high', 'critical'],
      required: true
    },
    source: {
      type: String,
      enum: ['official', 'community', 'ai'],
      required: true
    },
    reportedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    isActive: { type: Boolean, default: true },
    expiresAt: {
      type: Date,
      default: () => new Date(Date.now() + 6 * 60 * 60 * 1000)
    }
  },
  { timestamps: true }
);

alertSchema.index({ location: '2dsphere' });

module.exports = mongoose.model('Alert', alertSchema);
