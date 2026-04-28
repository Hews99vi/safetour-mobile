const mongoose = require('mongoose');

const sosReportSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
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
    status: {
      type: String,
      enum: ['pending', 'acknowledged', 'resolved', 'cancelled'],
      default: 'pending'
    },
    emergencyType: {
      type: String,
      enum: ['medical', 'theft', 'harassment', 'accident', 'fire', 'other'],
      required: true
    },
    description: { type: String, trim: true },
    respondedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    resolvedAt: { type: Date }
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

sosReportSchema.index({ location: '2dsphere' });

module.exports = mongoose.model('SosReport', sosReportSchema);
