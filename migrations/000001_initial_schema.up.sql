-- Consolidated initial schema for wallet-based authentication system

-- users table with wallet authentication
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    
    -- wallet_address is the Ethereum wallet address (primary identifier)
    wallet_address VARCHAR(42) UNIQUE NOT NULL,
    
    -- payment_address is the custom payment address (optional override)
    payment_address TEXT NOT NULL DEFAULT '',
    
    -- Standard timestamp fields
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auth nonces for replay attack prevention
CREATE TABLE auth_nonces (
    nonce VARCHAR(64) PRIMARY KEY,
    wallet_address VARCHAR(42) NOT NULL,
    timestamp BIGINT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Refresh tokens for stateful JWT management
CREATE TABLE refresh_tokens (
    id BIGSERIAL PRIMARY KEY,
    token_hash VARCHAR(64) UNIQUE NOT NULL,
    user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
    expires_at TIMESTAMPTZ NOT NULL,
    is_revoked BOOLEAN DEFAULT FALSE,
    device_info TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Revoked JWT tokens for immediate revocation
CREATE TABLE revoked_tokens (
    jti VARCHAR(32) PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
    reason TEXT,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- paid_routes table for configurable, paid API routes
CREATE TABLE paid_routes (
    id BIGSERIAL PRIMARY KEY,
    
    -- short_code is the unique identifier for the route in URLs
    short_code TEXT NOT NULL,
    
    -- target_url is the destination URL to proxy requests to
    target_url TEXT NOT NULL,
    
    -- method is the HTTP method allowed for this route
    method TEXT NOT NULL,
    
    -- price is the amount charged for accessing this route in Wei (token base units)
    price BIGINT NOT NULL,
    
    -- type indicates route type: "credit" or "subscription"
    type TEXT NOT NULL DEFAULT 'credit',
    
    -- credits is the number of credits for credit-based routes
    credits INT NOT NULL DEFAULT 1,
    
    -- is_test indicates whether this route uses testnet or mainnet
    is_test BOOLEAN NOT NULL,
    
    -- user_id is the owner of this route
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- is_enabled controls whether the route is active
    is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    
    -- resource_type indicates if this is a "url" or "file" route
    resource_type TEXT NOT NULL DEFAULT 'url',
    
    -- original_filename for file uploads
    original_filename TEXT,
    
    -- cover_url for route preview images
    cover_url TEXT,
    
    -- title for the route
    title TEXT,
    
    -- description for the route
    description TEXT,
    
    -- sigwei_secret is the secret for forwarded request verification
    sigwei_secret TEXT NOT NULL,
    
    -- Statistics counters
    attempt_count INT NOT NULL DEFAULT 0,
    payment_count INT NOT NULL DEFAULT 0,
    access_count INT NOT NULL DEFAULT 0,
    
    -- Standard timestamp fields
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Soft delete support
    deleted_at TIMESTAMPTZ
);

-- purchases table for successful payment transactions
CREATE TABLE purchases (
    id BIGSERIAL PRIMARY KEY,
    
    -- short_code is the short code of the accessed route
    short_code TEXT NOT NULL,
    
    -- target_url is the destination URL that was accessed
    target_url TEXT NOT NULL,
    
    -- method is the HTTP method used
    method TEXT NOT NULL,
    
    -- price is the amount charged in Wei (token base units)
    price BIGINT NOT NULL,
    
    -- type indicates purchase type
    type TEXT NOT NULL DEFAULT 'credit',
    
    -- credits tracking for credit-based purchases
    credits_available INT NOT NULL DEFAULT 0,
    credits_used INT NOT NULL DEFAULT 0,
    
    -- is_test indicates whether this was a testnet or mainnet transaction
    is_test BOOLEAN NOT NULL,
    
    -- payment_header stores the X-Payment header
    payment_header TEXT,
    
    -- payment_payload stores the payment data as bytes
    payment_payload BYTEA,
    
    -- settle_response stores the settled response as bytes
    settle_response BYTEA,
    
    -- paid_route_id is the associated PaidRoute
    paid_route_id BIGINT NOT NULL REFERENCES paid_routes(id) ON DELETE CASCADE,
    
    -- paid_to_address is the address to which payment was made
    paid_to_address TEXT NOT NULL,
    
    -- Standard timestamp fields
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for performance

-- User indexes
CREATE INDEX idx_users_wallet_address ON users(wallet_address);
CREATE INDEX idx_users_payment_address ON users(payment_address);

-- Auth nonce indexes
CREATE INDEX idx_auth_nonces_wallet_address ON auth_nonces(wallet_address);
CREATE INDEX idx_auth_nonces_expires_at ON auth_nonces(expires_at);

-- Refresh token indexes
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_expires_at ON refresh_tokens(expires_at);

-- Revoked token indexes
CREATE INDEX idx_revoked_tokens_expires_at ON revoked_tokens(expires_at);

-- Paid route indexes
CREATE UNIQUE INDEX idx_paid_routes_short_code ON paid_routes(short_code);
CREATE INDEX idx_paid_routes_user_id ON paid_routes(user_id);
CREATE INDEX idx_paid_routes_deleted_at ON paid_routes(deleted_at);

-- Purchase indexes
CREATE INDEX idx_purchases_short_code ON purchases(short_code);
CREATE INDEX idx_purchases_paid_route_id ON purchases(paid_route_id);
CREATE INDEX idx_purchases_created_at ON purchases(created_at);