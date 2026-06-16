# Phase 8 Local Data Migration

## Goal

Move user-owned data from JSON strings in `SharedPreferences` to a transactional
local database without losing data created by older app versions.

## Current Safety Layer

- Existing storage keys remain unchanged for backward compatibility.
- Every JSON list keeps one previous-value backup.
- The app can export and restore a versioned full backup.
- Restore validates every section before writing any user data.

## Implemented Database Schema

The first SQLite version keeps each existing model payload intact. This reduces
migration risk while separating data by ownership and enabling transactions.

### spaces, products, care_records, search_requests, submissions

- `id` text primary key
- `sort_order` integer
- `payload_json`

Records keep their original space name even when a product later moves.

### app_metadata

- `key` text primary key
- `value`

Stores schema version, migration completion, and the last successful backup time.

## Future Normalization

Normalize frequently queried product, record, and consumable fields only after
real usage shows which indexes and cross-table queries are needed. The migration
must preserve the complete payload until normalized-field parity is verified.

## Migration Order

1. Open the new database and create all tables in one transaction.
2. Read and fully validate every legacy SharedPreferences list.
3. Insert spaces, products, records, consumables, and submissions.
4. Compare source and target row counts.
5. Mark `legacy_json_migration_v1` complete.
6. Keep the legacy JSON for one release as rollback data.
7. Remove legacy data only after a later verified release.

## Failure Rules

- Never mark migration complete after a partial insert.
- Roll back the complete transaction when any item cannot be decoded.
- Continue using legacy storage if database initialization fails.
- Offer backup export before retrying a failed migration.
- Log only counts and error categories, never product notes or backup contents.

## Verification

- Fresh install creates an empty database.
- Existing install migrates all supported legacy JSON.
- Reopening the app does not run migration twice.
- App termination during migration leaves legacy data usable.
- Products with no space remain valid.
- Deleted products do not remove historical care records.
- Export before and after migration contains equivalent user data.

## Implemented

- Android and iOS now use an SQLite database.
- Existing SharedPreferences JSON is validated and moved in one transaction.
- The migration completion flag is stored only after every table succeeds.
- Legacy SharedPreferences data is retained as rollback data.
- Spaces, products, records, requests, and submissions have separate tables.
- Recent searches and recently viewed products are stored as database metadata.
- Mobile backup restore replaces all user tables in one transaction.
- Windows widget tests continue to use the legacy adapter for deterministic tests.

## Remaining Sequence

1. Add direct SQLite contract tests with a test database factory.
2. Test migration interruption and rollback on Android integration tests.
3. Normalize consumables into their own table when query requirements grow.
4. Add backup file export when a stable cross-platform file flow is selected.
5. Keep the legacy JSON for at least one verified release before cleanup.
