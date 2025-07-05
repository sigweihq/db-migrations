-- name: CreateX402Transaction :exec
-- CreateX402Transaction creates a new x402 transaction record.
INSERT INTO x402_transactions (
    id, payment_requirements_json, payment_payload, payment_header, settle_response, typed_data
) VALUES (
    $1, $2, $3, $4, $5, $6
);

-- name: GetX402TransactionByID :one
-- GetX402TransactionByID returns an x402 transaction by ID.
SELECT * FROM x402_transactions
WHERE id = $1;

-- name: GetX402TransactionByPaymentHeader :one
-- GetX402TransactionByPaymentHeader returns an x402 transaction by payment header.
SELECT * FROM x402_transactions
WHERE payment_header = $1;

-- name: UpdateX402TransactionSettlement :exec
-- UpdateX402TransactionSettlement updates the settlement response for an x402 transaction.
UPDATE x402_transactions
SET settle_response = $2
WHERE id = $1;

-- name: GetX402TransactionWithTransaction :one
-- GetX402TransactionWithTransaction returns x402 transaction with base transaction data.
SELECT 
    x.id, x.payment_requirements_json, x.payment_payload, x.payment_header, x.settle_response, x.typed_data,
    t.signer_address, t.amount, t.network, t.chain_id, t.transaction_hash, t.status, t.error,
    t.created_at, t.updated_at
FROM x402_transactions x
JOIN transactions t ON x.id = t.id
WHERE x.id = $1;

-- name: ListSettledX402Transactions :many
-- ListSettledX402Transactions returns all x402 transactions that have been settled.
SELECT 
    x.id, x.payment_requirements_json, x.payment_payload, x.payment_header, x.settle_response, x.typed_data,
    t.signer_address, t.amount, t.network, t.chain_id, t.transaction_hash, t.status, t.error,
    t.created_at, t.updated_at
FROM x402_transactions x
JOIN transactions t ON x.id = t.id
WHERE x.settle_response IS NOT NULL
ORDER BY t.created_at DESC;

-- name: ListUnsettledX402Transactions :many
-- ListUnsettledX402Transactions returns all x402 transactions pending settlement.
SELECT 
    x.id, x.payment_requirements_json, x.payment_payload, x.payment_header, x.settle_response, x.typed_data,
    t.signer_address, t.amount, t.network, t.chain_id, t.transaction_hash, t.status, t.error,
    t.created_at, t.updated_at
FROM x402_transactions x
JOIN transactions t ON x.id = t.id
WHERE x.settle_response IS NULL AND t.status = 'PENDING'
ORDER BY t.created_at ASC;

-- name: GetX402TransactionsByNetwork :many
-- GetX402TransactionsByNetwork returns x402 transactions on a specific network.
SELECT 
    x.id, x.payment_requirements_json, x.payment_payload, x.payment_header, x.settle_response, x.typed_data,
    t.signer_address, t.amount, t.network, t.chain_id, t.transaction_hash, t.status, t.error,
    t.created_at, t.updated_at
FROM x402_transactions x
JOIN transactions t ON x.id = t.id
WHERE t.network = $1
ORDER BY t.created_at DESC;

-- name: GetTransactionHistory :many
-- GetTransactionHistory returns transaction history for a wallet address with optional filtering.
SELECT 
    t.created_at,
    t.updated_at,
    t.signer_address,
    t.network,
    t.amount,
    x.payment_requirements_json,
    x.payment_payload,
    x.typed_data,
    t.status,
    t.transaction_hash,
    t.error,
    CASE 
        WHEN p.id IS NOT NULL THEN 'purchase'
        ELSE 'transfer'
    END as type,
    p.short_code,
    pr.title,
    pr.description,
    pr.type as paygate_type,
    pr.credits as total_credits,
    p.credits_used,
    (pr.credits - COALESCE(p.credits_used, 0)) as remaining_credits
FROM x402_transactions x
JOIN transactions t ON x.id = t.id
LEFT JOIN purchases p ON x.id = p.id
LEFT JOIN paid_routes pr ON p.paid_route_id = pr.id
WHERE t.signer_address = $1
    AND ($2::text IS NULL OR t.network = $2)
ORDER BY t.created_at DESC
LIMIT $4 OFFSET $3;

-- name: GetTransactionHistoryCount :one
-- GetTransactionHistoryCount returns the total count of transactions for a wallet address with optional filtering.
SELECT COUNT(*)
FROM x402_transactions x
JOIN transactions t ON x.id = t.id
LEFT JOIN purchases p ON x.id = p.id
WHERE t.signer_address = $1
    AND ($2::text IS NULL OR t.network = $2);