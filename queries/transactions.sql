-- name: CreateTransaction :one
-- CreateTransaction creates a new base transaction record.
INSERT INTO transactions (
    signer_address, amount, network, chain_id, transaction_hash, status, error, created_at, updated_at
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8, $9
) RETURNING id;

-- name: GetTransactionByID :one
-- GetTransactionByID returns a transaction by ID.
SELECT * FROM transactions
WHERE id = $1;

-- name: GetTransactionByHash :one
-- GetTransactionByHash returns a transaction by its blockchain hash.
SELECT * FROM transactions
WHERE transaction_hash = $1;

-- name: UpdateTransactionStatus :exec
-- UpdateTransactionStatus updates the status and error of a transaction.
UPDATE transactions 
SET status = $2, error = $3, updated_at = $4
WHERE id = $1;

-- name: ListTransactionsBySignerAddress :many
-- ListTransactionsBySignerAddress returns all transactions for a signer.
SELECT * FROM transactions
WHERE signer_address = $1
ORDER BY created_at DESC;

-- name: ListTransactionsByStatus :many
-- ListTransactionsByStatus returns all transactions with a specific status.
SELECT * FROM transactions
WHERE status = $1
ORDER BY created_at DESC;

-- name: ListTransactionsByNetwork :many
-- ListTransactionsByNetwork returns all transactions on a specific network.
SELECT * FROM transactions
WHERE network = $1
ORDER BY created_at DESC;

-- name: GetTransactionStats :one
-- GetTransactionStats returns overall transaction statistics.
SELECT 
    COUNT(*) as total_count,
    COALESCE(SUM(amount), 0) as total_amount,
    COUNT(CASE WHEN status = 'PENDING' THEN 1 END) as pending_count,
    COUNT(CASE WHEN status = 'CONFIRMED' THEN 1 END) as confirmed_count,
    COUNT(CASE WHEN status = 'FAILED' THEN 1 END) as failed_count,
    COUNT(CASE WHEN network = 'base-sepolia' THEN 1 END) as testnet_count,
    COUNT(CASE WHEN network = 'base' THEN 1 END) as mainnet_count
FROM transactions;

-- name: GetDailyTransactionStats :many
-- GetDailyTransactionStats returns daily transaction statistics.
SELECT 
    to_char(created_at AT TIME ZONE 'UTC', 'YYYY-MM-DD') AS date,
    COUNT(*) AS count,
    COALESCE(SUM(amount), 0) AS total_amount,
    COUNT(CASE WHEN network = 'base-sepolia' THEN 1 END) AS testnet_count,
    COALESCE(SUM(CASE WHEN network = 'base-sepolia' THEN amount ELSE 0 END), 0) AS testnet_amount,
    COUNT(CASE WHEN network = 'base' THEN 1 END) AS mainnet_count,
    COALESCE(SUM(CASE WHEN network = 'base' THEN amount ELSE 0 END), 0) AS mainnet_amount
FROM transactions
WHERE created_at >= CURRENT_TIMESTAMP - ($1 || ' days')::INTERVAL
GROUP BY date
ORDER BY date DESC;

-- name: ListPendingTransactions :many
-- ListPendingTransactions returns all pending transactions older than specified minutes.
SELECT * FROM transactions
WHERE status = 'PENDING' 
  AND created_at < NOW() - ($1 || ' minutes')::INTERVAL
ORDER BY created_at ASC;

-- name: GetTransactionsBySignerAndNetwork :many
-- GetTransactionsBySignerAndNetwork returns transactions for a signer on a specific network.
SELECT * FROM transactions
WHERE signer_address = $1 AND network = $2
ORDER BY created_at DESC;

-- name: UpdateTransactionHash :exec
-- UpdateTransactionHash updates the blockchain transaction hash.
UPDATE transactions
SET transaction_hash = $2, updated_at = $3
WHERE id = $1;