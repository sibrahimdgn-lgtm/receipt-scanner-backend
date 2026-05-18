# API Reference

Base URL: `http://127.0.0.1:3000/api`

## Health

- `GET /health`
  - returns server status, timestamp, Firebase Admin status, Storage bucket name, Qwen config status, and local uploads fallback readiness

## Auth

- `POST /auth/register`
  - body: `{ idToken, shop_name, preferred_language?, currency? }`
  - verifies the Firebase ID token, creates or repairs Firestore `shops` and `users` docs, returns app session context
- `POST /auth/login`
  - body: `{ idToken, preferred_language? }`
  - verifies the Firebase ID token and returns Firestore tenant context
  - if the Firebase user exists but no shop/profile document is linked, returns `404` with `code=account_setup_required`
- `POST /auth/setup-shop`
  - body: `{ idToken, shop_name, preferred_language?, currency? }`
  - uses the current Firebase user to create a missing Firestore `shop` profile and repair the matching `users` doc
- `PUT /auth/preferences`
  - auth: `Authorization: Bearer <Firebase ID token>`
  - body: `{ preferred_language }`

Auth responses return:
- `token`
- `shopId`
- `email`
- `shopName`
- `currency`
- `preferredLanguage`
- `userId`

## Receipts

- `POST /receipts/scan`
  - multipart field: `receipt`
  - accepts JPG, PNG, WEBP, and PDF on the backend
  - uploads to Firebase Cloud Storage when available; falls back to local `/uploads/...` storage if Cloud Storage upload fails
  - guest calls return parsed data without saving
  - authenticated calls upload the source file to Firebase Cloud Storage and persist the receipt in Firestore
- `POST /receipts/import`
  - auth required
  - saves structured receipt JSON directly into Firestore
- `PUT /receipts/:id`
  - auth required
  - updates a Firestore receipt document
- `DELETE /receipts/:id`
  - auth required
  - deletes the Firestore receipt doc and any stored cloud file

`/receipts/scan` returns structured JSON with vendor, date, totals, currency, and localized line items.
Each line item can also include an optional `transaction_date` in `YYYY-MM-DD` format for bank statements or multi-date invoices.

## Dashboard

- `GET /dashboard/summary`
  - auth required
  - query: `period=daily|weekly|monthly|yearly`
  - optional query: `currency=TRY`
  - optional query: `timezoneOffset=<local-minus-UTC minutes>` to anchor
    daily/weekly/monthly/yearly boundaries to the user's local calendar day
  - response is aggregated in memory from Firestore receipt documents
- `GET /dashboard/history`
  - auth required
  - query: `page=<n>`

Dashboard and history are tenant-scoped and currency-aware.
When `period=monthly` or `period=yearly`, each `trend` bucket in `/dashboard/summary`
can also include a `drilldown` array with weekly sub-buckets so the client can expand
an aggregate bar into smaller weekly bars without making another request.
