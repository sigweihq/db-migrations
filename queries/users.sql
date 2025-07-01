-- name: GetUserByID :one
-- GetUserByID returns a user by ID.
SELECT id, wallet_address, payment_address, created_at, updated_at
FROM users
WHERE id = $1;

-- name: GetUserByWalletAddress :one
-- GetUserByWalletAddress returns a user by wallet address.
SELECT id, wallet_address, payment_address, created_at, updated_at
FROM users
WHERE wallet_address = $1;

-- name: CreateUserByWallet :one
-- CreateUserByWallet creates a new user record with wallet address.
INSERT INTO users (
    wallet_address, created_at, updated_at
) VALUES (
    $1, $2, $3
) RETURNING id;


-- name: UpdateUserPaymentAddress :one
-- UpdateUserPaymentAddress updates a user's payment address.
UPDATE users SET
    payment_address = $2,
    updated_at = $3
WHERE id = $1
RETURNING id, wallet_address, payment_address, created_at, updated_at;