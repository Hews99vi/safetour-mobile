const Alert = require('../models/Alert');
const SosReport = require('../models/SosReport');

const ALERT_RADIUS_METERS = 1000;
const SOS_RADIUS_METERS = 2000;
const SOS_LOOKBACK_MS = 24 * 60 * 60 * 1000;

const severityPoints = {
  critical: 25,
  high: 15,
  medium: 8,
  low: 3
};

async function calculateRiskScore({ lat, lng, timeOfDay, dayOfWeek }) {
  const latitude = Number(lat);
  const longitude = Number(lng);

  if (!Number.isFinite(latitude) || latitude < -90 || latitude > 90) {
    throw new Error('lat must be a valid latitude');
  }

  if (!Number.isFinite(longitude) || longitude < -180 || longitude > 180) {
    throw new Error('lng must be a valid longitude');
  }

  const context = normalizeTimeContext(timeOfDay, dayOfWeek);
  const factors = [];
  let score = 0;

  const alerts = await findNearbyAlerts(latitude, longitude);
  if (alerts.length > 0) {
    const alertScore = alerts.reduce(
      (total, alert) => total + (severityPoints[alert.severity] || 0),
      0
    );
    score += alertScore;
    factors.push(`${alerts.length} active alert${alerts.length === 1 ? '' : 's'} nearby`);
  }

  const timeRisk = calculateTimeRisk(context.hour);
  if (timeRisk.points > 0) {
    score += timeRisk.points;
    factors.push(timeRisk.factor);
  }

  if (isWeekendNight(context.dayOfWeek, context.hour)) {
    score += 10;
    factors.push('Friday or Saturday night risk');
  }

  const sosCount = await countRecentNearbySos(latitude, longitude);
  if (sosCount > 0) {
    const sosScore = Math.min(sosCount * 5, 20);
    score += sosScore;
    factors.push(
      `${sosCount} SOS report${sosCount === 1 ? '' : 's'} nearby in the last 24 hours`
    );
  }

  const cappedScore = Math.min(score, 100);

  return {
    score: cappedScore,
    level: riskLevelFromScore(cappedScore),
    factors,
    predictedAlerts: []
  };
}

async function findNearbyAlerts(lat, lng) {
  return Alert.find({
    isActive: true,
    location: {
      $nearSphere: {
        $geometry: {
          type: 'Point',
          coordinates: [lng, lat]
        },
        $maxDistance: ALERT_RADIUS_METERS
      }
    }
  }).select('severity type title location createdAt');
}

async function countRecentNearbySos(lat, lng) {
  const since = new Date(Date.now() - SOS_LOOKBACK_MS);

  return SosReport.countDocuments({
    createdAt: { $gte: since },
    location: {
      $nearSphere: {
        $geometry: {
          type: 'Point',
          coordinates: [lng, lat]
        },
        $maxDistance: SOS_RADIUS_METERS
      }
    }
  });
}

function normalizeTimeContext(timeOfDay, dayOfWeek) {
  const now = getSriLankaNow();
  const hour = parseHour(timeOfDay, now.hour);

  return {
    hour,
    dayOfWeek: normalizeDayOfWeek(dayOfWeek, now.dayOfWeek)
  };
}

function getSriLankaNow() {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone: 'Asia/Colombo',
    weekday: 'long',
    hour: '2-digit',
    hour12: false
  }).formatToParts(new Date());

  const hour = Number(parts.find((part) => part.type === 'hour')?.value || 0);
  const dayOfWeek = parts.find((part) => part.type === 'weekday')?.value || 'Monday';

  return { hour, dayOfWeek };
}

function parseHour(timeOfDay, fallbackHour) {
  if (typeof timeOfDay !== 'string' || timeOfDay.trim().length === 0) {
    return fallbackHour;
  }

  const match = timeOfDay.trim().match(/^(\d{1,2})(?::\d{2})?$/);
  if (!match) {
    return fallbackHour;
  }

  const hour = Number(match[1]);
  return Number.isInteger(hour) && hour >= 0 && hour <= 23 ? hour : fallbackHour;
}

function normalizeDayOfWeek(dayOfWeek, fallbackDay) {
  if (typeof dayOfWeek !== 'string' || dayOfWeek.trim().length === 0) {
    return fallbackDay.toLowerCase();
  }

  return dayOfWeek.trim().toLowerCase();
}

function calculateTimeRisk(hour) {
  if (hour >= 0 && hour < 5) {
    return { points: 20, factor: 'Late night hours' };
  }

  if (hour >= 22 && hour < 24) {
    return { points: 10, factor: 'Night hours' };
  }

  if (hour >= 18 && hour < 22) {
    return { points: 5, factor: 'Evening hours' };
  }

  return { points: 0, factor: null };
}

function isWeekendNight(dayOfWeek, hour) {
  const isFridayOrSaturday = dayOfWeek === 'friday' || dayOfWeek === 'saturday';
  return isFridayOrSaturday && (hour >= 18 || hour < 4);
}

function riskLevelFromScore(score) {
  if (score >= 75) return 'critical';
  if (score >= 50) return 'high';
  if (score >= 25) return 'medium';
  return 'low';
}

module.exports = { calculateRiskScore };
