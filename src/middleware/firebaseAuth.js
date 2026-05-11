const { hasFirebaseAdminConfig, admin } = require('../config/firebaseAdmin');

function extractBearerToken(req) {
  const authHeader = req.headers.authorization || req.headers.Authorization;
  if (typeof authHeader !== 'string' || !authHeader.startsWith('Bearer ')) {
    return null;
  }

  const token = authHeader.slice(7).trim();
  return token || null;
}

function buildAuthError(message, statusCode) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}

async function verifyFirebaseIdToken(idToken) {
  if (!idToken) {
    throw buildAuthError('Authorization token required.', 401);
  }

  if (!hasFirebaseAdminConfig()) {
    throw buildAuthError(
      'Firebase Admin is not configured on the server.',
      500
    );
  }

  try {
    return await admin.auth().verifyIdToken(idToken);
  } catch (error) {
    console.error("GERCEK FIREBASE HATASI:", error);
    console.log("GELEN TOKEN:", idToken);
    throw buildAuthError('Invalid or expired Firebase token.', 401);
  }
}

async function firebaseAuth(req, res, next) {
  try {
    const decodedToken = await verifyFirebaseIdToken(extractBearerToken(req));
    req.firebaseUser = decodedToken;
    req.userId = decodedToken.uid;
    req.email = decodedToken.email || null;
    req.idToken = extractBearerToken(req);
    next();
  } catch (error) {
    return res
      .status(error.statusCode || 500)
      .json({ error: error.message || 'Authentication failed.' });
  }
}

async function optionalFirebaseAuth(req, res, next) {
  const token = extractBearerToken(req);
  if (!token) {
    return next();
  }

  try {
    const decodedToken = await verifyFirebaseIdToken(token);
    req.firebaseUser = decodedToken;
    req.userId = decodedToken.uid;
    req.email = decodedToken.email || null;
    req.idToken = token;
    next();
  } catch (error) {
    return res
      .status(error.statusCode || 500)
      .json({ error: error.message || 'Authentication failed.' });
  }
}

module.exports = firebaseAuth;
module.exports.extractBearerToken = extractBearerToken;
module.exports.optionalFirebaseAuth = optionalFirebaseAuth;
module.exports.verifyFirebaseIdToken = verifyFirebaseIdToken;
