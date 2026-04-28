const express = require('express');
const { body, param } = require('express-validator');

const authMiddleware = require('../middleware/authMiddleware');
const sosController = require('../controllers/sosController');

const router = express.Router();

const emergencyTypes = ['medical', 'theft', 'harassment', 'accident', 'fire', 'other'];
const statusUpdates = ['acknowledged', 'resolved'];

router.post(
  '/report',
  authMiddleware,
  [
    body('lat')
      .isFloat({ min: -90, max: 90 })
      .withMessage('lat must be a valid latitude'),
    body('lng')
      .isFloat({ min: -180, max: 180 })
      .withMessage('lng must be a valid longitude'),
    body('emergencyType')
      .isIn(emergencyTypes)
      .withMessage(`emergencyType must be one of: ${emergencyTypes.join(', ')}`),
    body('description')
      .optional()
      .isString()
      .trim()
      .isLength({ max: 2000 })
      .withMessage('description must be 2000 characters or less')
  ],
  sosController.reportSos
);

router.post(
  '/:sosId/cancel',
  authMiddleware,
  [param('sosId').isMongoId().withMessage('sosId must be a valid Mongo ID')],
  sosController.cancelSos
);

router.get('/active', authMiddleware, sosController.getActiveSosReports);

router.patch(
  '/:sosId/status',
  authMiddleware,
  [
    param('sosId').isMongoId().withMessage('sosId must be a valid Mongo ID'),
    body('status')
      .isIn(statusUpdates)
      .withMessage(`status must be one of: ${statusUpdates.join(', ')}`)
  ],
  sosController.updateSosStatus
);

module.exports = router;
