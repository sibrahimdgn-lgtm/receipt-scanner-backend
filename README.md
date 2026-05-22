# Receipt Scanner

Multi-tenant receipt scanning platform with:
- Node.js + Express API
- Firebase Auth for end-user sign-in
- Firestore for tenant/shop/receipt data
- Firebase Cloud Storage for uploaded receipt files
- Flutter web/mobile client
- Qwen Vision-powered receipt extraction

## Current Scope

The app can ingest:
- JPG receipts
- PNG receipts
- HEIC / HEIF mobile screenshots and photos
- PDF e-invoices and digital receipts
- Live camera captures from the scan screen

It extracts:
- vendor name
- receipt date
- per-line transaction dates for bank statements or multi-date invoices
- totals and tax
- line items
- localized categories
- currency metadata
- downloadable PDF and CSV history exports from the History screen

## Project Layout

- `server.js`: API entry point
- `src/routes/`: auth, receipt, and dashboard endpoints
- `src/services/`: Firebase-backed persistence, Qwen Vision, Storage, and dashboard aggregation logic
- `src/config/`: Firebase admin, languages, categories, currency, and file-type config
- `mobile_app/`: Flutter application
- `firestore.rules`: Firestore development/test-mode rules
- `uploads/`: auto-created local fallback storage when Firebase Storage is unavailable
- `schema.sql`: Firestore/Storage data model reference
- `scripts/`: local web build and serve helpers
- `LOCAL_RUN_PLAN.md`: running project log and continuation notes

## Backend Environment

Create `.env` from `.env.example` and set:
- `QWEN_API_KEY`
- `FIREBASE_STORAGE_BUCKET`
- `FIREBASE_SERVICE_ACCOUNT` with the full JSON service account payload for hosted environments like Render
- one Firebase Admin credential strategy:
  - `FIREBASE_SERVICE_ACCOUNT`, or
  - `FIREBASE_SERVICE_ACCOUNT_JSON`, or
  - `FIREBASE_PROJECT_ID` + `FIREBASE_CLIENT_EMAIL` + `FIREBASE_PRIVATE_KEY`, or
  - `GOOGLE_APPLICATION_CREDENTIALS` in your shell for local file-based development
- optional `PORT`

At startup the API now validates:
- `FIREBASE_SERVICE_ACCOUNT` JSON is parseable when present
- `firebase-service-account.json` can be resolved from `GOOGLE_APPLICATION_CREDENTIALS` when using a local file
- the local `uploads/` directory exists and is writable
- Firebase Admin and Qwen config status are printed to the server console

## Flutter Firebase Configuration

The Flutter app initializes Firebase directly from the checked-in
`mobile_app/lib/firebase_options.dart` file via
`DefaultFirebaseOptions.currentPlatform`.

For Flutter Web debugging:
- `WidgetsFlutterBinding.ensureInitialized()` runs before Firebase startup
- `main.dart` logs initialization failures to the browser console
- `mobile_app/lib/services/firebase_web_plugin_registrant.dart` manually registers
  Firebase web plugins before the first `Firebase.initializeApp(...)` call
- `web/index.html` also loads Firebase App/Auth/Firestore/Storage SDK scripts
  so browser-side SDK availability is easy to inspect

If your Firebase project changes, regenerate or edit `firebase_options.dart`
instead of relying on runtime `--dart-define` overrides.

## Firestore Rules

The repo now includes a root `firestore.rules` file with Firebase test-mode
rules for local development. To push those rules to the `reecaiptscanner`
project:

```bash
firebase deploy --only firestore:rules --project reecaiptscanner
```

These rules allow all reads and writes and should be tightened before any
production deployment.

## Storage Fallback

Receipt uploads are processed from memory first. If Firebase Cloud Storage upload
fails, the backend now falls back to a local `uploads/` directory and serves
those files from `/uploads/...` so `POST /api/receipts/scan` can still succeed
in local development.

## Local Run

1. Start the API:
   - `node server.js`
2. Start the web client:
   - `./scripts/start_web_client.sh`

Default local URLs:
- API: `http://127.0.0.1:3000`
- Web: `http://127.0.0.1:8080`

## Verification Shortcuts

- Backend tests:
  - `node --test test/*.test.js`
- Flutter tests:
  - `/Users/ibrahimdogan/development/flutter/bin/flutter test`
- Web build:
  - `/Users/ibrahimdogan/development/flutter/bin/flutter build web --release`

See `test.md` and `docs/` for the current detailed references.
