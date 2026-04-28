const admin = require('firebase-admin');

function initializeFirebase() {
  if (admin.apps.length) {
    return admin;
  }

  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;

  if (!serviceAccountJson) {
    console.warn('FIREBASE_SERVICE_ACCOUNT_JSON not provided. Firebase Admin not initialized.');
    return admin;
  }

  let serviceAccount;
  try {
    serviceAccount = JSON.parse(serviceAccountJson);
  } catch (error) {
    console.warn('FIREBASE_SERVICE_ACCOUNT_JSON is not valid JSON. Firebase Admin not initialized.');
    return admin;
  }

  try {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
  } catch (error) {
    console.warn(`Firebase Admin not initialized: ${error.message}`);
    return admin;
  }

  console.log('Firebase Admin initialized');
  return admin;
}

module.exports = initializeFirebase();
