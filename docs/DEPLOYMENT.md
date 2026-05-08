# Deployment Notes

## Runtime Architecture

- Backend auth verification: Firebase Admin
- Primary data store: Firestore
- Receipt file store: Firebase Cloud Storage
- Client auth: Firebase Auth
- AI extraction: Gemini API

## Backend Environment

Required:
- `GEMINI_API_KEY`
- `FIREBASE_STORAGE_BUCKET`
- local default key path: `GOOGLE_APPLICATION_CREDENTIALS=./firebase-service-account.json`
- one of:
  - `FIREBASE_SERVICE_ACCOUNT_JSON`
  - `FIREBASE_PROJECT_ID` + `FIREBASE_CLIENT_EMAIL` + `FIREBASE_PRIVATE_KEY`
  - `GOOGLE_APPLICATION_CREDENTIALS`

Optional:
- `PORT`

Startup checks now validate that:
- `GOOGLE_APPLICATION_CREDENTIALS` resolves to a readable `firebase-service-account.json`
- the local `uploads/` fallback directory exists and is writable
- Firebase Admin and Gemini config status are printed to the API console

## Firestore Rules

- Root `firestore.rules` is configured in Firebase test mode for development.
- Deploy it with:
  - `firebase deploy --only firestore:rules --project reecaiptscanner`
- These rules are intentionally permissive and should be replaced before production.

## Flutter Client Configuration

The Flutter client initializes Firebase from the checked-in
`mobile_app/lib/firebase_options.dart` file using
`DefaultFirebaseOptions.currentPlatform`.

Web startup details:
- `main.dart` calls `WidgetsFlutterBinding.ensureInitialized()` before Firebase
- Firebase init failures are printed to the browser console with stack traces
- Firebase web plugins are manually registered before initialization to avoid
  `FirebaseCoreHostApi.initializeCore` channel errors in web builds
- `mobile_app/web/index.html` loads Firebase App/Auth/Firestore/Storage SDK
  scripts for easier browser-side debugging

If the Firebase project changes, regenerate `firebase_options.dart`.

## Local Runtime

- API: `127.0.0.1:3000`
- Web: `127.0.0.1:8080`

## Local Scripts

- `scripts/start_web_client.sh`
- `scripts/build_web_client.sh`

## Notes

- The backend no longer requires PostgreSQL.
- Firebase Cloud Storage remains the primary receipt store, but failed uploads now fall back to local `uploads/` storage served from `/uploads/...`.
- Legacy PostgreSQL helper scripts and old JWT compatibility middleware were removed.
- `mobile_app/build/web` remains the Flutter web output directory.
- If stale UI persists after rebuild, hard refresh the browser.
