const admin = require('firebase-admin');

// Giriş yaparken aranan o eksik minik fonksiyonu buraya ekledik
function hasFirebaseAdminConfig() {
  return !!process.env.FIREBASE_SERVICE_ACCOUNT;
}

function ensureFirebaseAdmin() {
  if (!admin.apps.length) {
    try {
      if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
        throw new Error("FIREBASE_SERVICE_ACCOUNT ortam degiskeni bulunamadi!");
      }
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });
      console.log("Firebase Admin basariyla baslatildi.");
    } catch (error) {
      console.error("Firebase Admin baslatma hatasi:", error);
      throw error;
    }
  }
  return admin;
}

// En alta "hasFirebaseAdminConfig" adını da ekledik ki diğer dosyalar bunu görebilsin
module.exports = { ensureFirebaseAdmin, hasFirebaseAdminConfig, admin };
