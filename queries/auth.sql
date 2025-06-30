-- Auth nonces queries

-- name: CreateAuthNonce :exec
INSERT INTO auth_nonces (
    nonce, wallet_address, timestamp, expires_at
) VALUES (
    $1, $2, $3, $4
);

-- name: GetAuthNonce :one
SELECT nonce, wallet_address, timestamp, expires_at, created_at
FROM auth_nonces
WHERE nonce = $1;

-- name: DeleteExpiredNonces :exec
DELETE FROM auth_nonces
WHERE expires_at < NOW();

-- name: DeleteAuthNonce :exec
DELETE FROM auth_nonces
WHERE nonce = $1;

-- Refresh tokens queries

-- name: CreateRefreshToken :one
INSERT INTO refresh_tokens (
    token_hash, user_id, expires_at, device_info
) VALUES (
    $1, $2, $3, $4
) RETURNING id;

-- name: GetRefreshToken :one
SELECT id, token_hash, user_id, expires_at, is_revoked, device_info, created_at
FROM refresh_tokens
WHERE token_hash = $1 AND is_revoked = false AND expires_at > NOW();

-- name: RevokeRefreshToken :exec
UPDATE refresh_tokens
SET is_revoked = true
WHERE token_hash = $1;

-- name: RevokeAllUserRefreshTokens :exec
UPDATE refresh_tokens
SET is_revoked = true
WHERE user_id = $1;

-- name: DeleteExpiredRefreshTokens :exec
DELETE FROM refresh_tokens
WHERE expires_at < NOW() OR is_revoked = true;

-- Revoked JWT tokens queries

-- name: CreateRevokedToken :exec
INSERT INTO revoked_tokens (
    jti, user_id, reason, expires_at
) VALUES (
    $1, $2, $3, $4
);

-- name: IsTokenRevoked :one
SELECT EXISTS(
    SELECT 1 FROM revoked_tokens
    WHERE jti = $1 AND expires_at > NOW()
);

-- name: DeleteExpiredRevokedTokens :exec
DELETE FROM revoked_tokens
WHERE expires_at < NOW();

