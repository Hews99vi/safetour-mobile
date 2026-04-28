const locationService = require('../services/locationService');

async function getSafeZones(req, res, next) {
  try {
    const { lat, lng } = req.query;
    const zones = await locationService.getNearbySafeZones(Number(lat), Number(lng));
    res.json(zones);
  } catch (error) {
    next(error);
  }
}

module.exports = { getSafeZones };
