const Alert = require('../models/Alert');

function toNumber(value) {
  if (value == null || value === '') return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

async function getRecentAlerts(req, res, next) {
  try {
    const lat = toNumber(req.query.lat);
    const lng = toNumber(req.query.lng);
    const radius = toNumber(req.query.radius) || 5000;
    const limit = Math.min(toNumber(req.query.limit) || 50, 100);
    const { type } = req.query;

    const query = { isActive: true };
    if (typeof type === 'string' && type.trim()) {
      query.type = type.trim();
    }
    if (lat !== null && lng !== null) {
      query.location = {
        $geoWithin: {
          $centerSphere: [[lng, lat], radius / 6378100]
        }
      };
    }

    const alerts = await Alert.find(query).sort({ createdAt: -1 }).limit(limit);
    res.json(alerts);
  } catch (error) {
    next(error);
  }
}

async function createAlert(req, res, next) {
  try {
    const alert = await Alert.create(req.body);
    res.status(201).json(alert);
  } catch (error) {
    next(error);
  }
}

module.exports = { getRecentAlerts, createAlert };
