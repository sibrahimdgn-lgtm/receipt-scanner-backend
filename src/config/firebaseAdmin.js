const admin = require('firebase-admin');

function ensureFirebaseAdmin() {
  if (!admin.apps.length) {
    try {
      // 1. Ortam değişkeni var mı kontrol et
      if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
        throw new Error("FIREBASE_SERVICE_ACCOUNT ortam degiskeni bulunamadi! Render uzerinde eklendiginden emin olun.");
      }

      // 2. Metni JSON'a çevir
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);

      // 3. Firebase'i başlat (Dosya yolu yok, direkt JSON verisi var)
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

module.exports = { ensureFirebaseAdmin, admin };