const fs = require('fs');
const path = require('path');

const admin = require('firebase-admin');

const PROJECT_ROOT = path.resolve(__dirname, '../..');

function parseServiceAccountJson() {
  if (!process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    return null;
  }

  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON.trim();
  if (!raw) {
    return null;
  }

  return JSON.parse(raw);
}

function buildServiceAccountFromEnv() {
  const projectId = process.env.FIREBASE_PROJECT_ID?.trim();
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL?.trim();
  const privateKey = process.env.FIREBASE_PRIVATE_KEY
    ?.replace(/\\n/g, '\n')
    .trim();

  if (!projectId || !clientEmail || !privateKey) {
    return null;
  }

  return {
    projectId,
    clientEmail,
    privateKey,
  };
}

function getServiceAccount() {
  return parseServiceAccountJson() || buildServiceAccountFromEnv();
}

function getGoogleApplicationCredentialsPath() {
  const rawPath = process.env.GOOGLE_APPLICATION_CREDENTIALS?.trim();

  if (!rawPath) {
    return null;
  }

  return path.isAbsolute(rawPath)
    ? rawPath
    : path.resolve(PROJECT_ROOT, rawPath);
}

function hasFirebaseAdminConfig() {
  const credentialsPath = getGoogleApplicationCredentialsPath();

  return Boolean(
    getServiceAccount()
    || credentialsPath
  );
}

function ensureFirebaseAdmin() {
  if (admin.apps.length > 0) {
    return admin.app();
  }

  const serviceAccount = getServiceAccount();
  const credentialsPath = getGoogleApplicationCredentialsPath();
  const storageBucket = process.env.FIREBASE_STORAGE_BUCKET?.trim();

  if (credentialsPath) {
    if (!fs.existsSync(credentialsPath)) {
      throw new Error(
        `Firebase service account file not found at ${credentialsPath}.`
      );
    }
    process.env.GOOGLE_APPLICATION_CREDENTIALS = credentialsPath;
  }

  if (!serviceAccount) {
    if (!credentialsPath) {
      throw new Error(
        'Firebase Admin is not configured. Set FIREBASE_SERVICE_ACCOUNT_JSON or FIREBASE_PROJECT_ID/FIREBASE_CLIENT_EMAIL/FIREBASE_PRIVATE_KEY, or provide GOOGLE_APPLICATION_CREDENTIALS.'
      );
    }
  }

  const options = {
    credential: serviceAccount
      ? admin.credential.cert(serviceAccount)
      : admin.credential.applicationDefault(),
  };

  if (storageBucket) {
    options.storageBucket = storageBucket;
  }

  return admin.initializeApp(options);
}

function getFirestore() {
  return ensureFirebaseAdmin().firestore();
}

function getAuth() {
  return ensureFirebaseAdmin().auth();
}

function getStorageBucket() {
  const storageBucket = process.env.FIREBASE_STORAGE_BUCKET?.trim();

  if (!storageBucket) {
    throw new Error(
      'Firebase Storage bucket is not configured. Set FIREBASE_STORAGE_BUCKET.'
    );
  }

  return ensureFirebaseAdmin().storage().bucket(storageBucket);
}

function getFirebaseAdminDiagnostics() {
  const credentialsPath = getGoogleApplicationCredentialsPath();
  const serviceAccount = getServiceAccount();

  return {
    credentialsPath,
    credentialsPathExists: credentialsPath ? fs.existsSync(credentialsPath) : false,
    credentialSource: serviceAccount
      ? 'env_service_account'
      : credentialsPath
        ? 'google_application_credentials'
        : 'missing',
    projectId:
      serviceAccount?.projectId
      || process.env.FIREBASE_PROJECT_ID?.trim()
      || null,
    storageBucket: process.env.FIREBASE_STORAGE_BUCKET?.trim() || null,
  };
}

module.exports = {
  admin,
  ensureFirebaseAdmin,
  getFirebaseAdminDiagnostics,
  getAuth,
  getFirestore,
  getStorageBucket,
  hasFirebaseAdminConfig,
};
