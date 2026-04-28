const { getMessaging } = require('./firebaseService');

function normalizeData(data = {}) {
  return Object.fromEntries(
    Object.entries(data).map(([key, value]) => [key, String(value)])
  );
}

async function sendToDevice(fcmToken, { title, body, data = {} }) {
  if (!fcmToken) {
    console.log('FCM token missing. Device notification skipped.');
    return null;
  }

  const messaging = getMessaging();
  if (!messaging) {
    console.log('Firebase messaging unavailable. Device notification skipped.');
    return null;
  }

  try {
    return await messaging.send({
      token: fcmToken,
      notification: { title, body },
      data: normalizeData(data)
    });
  } catch (error) {
    console.log(`Device notification failed: ${error.message}`);
    return null;
  }
}

async function sendToMultiple(tokens, { title, body, data = {} }) {
  const validTokens = [...new Set((tokens || []).filter(Boolean))];

  if (validTokens.length === 0) {
    console.log('FCM tokens missing. Multicast notification skipped.');
    return null;
  }

  const messaging = getMessaging();
  if (!messaging) {
    console.log('Firebase messaging unavailable. Multicast notification skipped.');
    return null;
  }

  try {
    return await messaging.sendEachForMulticast({
      tokens: validTokens,
      notification: { title, body },
      data: normalizeData(data)
    });
  } catch (error) {
    console.log(`Multicast notification failed: ${error.message}`);
    return null;
  }
}

async function notifyAuthorities(sosReport) {
  const messaging = getMessaging();

  if (!messaging) {
    console.log('Firebase messaging unavailable. SOS notification skipped.');
    return null;
  }

  try {
    return await messaging.send({
      topic: 'sos-alerts',
      notification: {
        title: 'New SafeTour SOS',
        body: 'A tourist has sent an emergency SOS report.'
      },
      data: {
        sosReportId: sosReport._id.toString(),
        screen: 'sos'
      }
    });
  } catch (error) {
    console.log(`Authority topic notification failed: ${error.message}`);
    return null;
  }
}

module.exports = { notifyAuthorities, sendToDevice, sendToMultiple };
