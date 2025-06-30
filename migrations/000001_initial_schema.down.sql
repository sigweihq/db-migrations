-- Drop all tables and indexes in reverse order

-- Drop indexes first
DROP INDEX IF EXISTS idx_purchases_created_at;
DROP INDEX IF EXISTS idx_purchases_paid_route_id;
DROP INDEX IF EXISTS idx_purchases_short_code;

DROP INDEX IF EXISTS idx_paid_routes_deleted_at;
DROP INDEX IF EXISTS idx_paid_routes_user_id;
DROP INDEX IF EXISTS idx_paid_routes_short_code;

DROP INDEX IF EXISTS idx_revoked_tokens_expires_at;

DROP INDEX IF EXISTS idx_refresh_tokens_expires_at;
DROP INDEX IF EXISTS idx_refresh_tokens_user_id;

DROP INDEX IF EXISTS idx_auth_nonces_expires_at;
DROP INDEX IF EXISTS idx_auth_nonces_wallet_address;

DROP INDEX IF EXISTS idx_users_payment_address;
DROP INDEX IF EXISTS idx_users_wallet_address;

-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS purchases;
DROP TABLE IF EXISTS paid_routes;
DROP TABLE IF EXISTS revoked_tokens;
DROP TABLE IF EXISTS refresh_tokens;
DROP TABLE IF EXISTS auth_nonces;
DROP TABLE IF EXISTS users;