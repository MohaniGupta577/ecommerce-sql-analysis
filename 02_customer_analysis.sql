-- ================================================================
-- E-Commerce SQL Analysis — 02 Customer Analysis
-- Author  : Mohani Gupta | mohanigupta279@gmail.com
-- ================================================================

-- ── 1. Customer Lifetime Value (CLV) ─────────────────────────
WITH customer_stats AS (
    SELECT
        o.customer_id,
        c.first_name || ' ' || c.last_name              AS customer_name,
        c.city,
        COUNT(DISTINCT o.order_id)                        AS total_orders,
        ROUND(SUM(o.order_value)::NUMERIC, 2)             AS total_spent,
        ROUND(AVG(o.order_value)::NUMERIC, 2)             AS avg_order_value,
        MIN(o.order_date)::DATE                           AS first_purchase,
        MAX(o.order_date)::DATE                           AS last_purchase,
        (MAX(o.order_date) - MIN(o.order_date))::INT / 30 AS active_months
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'Delivered'
    GROUP BY o.customer_id, c.first_name, c.last_name, c.city
)
SELECT *,
    NTILE(4) OVER (ORDER BY total_spent DESC) AS value_quartile,
    CASE NTILE(4) OVER (ORDER BY total_spent DESC)
        WHEN 1 THEN '⭐ Platinum'
        WHEN 2 THEN '🥇 Gold'
        WHEN 3 THEN '🥈 Silver'
        ELSE        '🥉 Bronze'
    END AS customer_tier
FROM customer_stats
ORDER BY total_spent DESC;

-- ── 2. Repeat vs One-Time Buyers ─────────────────────────────
SELECT
    CASE WHEN order_count = 1 THEN 'One-Time'
         WHEN order_count BETWEEN 2 AND 4 THEN 'Occasional (2-4)'
         WHEN order_count BETWEEN 5 AND 9 THEN 'Regular (5-9)'
         ELSE 'Loyal (10+)'
    END AS buyer_segment,
    COUNT(*) AS customers,
    ROUND(AVG(total_spent)::NUMERIC, 2) AS avg_clv
FROM (
    SELECT customer_id,
           COUNT(DISTINCT order_id) AS order_count,
           SUM(order_value)         AS total_spent
    FROM orders WHERE order_status = 'Delivered'
    GROUP BY customer_id
) t
GROUP BY buyer_segment
ORDER BY avg_clv DESC;

-- ── 3. Customer City Distribution ────────────────────────────
SELECT
    c.city,
    COUNT(DISTINCT c.customer_id)        AS customers,
    COUNT(DISTINCT o.order_id)           AS orders,
    ROUND(SUM(o.order_value)::NUMERIC, 2) AS revenue
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
    AND o.order_status = 'Delivered'
GROUP BY c.city
ORDER BY revenue DESC
LIMIT 15;

-- ── 4. Days Since Last Purchase (Recency) ────────────────────
SELECT
    customer_id,
    MAX(order_date)::DATE              AS last_order_date,
    (CURRENT_DATE - MAX(order_date)::DATE) AS days_since_last_order,
    CASE
        WHEN (CURRENT_DATE - MAX(order_date)::DATE) <= 30  THEN 'Active   (0–30d)'
        WHEN (CURRENT_DATE - MAX(order_date)::DATE) <= 90  THEN 'Recent   (31–90d)'
        WHEN (CURRENT_DATE - MAX(order_date)::DATE) <= 180 THEN 'Lapsing  (91–180d)'
        ELSE 'Churned  (180d+)'
    END AS recency_segment
FROM orders
WHERE order_status = 'Delivered'
GROUP BY customer_id
ORDER BY days_since_last_order;
