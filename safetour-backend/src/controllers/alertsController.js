const Alert = require('../models/Alert');

async function getRecentAlerts(req, res, next) {
  try {
    const alerts = await Alert.find({ isActive: true }).sort({ createdAt: -1 }).limit(50);
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
