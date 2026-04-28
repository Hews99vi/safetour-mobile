const SafeZone = require('../models/SafeZone');

async function getNearbySafeZones(lat, lng) {
  const query = { isActive: true };

  const zones = await SafeZone.find(query).sort({ createdAt: -1 }).limit(50);

  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    return zones;
  }

  return zones.map((zone) => ({
    ...zone.toObject(),
    distanceKm: calculateDistanceKm(lat, lng, zone.coordinates.lat, zone.coordinates.lng)
  }));
}

function calculateDistanceKm(lat1, lng1, lat2, lng2) {
  const radiusKm = 6371;
  const dLat = toRadians(lat2 - lat1);
  const dLng = toRadians(lng2 - lng1);

  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) * Math.sin(dLng / 2) ** 2;

  return Number((radiusKm * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))).toFixed(2));
}

function toRadians(value) {
  return (value * Math.PI) / 180;
}

module.exports = { getNearbySafeZones };
