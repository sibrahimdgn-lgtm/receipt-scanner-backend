const crypto = require('crypto');

const { admin, getFirestore, hasFirebaseAdminConfig } = require('./firebaseAdmin');

const COLLECTIONS = {
  shops: 'shops',
  users: 'users',
  receipts: 'receipts',
};

function firestore() {
  return admin.firestore();
}

function collection(name) {
  return firestore().collection(name);
}

function shopsCollection() {
  return collection(COLLECTIONS.shops);
}

function usersCollection() {
  return collection(COLLECTIONS.users);
}

function receiptsCollection() {
  return collection(COLLECTIONS.receipts);
}

function serverTimestamp() {
  return admin.firestore.FieldValue.serverTimestamp();
}

function timestampFromDate(value) {
  if (!value) {
    return null;
  }

  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) {
    return null;
  }

  return admin.firestore.Timestamp.fromDate(date);
}

function serializeTimestamp(value) {
  if (!value) {
    return null;
  }

  if (typeof value.toDate === 'function') {
    return value.toDate().toISOString();
  }

  if (value instanceof Date) {
    return value.toISOString();
  }

  return value;
}

function normalizeDocument(value) {
  if (Array.isArray(value)) {
    return value.map((entry) => normalizeDocument(entry));
  }

  if (!value || typeof value !== 'object') {
    return serializeTimestamp(value);
  }

  const plain = {};
  for (const [key, entry] of Object.entries(value)) {
    plain[key] = normalizeDocument(entry);
  }
  return plain;
}

function newId() {
  return crypto.randomUUID();
}

module.exports = {
  COLLECTIONS,
  firestore,
  hasFirebaseAdminConfig,
  newId,
  normalizeDocument,
  receiptsCollection,
  serverTimestamp,
  serializeTimestamp,
  shopsCollection,
  timestampFromDate,
  usersCollection,
};
