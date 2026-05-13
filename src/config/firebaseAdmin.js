const admin = require('firebase-admin');

function parseServiceAccountFromEnv() {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!raw || !raw.trim()) {
    return null;
  }

  try {
    return JSON.parse(raw);
  } catch (error) {
    const wrapped = new Error(
      'FIREBASE_SERVICE_ACCOUNT is not valid JSON.'
    );
    wrapped.cause = error;
    throw wrapped;
  }
}

function hasFirebaseAdminConfig() {
  return Boolean(
    (process.env.FIREBASE_SERVICE_ACCOUNT || '').trim()
      || (process.env.GOOGLE_APPLICATION_CREDENTIALS || '').trim()
  );
}

function ensureFirebaseAdmin() {
  if (!admin.apps.length) {
    try {
      const serviceAccount = parseServiceAccountFromEnv();

      if (serviceAccount) {
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
        });
      } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
        admin.initializeApp();
      } else {
        throw new Error(
          'FIREBASE_SERVICE_ACCOUNT veya GOOGLE_APPLICATION_CREDENTIALS ortam degiskeni bulunamadi!'
        );
      }

      console.log('Firebase Admin basariyla baslatildi.');
    } catch (error) {
      console.error('Firebase Admin baslatma hatasi:', error);
      throw error;
    }
  }
  return admin;
}

function getFirebaseAdminDiagnostics() {
  const serviceAccount = parseServiceAccountFromEnv();

  return {
    credentialSource: serviceAccount
      ? 'env_firebase_service_account'
      : process.env.GOOGLE_APPLICATION_CREDENTIALS
        ? 'env_google_application_credentials'
        : 'none',
    credentialsPath: process.env.GOOGLE_APPLICATION_CREDENTIALS || null,
    storageBucket: process.env.FIREBASE_STORAGE_BUCKET || '(not set)',
  };
}

module.exports = {
  ensureFirebaseAdmin,
  hasFirebaseAdminConfig,
  getFirebaseAdminDiagnostics,
  admin,
};
