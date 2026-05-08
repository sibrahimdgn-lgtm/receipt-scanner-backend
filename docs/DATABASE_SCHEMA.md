# Database Schema Overview

## Runtime Source Of Truth

The app now uses Firebase instead of PostgreSQL:

- Firebase Auth
  - user identity and email/password sign-in
- Firestore
  - multi-tenant app data for shops, users, and receipts
- Firebase Cloud Storage
  - uploaded receipt source files

## Firestore Collections

### `shops`

One document per tenant/shop:
- `shop_id`
- `name`
- `email`
- `currency`
- `owner_user_id`
- `created_at`
- `updated_at`

### `users`

One document per Firebase Auth UID:
- `user_id`
- `shop_id`
- `email`
- `preferred_language`
- `created_at`
- `updated_at`

### `receipts`

One document per scanned or imported receipt:
- `receipt_id`
- `shop_id`
- `user_id`
- `vendor_name`
- `receipt_date`
- `scanned_image_url`
- `scanned_image_path`
- `original_filename`
- `mime_type`
- `currency_code`
- `currency_symbol`
- `currency_source`
- `currency_confidence`
- `total_amount`
- `tax_amount`
- `item_count`
- `line_items` (embedded array)
- `created_at`
- `updated_at`

### Embedded `line_items`

Each receipt document stores its extracted items inline:
- `line_item_id`
- `item_name`
- `transaction_date`
- `quantity`
- `unit_price`
- `total_price`
- `category`

## Storage Layout

Receipt source files are stored at paths like:

`shops/{shopId}/receipts/{timestamp}-{userId}-{filename}`

The generated download URL is stored in `receipts.scanned_image_url`.

## Legacy Notes

- `schema.sql` is now a documentation artifact for the Firestore model.
- Old PostgreSQL migration scripts and local Postgres helper scripts were removed
  from the runtime workspace during the Firebase migration cleanup.
