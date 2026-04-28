const admin = require('../config/firebase');

function getMessaging() {
  if (!admin.apps || admin.apps.length === 0) {
    return null;
  }

  return admin.messaging();
}

module.exports = { getMessaging };
