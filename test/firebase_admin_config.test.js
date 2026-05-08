const test = require('node:test');
const assert = require('node:assert/strict');

const firebaseAdmin = require('../src/config/firebaseAdmin');

test('Firebase Admin diagnostics prefer FIREBASE_SERVICE_ACCOUNT JSON', () => {
  const originalServiceAccount = process.env.FIREBASE_SERVICE_ACCOUNT;
  const originalLegacyServiceAccount = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  const originalProjectId = process.env.FIREBASE_PROJECT_ID;
  const originalClientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const originalPrivateKey = process.env.FIREBASE_PRIVATE_KEY;
  const originalCredentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;

  process.env.FIREBASE_SERVICE_ACCOUNT = JSON.stringify({
    projectId: 'render-project',
    clientEmail: 'firebase-adminsdk@example.com',
    privateKey: '-----BEGIN PRIVATE KEY-----\\nabc\\n-----END PRIVATE KEY-----\\n',
  });
  delete process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  delete process.env.FIREBASE_PROJECT_ID;
  delete process.env.FIREBASE_CLIENT_EMAIL;
  delete process.env.FIREBASE_PRIVATE_KEY;
  delete process.env.GOOGLE_APPLICATION_CREDENTIALS;

  const diagnostics = firebaseAdmin.getFirebaseAdminDiagnostics();
  assert.equal(diagnostics.credentialSource, 'env_firebase_service_account');
  assert.equal(firebaseAdmin.hasFirebaseAdminConfig(), true);

  restoreEnv('FIREBASE_SERVICE_ACCOUNT', originalServiceAccount);
  restoreEnv('FIREBASE_SERVICE_ACCOUNT_JSON', originalLegacyServiceAccount);
  restoreEnv('FIREBASE_PROJECT_ID', originalProjectId);
  restoreEnv('FIREBASE_CLIENT_EMAIL', originalClientEmail);
  restoreEnv('FIREBASE_PRIVATE_KEY', originalPrivateKey);
  restoreEnv('GOOGLE_APPLICATION_CREDENTIALS', originalCredentialsPath);
});

test('invalid FIREBASE_SERVICE_ACCOUNT JSON fails loudly', () => {
  const originalServiceAccount = process.env.FIREBASE_SERVICE_ACCOUNT;

  process.env.FIREBASE_SERVICE_ACCOUNT = '{broken-json';

  assert.throws(
    () => firebaseAdmin.getFirebaseAdminDiagnostics(),
    /FIREBASE_SERVICE_ACCOUNT is not valid JSON/
  );

  restoreEnv('FIREBASE_SERVICE_ACCOUNT', originalServiceAccount);
});

function restoreEnv(key, value) {
  if (value == null) {
    delete process.env[key];
  } else {
    process.env[key] = value;
  }
}
