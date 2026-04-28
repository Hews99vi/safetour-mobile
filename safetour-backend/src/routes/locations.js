const express = require('express');
const { query, validationResult } = require('express-validator');

const authMiddleware = require('../middleware/authMiddleware');
const SafeZone = require('../models/SafeZone');
const riskScoringService = require('../services/riskScoringService');

const router = express.Router();

const coordinateValidators = [
  query('lat')
    .isFloat({ min: -90, max: 90 })
    .withMessage('lat must be a valid latitude'),
  query('lng')
    .isFloat({ min: -180, max: 180 })
    .withMessage('lng must be a valid longitude')
];

router.get(
  '/risk-score',
  authMiddleware,
  coordinateValidators,
  async (req, res, next) => {
    try {
      const validationResponse = handleValidationErrors(req, res);
      if (validationResponse) return validationResponse;

      const result = await riskScoringService.calculateRiskScore({
        lat: Number(req.query.lat),
        lng: Number(req.query.lng)
      });

      return res.json({
        score: result.score,
        level: result.level,
        factors: result.factors,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      return next(error);
    }
  }
);

router.get(
  '/safe-zones',
  authMiddleware,
  [
    ...coordinateValidators,
    query('radius')
      .optional()
      .isFloat({ min: 1, max: 50000 })
      .withMessage('radius must be between 1 and 50000 meters')
  ],
  async (req, res, next) => {
    try {
      const validationResponse = handleValidationErrors(req, res);
      if (validationResponse) return validationResponse;

      const lat = Number(req.query.lat);
      const lng = Number(req.query.lng);
      const radius = Number(req.query.radius || 2000);

      const safeZones = await SafeZone.find({
        location: {
          $nearSphere: {
            $geometry: {
              type: 'Point',
              coordinates: [lng, lat]
            },
            $maxDistance: radius
          }
        }
      }).limit(10);

      return res.json(safeZones);
    } catch (error) {
      return next(error);
    }
  }
);

function handleValidationErrors(req, res) {
  const errors = validationResult(req);

  if (errors.isEmpty()) {
    return null;
  }

  return res.status(400).json({
    error: 'ValidationError',
    message: errors.array().map((item) => item.msg).join(', '),
    statusCode: 400
  });
}

module.exports = router;
