const express = require('express');
const authMiddleware = require('../middleware/authMiddleware');
const alertsController = require('../controllers/alertsController');

const router = express.Router();

router.get('/recent', authMiddleware, alertsController.getRecentAlerts);
router.post('/', authMiddleware, alertsController.createAlert);

module.exports = router;
