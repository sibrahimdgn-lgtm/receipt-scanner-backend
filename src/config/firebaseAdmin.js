const admin = require('firebase-admin');

// Giriş yaparken aranan o eksik minik fonksiyonu buraya ekledik
function hasFirebaseAdminConfig() {
  return !!process.env.FIREBASE_SERVICE_ACCOUNT || !!process.env.GOOGLE_APPLICATION_CREDENTIALS;
}

function ensureFirebaseAdmin() {
  if (!admin.apps.length) {
    try {
      if (process.env.FIREBASE_SERVICE_ACCOUNT) {
        const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount)
        });
      } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
        admin.initializeApp();
      } else {
        throw new Error("FIREBASE_SERVICE_ACCOUNT veya GOOGLE_APPLICATION_CREDENTIALS ortam degiskeni bulunamadi!");
      }
      console.log("Firebase Admin basariyla baslatildi.");
    } catch (error) {
      console.error("Firebase Admin baslatma hatasi:", error);
      throw error;
    }
  }
  return admin;
}

function getFirebaseAdminDiagnostics() {
  return {
    credentialSource: process.env.FIREBASE_SERVICE_ACCOUNT ? 'FIREBASE_SERVICE_ACCOUNT (env)' : (process.env.GOOGLE_APPLICATION_CREDENTIALS ? 'GOOGLE_APPLICATION_CREDENTIALS' : 'None'),
    credentialsPath: process.env.GOOGLE_APPLICATION_CREDENTIALS || null,
    storageBucket: process.env.FIREBASE_STORAGE_BUCKET || '(not set)'
  };
}

module.exports = { ensureFirebaseAdmin, hasFirebaseAdminConfig, getFirebaseAdminDiagnostics, admin };
