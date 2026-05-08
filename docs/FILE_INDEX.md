# File Index

## Backend

- `server.js`: Express bootstrap, health route, and global middleware
- `src/routes/auth.js`: Firebase-backed registration, login, and language preferences
- `src/routes/receipts.js`: upload, scan, import, edit, delete
- `src/routes/dashboard.js`: Firestore-backed summary and history
- `src/middleware/firebaseAuth.js`: Firebase ID token verification
- `src/middleware/upload.js`: multer memory upload rules
- `src/config/firebaseAdmin.js`: Firebase Admin bootstrap
- `src/config/runtimePaths.js`: project-root uploads directory helpers and local fallback URL builders
- `src/config/db.js`: Firestore collection helpers and timestamp utilities
- `src/config/receiptFiles.js`: supported receipt MIME types/extensions and localized upload messages
- `src/services/firestoreDataService.js`: Firestore CRUD for shops, users, receipts
- `src/services/firestoreDashboardService.js`: dashboard/history aggregation from Firestore receipt documents
- `src/services/storageService.js`: Firebase Cloud Storage upload/delete helpers
- `src/services/geminiService.js`: prompt/schema generation and Gemini calls from buffer or URL
- `src/services/dashboardTrendService.js`: dashboard period config and drilldown shaping
- `firestore.rules`: Firestore test-mode development rules
- `firebase.json`: Firebase CLI mapping for Firestore rules
- `uploads/`: local fallback receipt storage served by the API when Cloud Storage upload fails

## Flutter

- `mobile_app/lib/main.dart`: app shell, locale wiring, Firebase bootstrap call
- `mobile_app/lib/screens/scan_screen.dart`: receipt upload and scan entry point
- `mobile_app/lib/screens/dashboard_screen.dart`: summary UI
- `mobile_app/lib/screens/history_screen.dart`: receipt history UI
- `mobile_app/lib/screens/login_screen.dart`: Firebase Auth sign-in form
- `mobile_app/lib/screens/register_screen.dart`: Firebase Auth sign-up form
- `mobile_app/lib/screens/shop_setup_screen.dart`: Firestore shop/profile completion flow for accounts missing a shop
- `mobile_app/lib/services/firebase_bootstrap.dart`: guarded Firebase Core initialization
- `mobile_app/lib/services/firebase_web_plugin_registrant.dart`: conditional manual registration entry for Firebase web plugins
- `mobile_app/lib/services/firebase_web_plugin_registrant_web.dart`: web-only FirebaseCore/Auth/Firestore/Storage plugin registration
- `mobile_app/lib/services/auth_service.dart`: Firebase Auth + backend session/language persistence
- `mobile_app/lib/services/receipt_api_service.dart`: camera, file picking, upload preparation
- `mobile_app/lib/services/dashboard_service.dart`: backend dashboard/history/edit/delete calls
- `mobile_app/lib/utils/auth_error_message.dart`: localized auth error mapping
- `mobile_app/lib/utils/dashboard_trend.dart`: typed dashboard trend buckets and drilldown parsing
- `mobile_app/lib/utils/receipt_date_format.dart`: localized formatting for receipt and line-item dates
- `mobile_app/lib/widgets/animated_backdrop.dart`: shared animated gradient/orb backdrop
- `mobile_app/lib/widgets/dashboard_trend_chart.dart`: expandable trend bar chart with weekly drilldown animation
- `mobile_app/lib/widgets/motion_reveal.dart`: staggered entrance motion primitive
- `mobile_app/lib/widgets/hover_lift_card.dart`: hover/tap lift + glow motion wrapper
- `mobile_app/lib/widgets/language_switcher_button.dart`: shared language selector
- `mobile_app/lib/widgets/live_camera_capture_dialog_web.dart`: browser camera permission + live capture sheet
- `mobile_app/lib/widgets/live_camera_capture_dialog_stub.dart`: non-web fallback for the live capture sheet import
- `mobile_app/lib/l10n/*.arb`: localization source files

## Planning

- `LOCAL_RUN_PLAN.md`: ongoing work log and continuation state
- `rules.md`: repo operating spec for feature work
- `test.md`: verification policy
