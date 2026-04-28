const { validationResult } = require('express-validator');

const SosReport = require('../models/SosReport');
const User = require('../models/User');
const notificationService = require('../services/notificationService');
const { getIo } = require('../services/chatService');

const activeStatuses = ['pending', 'acknowledged'];

function sendValidationErrors(req, res) {
  const errors = validationResult(req);

  if (errors.isEmpty()) {
    return false;
  }

  return res.status(400).json({
    error: 'ValidationError',
    message: errors.array().map((item) => item.msg).join(', '),
    statusCode: 400
  });
}

function forbidden(res, message) {
  return res.status(403).json({
    error: 'Forbidden',
    message,
    statusCode: 403
  });
}

function notFound(res, message) {
  return res.status(404).json({
    error: 'NotFound',
    message,
    statusCode: 404
  });
}

function requireRole(req, res, role) {
  if (req.user.role !== role) {
    forbidden(res, `${role} role required.`);
    return false;
  }

  return true;
}

function emitSosEvent(eventName, report) {
  const io = getIo();
  if (!io) return;
  io.emit(eventName, { report });
}

async function populateSosReport(report) {
  return report.populate('userId', 'email displayName');
}

async function reportSos(req, res, next) {
  try {
    if (sendValidationErrors(req, res)) return;
    if (!requireRole(req, res, 'tourist')) return;

    const lat = Number(req.body.lat);
    const lng = Number(req.body.lng);
    const { emergencyType, description } = req.body;

    const report = await SosReport.create({
      userId: req.user.userId,
      location: {
        type: 'Point',
        coordinates: [lng, lat]
      },
      status: 'pending',
      emergencyType,
      description
    });
    const populatedReport = await populateSosReport(report);

    const authorities = await User.find({
      role: 'admin',
      fcmToken: { $exists: true, $ne: '' }
    }).select('fcmToken');

    await notificationService.sendToMultiple(
      authorities.map((authority) => authority.fcmToken),
      {
        title: `🚨 SOS Alert — ${emergencyType}`,
        body: `Tourist needs help at ${lat},${lng}`,
        data: {
          sosId: report._id.toString(),
          lat,
          lng,
          emergencyType,
          userId: req.user.userId
        }
      }
    );

    res.status(201).json({
      sosId: report._id.toString(),
      status: 'pending',
      message: 'Help is on the way'
    });
    emitSosEvent('sos_new', populatedReport);
  } catch (error) {
    next(error);
  }
}

async function cancelSos(req, res, next) {
  try {
    if (sendValidationErrors(req, res)) return;

    const report = await SosReport.findById(req.params.sosId);
    if (!report) {
      return notFound(res, 'SOS report not found.');
    }

    if (report.userId.toString() !== req.user.userId) {
      return forbidden(res, 'Only the SOS owner can cancel this report.');
    }

    if (!activeStatuses.includes(report.status)) {
      return res.status(400).json({
        error: 'ValidationError',
        message: 'Only pending or acknowledged SOS reports can be cancelled.',
        statusCode: 400
      });
    }

    report.status = 'cancelled';
    const updated = await report.save();
    const populatedReport = await populateSosReport(updated);

    res.json(populatedReport);
    emitSosEvent('sos_updated', populatedReport);
  } catch (error) {
    next(error);
  }
}

async function getActiveSosReports(req, res, next) {
  try {
    if (!requireRole(req, res, 'admin')) return;

    const reports = await SosReport.find({ status: { $in: activeStatuses } })
      .populate('userId', 'email displayName')
      .sort({ createdAt: -1 });

    res.json(reports);
  } catch (error) {
    next(error);
  }
}

async function updateSosStatus(req, res, next) {
  try {
    if (sendValidationErrors(req, res)) return;
    if (!requireRole(req, res, 'admin')) return;

    const report = await SosReport.findById(req.params.sosId).populate(
      'userId',
      'email displayName fcmToken'
    );

    if (!report) {
      return notFound(res, 'SOS report not found.');
    }

    report.status = req.body.status;
    report.respondedBy = req.user.userId;
    report.resolvedAt = req.body.status === 'resolved' ? new Date() : undefined;

    const updated = await report.save();
    const tourist = report.userId;

    if (tourist?.fcmToken) {
      await notificationService.sendToDevice(tourist.fcmToken, {
        title: `Your SOS has been ${req.body.status}`,
        body:
          req.body.status === 'resolved'
            ? 'Your SOS case has been marked resolved.'
            : 'An authority has acknowledged your SOS.',
        data: {
          sosId: updated._id.toString(),
          status: updated.status
        }
      });
    }

    res.json(updated);
    emitSosEvent('sos_updated', updated);
  } catch (error) {
    next(error);
  }
}

module.exports = {
  reportSos,
  cancelSos,
  getActiveSosReports,
  updateSosStatus
};
