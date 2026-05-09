const admin = require('firebase-admin');

function ensureFirebaseAdmin() {
  if (!admin.apps.length) {
    try {
      if (!process.env.FIREBASE_SERVICE_ACCOUNT?.trim()) {
        throw new Error(
          "FIREBASE_SERVICE_ACCOUNT ortam degiskeni bulunamadi. Render ortam degiskenlerine tam service account JSON degerini ekleyin."
        );
      }

      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);

      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });

      console.log("Firebase Admin basariyla baslatildi.");
    } catch (error) {
      if (error instanceof SyntaxError) {
        console.error(
          "Firebase Admin baslatma hatasi: FIREBASE_SERVICE_ACCOUNT gecersiz JSON iceriyor.",
          error
        );
        throw error;
      }

      console.error("Firebase Admin baslatma hatasi:", error);
      throw error;
    }
  }
  return admin;
}

module.exports = { ensureFirebaseAdmin, admin };
