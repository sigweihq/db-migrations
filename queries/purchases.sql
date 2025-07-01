-- name: CreatePurchase :exec
-- CreatePurchase creates a new purchase record in the three-tier hierarchy.
INSERT INTO purchases (
    id, short_code, target_url, method, type, credits_available, credits_used, paid_route_id, paid_to_address
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8, $9
);

-- name: GetPurchaseByID :one
-- GetPurchaseByID returns a complete purchase with transaction and x402 data.
SELECT 
    p.id, p.short_code, p.target_url, p.method, p.type, 
    p.credits_available, p.credits_used, p.paid_route_id, p.paid_to_address,
    t.signer_address, t.amount, t.network, t.chain_id, t.transaction_hash, t.status, t.error,
    t.created_at, t.updated_at,
    x.payment_requirements_json, x.payment_payload, x.payment_header, x.settle_response, x.typed_data
FROM purchases p
JOIN x402_transactions x ON p.id = x.id
JOIN transactions t ON x.id = t.id
WHERE p.id = $1;

-- name: ListPurchasesByUserID :many
-- ListPurchasesByUserID retrieves all purchases for a specific user via paid_routes.
SELECT 
    p.id, p.short_code, p.target_url, p.method, p.type, 
    p.credits_available, p.credits_used, p.paid_route_id, p.paid_to_address,
    t.signer_address, t.amount, t.network, t.chain_id, t.transaction_hash, t.status, t.error,
    t.created_at, t.updated_at,
    x.payment_requirements_json, x.payment_payload, x.payment_header, x.settle_response, x.typed_data
FROM purchases p
JOIN x402_transactions x ON p.id = x.id
JOIN transactions t ON x.id = t.id
JOIN paid_routes pr ON p.paid_route_id = pr.id
WHERE pr.user_id = $1
ORDER BY t.created_at DESC;

-- name: GetDailyStats :many
-- GetDailyStats retrieves daily purchase stats for a specific user.
SELECT 
    to_char(t.created_at AT TIME ZONE 'UTC', 'YYYY-MM-DD') AS date,
    COUNT(*) AS count,
    SUM(t.amount) AS earnings,
    COUNT(CASE WHEN t.network = 'base-sepolia' THEN 1 END) AS test_count,
    COALESCE(SUM(CASE WHEN t.network = 'base-sepolia' THEN t.amount ELSE 0 END), 0) AS test_earnings,
    COUNT(CASE WHEN t.network = 'base' THEN 1 END) AS real_count,
    COALESCE(SUM(CASE WHEN t.network = 'base' THEN t.amount ELSE 0 END), 0) AS real_earnings
FROM 
    purchases p
JOIN x402_transactions x ON p.id = x.id
JOIN transactions t ON x.id = t.id
JOIN paid_routes pr ON p.paid_route_id = pr.id
WHERE 
    pr.user_id = $1
    AND t.created_at >= CURRENT_TIMESTAMP - ($2 || ' days')::INTERVAL
GROUP BY 
    date
ORDER BY 
    date DESC;

-- name: GetTotalStats :one
-- GetTotalStats retrieves total purchase stats for a specific user.
SELECT 
    COALESCE(SUM(t.amount), 0) AS total_earnings,
    COUNT(*) AS total_count
FROM 
    purchases p
JOIN x402_transactions x ON p.id = x.id
JOIN transactions t ON x.id = t.id
JOIN paid_routes pr ON p.paid_route_id = pr.id
WHERE 
    pr.user_id = $1;

-- name: GetPurchaseByRouteIDAndPaymentHeader :one
-- GetPurchaseByRouteIDAndPaymentHeader finds a purchase by route ID and payment header.
SELECT 
    p.id, p.short_code, p.target_url, p.method, p.type, 
    p.credits_available, p.credits_used, p.paid_route_id, p.paid_to_address,
    t.signer_address, t.amount, t.network, t.chain_id, t.transaction_hash, t.status, t.error,
    t.created_at, t.updated_at,
    x.payment_requirements_json, x.payment_payload, x.payment_header, x.settle_response, x.typed_data
FROM purchases p
JOIN x402_transactions x ON p.id = x.id
JOIN transactions t ON x.id = t.id
WHERE p.paid_route_id = $1 AND x.payment_header = $2
ORDER BY t.created_at DESC LIMIT 1;

-- name: IncrementPurchaseCreditsUsed :exec
-- IncrementPurchaseCreditsUsed increments credits used and updates transaction timestamp.
UPDATE purchases p
SET credits_used = credits_used + 1
FROM transactions t
WHERE p.id = t.id AND p.id = $1 AND p.credits_used < p.credits_available;

UPDATE transactions
SET updated_at = $2
WHERE id = $1;

-- name: GetPurchasesByShortCode :many
-- GetPurchasesByShortCode returns all purchases for a specific route short code.
SELECT 
    p.id, p.short_code, p.target_url, p.method, p.type, 
    p.credits_available, p.credits_used, p.paid_route_id, p.paid_to_address,
    t.signer_address, t.amount, t.network, t.chain_id, t.transaction_hash, t.status, t.error,
    t.created_at, t.updated_at,
    x.payment_requirements_json, x.payment_payload, x.payment_header, x.settle_response, x.typed_data
FROM purchases p
JOIN x402_transactions x ON p.id = x.id
JOIN transactions t ON x.id = t.id
WHERE p.short_code = $1
ORDER BY t.created_at DESC;

-- name: GetPurchasesByStatus :many
-- GetPurchasesByStatus returns purchases with a specific transaction status.
SELECT 
    p.id, p.short_code, p.target_url, p.method, p.type, 
    p.credits_available, p.credits_used, p.paid_route_id, p.paid_to_address,
    t.signer_address, t.amount, t.network, t.chain_id, t.transaction_hash, t.status, t.error,
    t.created_at, t.updated_at,
    x.payment_requirements_json, x.payment_payload, x.payment_header, x.settle_response, x.typed_data
FROM purchases p
JOIN x402_transactions x ON p.id = x.id
JOIN transactions t ON x.id = t.id
WHERE t.status = $1
ORDER BY t.created_at DESC;

-- name: GetPurchasesWithCreditsRemaining :many
-- GetPurchasesWithCreditsRemaining returns purchases that still have unused credits.
SELECT 
    p.id, p.short_code, p.target_url, p.method, p.type, 
    p.credits_available, p.credits_used, p.paid_route_id, p.paid_to_address,
    t.signer_address, t.amount, t.network, t.chain_id, t.transaction_hash, t.status, t.error,
    t.created_at, t.updated_at,
    x.payment_requirements_json, x.payment_payload, x.payment_header, x.settle_response, x.typed_data
FROM purchases p
JOIN x402_transactions x ON p.id = x.id
JOIN transactions t ON x.id = t.id
WHERE p.credits_used < p.credits_available AND t.status = 'CONFIRMED'
ORDER BY t.created_at DESC;

-- name: GetUserPurchaseStats :one
-- GetUserPurchaseStats returns purchase statistics for a specific user.
SELECT 
    COUNT(*) as total_purchases,
    COALESCE(SUM(t.amount), 0) as total_spent,
    COUNT(CASE WHEN t.status = 'CONFIRMED' THEN 1 END) as confirmed_purchases,
    COUNT(CASE WHEN t.status = 'PENDING' THEN 1 END) as pending_purchases,
    COUNT(CASE WHEN t.status = 'FAILED' THEN 1 END) as failed_purchases,
    COALESCE(SUM(p.credits_available), 0) as total_credits_purchased,
    COALESCE(SUM(p.credits_used), 0) as total_credits_used
FROM purchases p
JOIN x402_transactions x ON p.id = x.id
JOIN transactions t ON x.id = t.id
JOIN paid_routes pr ON p.paid_route_id = pr.id
WHERE pr.user_id = $1;

-- name: GetPurchasesByNetworkAndUser :many
-- GetPurchasesByNetworkAndUser returns purchases for a user on a specific network.
SELECT 
    p.id, p.short_code, p.target_url, p.method, p.type, 
    p.credits_available, p.credits_used, p.paid_route_id, p.paid_to_address,
    t.signer_address, t.amount, t.network, t.chain_id, t.transaction_hash, t.status, t.error,
    t.created_at, t.updated_at,
    x.payment_requirements_json, x.payment_payload, x.payment_header, x.settle_response, x.typed_data
FROM purchases p
JOIN x402_transactions x ON p.id = x.id
JOIN transactions t ON x.id = t.id
JOIN paid_routes pr ON p.paid_route_id = pr.id
WHERE pr.user_id = $1 AND t.network = $2
ORDER BY t.created_at DESC; 