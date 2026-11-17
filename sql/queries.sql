-- ============================================================
-- E-Commerce Funnel Analysis — SQL
-- Data: 80,000 sessions (Nov–Dec campaign period)
-- Funnel: Home → Viewed Product → Add to Cart → Checkout → Purchase
-- ============================================================

-- 1. Overall funnel with stage-to-stage drop-off
SELECT COUNT(*) AS sessions,
       SUM(viewed_product) AS viewed,
       SUM(added_to_cart) AS carts,
       SUM(reached_checkout) AS checkouts,
       SUM(purchased) AS purchases,
       ROUND(100.0 * SUM(viewed_product) / COUNT(*), 1) AS view_pct,
       ROUND(100.0 * SUM(added_to_cart) / COUNT(*), 1) AS cart_pct,
       ROUND(100.0 * SUM(reached_checkout) / COUNT(*), 1) AS checkout_pct,
       ROUND(100.0 * SUM(purchased) / COUNT(*), 1) AS purchase_pct,
       ROUND(SUM(revenue), 0) AS revenue
FROM sessions;

-- 2. Stage-to-stage drop rates (where the funnel leaks)
SELECT
  ROUND(100.0 * (1 - CAST(SUM(viewed_product) AS REAL) / COUNT(*)), 1) AS home_to_view_drop,
  ROUND(100.0 * (1 - CAST(SUM(added_to_cart) AS REAL) / NULLIF(SUM(viewed_product),0)), 1) AS view_to_cart_drop,
  ROUND(100.0 * (1 - CAST(SUM(reached_checkout) AS REAL) / NULLIF(SUM(added_to_cart),0)), 1) AS cart_to_checkout_drop,
  ROUND(100.0 * (1 - CAST(SUM(purchased) AS REAL) / NULLIF(SUM(reached_checkout),0)), 1) AS checkout_to_purchase_drop
FROM sessions;

-- 3. Conversion by device
SELECT device,
       COUNT(*) AS sessions,
       SUM(purchased) AS purchases,
       ROUND(100.0 * SUM(purchased) / COUNT(*), 2) AS conv_pct,
       ROUND(AVG(CASE WHEN purchased = 1 THEN revenue END), 0) AS avg_order_value
FROM sessions
GROUP BY device
ORDER BY conv_pct DESC;

-- 4. Conversion by traffic source
SELECT traffic_source,
       COUNT(*) AS sessions,
       SUM(purchased) AS purchases,
       ROUND(100.0 * SUM(purchased) / COUNT(*), 2) AS conv_pct,
       ROUND(AVG(CASE WHEN purchased = 1 THEN revenue END), 0) AS avg_order_value
FROM sessions
GROUP BY traffic_source
ORDER BY conv_pct DESC;

-- 5. Source-level stage table (which source leaks at which stage)
SELECT traffic_source,
       SUM(viewed_product) AS viewed,
       SUM(added_to_cart) AS carts,
       SUM(reached_checkout) AS checkouts,
       SUM(purchased) AS purchases,
       ROUND(100.0 * (1 - CAST(SUM(reached_checkout) AS REAL) / NULLIF(SUM(added_to_cart),0)), 1) AS cart_to_checkout_drop
FROM sessions
GROUP BY traffic_source
ORDER BY purchases DESC;

-- 6. Cart-abandonment detail by device (checkout leakage)
SELECT device,
       SUM(added_to_cart) AS carts,
       SUM(reached_checkout) AS checkouts,
       SUM(purchased) AS purchases,
       ROUND(100.0 * (SUM(added_to_cart) - SUM(reached_checkout)) / SUM(added_to_cart), 1) AS cart_to_checkout_drop,
       ROUND(100.0 * (SUM(reached_checkout) - SUM(purchased)) / SUM(reached_checkout), 1) AS checkout_to_buy_drop
FROM sessions
WHERE added_to_cart = 1
GROUP BY device
ORDER BY cart_to_checkout_drop DESC;

-- 7. Revenue and revenue per session (efficiency, not just volume)
SELECT traffic_source,
       ROUND(SUM(revenue), 0) AS revenue,
       ROUND(SUM(revenue) * 1.0 / COUNT(*), 2) AS revenue_per_session
FROM sessions
GROUP BY traffic_source
ORDER BY revenue_per_session DESC;
