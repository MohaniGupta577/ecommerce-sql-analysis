-- ================================================================
-- E-Commerce SQL Analysis — Advanced Queries
-- Author  : Mohani Gupta | mohanigupta279@gmail.com
-- Tools   : PostgreSQL 15+
-- Topics  : CTEs · Window Functions · RFM · Cohorts · Funnels
-- ================================================================

-- ── 1. BUSINESS OVERVIEW KPIs ────────────────────────────────
SELECT
    COUNT(DISTINCT order_id)     AS total_orders,
    COUNT(DISTINCT customer_id)  AS total_customers,
    ROUND(SUM(order_value), 2)   AS total_revenue,
    ROUND(AVG(order_value), 2)   AS avg_order_value,
    MIN(order_date)              AS first_order,
    MAX(order_date)              AS last_order
FROM orders
WHERE order_status = 'Delivered';

-- ── 2. CUSTOMER LIFETIME VALUE (CLV) with NTILE ──────────────
WITH customer_stats AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id)                    AS total_orders,
        ROUND(SUM(order_value)::NUMERIC, 2)         AS total_spent,
        MIN(order_date)                             AS first_order,
        MAX(order_date)                             AS last_order,
        (MAX(order_date) - MIN(order_date))         AS lifespan_days
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),
clv_ranked AS (
    SELECT *,
        ROUND(total_spent / NULLIF(total_orders, 0), 2) AS avg_order_val,
        NTILE(4) OVER (ORDER BY total_spent DESC)        AS value_quartile
    FROM customer_stats
)
SELECT
    value_quartile,
    COUNT(*)                           AS customers,
    ROUND(AVG(total_spent)::NUMERIC, 2)  AS avg_clv,
    ROUND(SUM(total_spent)::NUMERIC, 2)  AS segment_revenue,
    ROUND(AVG(total_orders)::NUMERIC, 1) AS avg_orders_per_customer
FROM clv_ranked
GROUP BY value_quartile
ORDER BY value_quartile;

-- ── 3. PRODUCT PERFORMANCE WITH RANK IN CATEGORY ─────────────
WITH product_metrics AS (
    SELECT
        p.product_name,
        p.category,
        SUM(oi.quantity)              AS units_sold,
        ROUND(SUM(oi.line_total)::NUMERIC, 2) AS revenue,
        ROUND(AVG(r.rating)::NUMERIC, 2)       AS avg_rating,
        COUNT(DISTINCT o.order_id)    AS order_count
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN orders   o ON oi.order_id   = o.order_id
    LEFT JOIN reviews r ON p.product_id = r.product_id
    WHERE o.order_status = 'Delivered'
    GROUP BY p.product_name, p.category
)
SELECT *,
    RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rank_in_category,
    ROUND(revenue * 100.0 / SUM(revenue) OVER (PARTITION BY category), 2) AS cat_revenue_share_pct
FROM product_metrics
ORDER BY category, rank_in_category
LIMIT 30;

-- ── 4. REVENUE TREND WITH ROLLING 3-MONTH AVERAGE ───────────
WITH monthly AS (
    SELECT
        TO_CHAR(order_date, 'YYYY-MM') AS month,
        ROUND(SUM(order_value)::NUMERIC, 2) AS revenue
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY TO_CHAR(order_date, 'YYYY-MM')
)
SELECT
    month,
    revenue,
    ROUND(AVG(revenue) OVER (
        ORDER BY month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    )::NUMERIC, 2) AS rolling_3mo_avg,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY month))::NUMERIC, 2) AS mom_delta,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month))
        / NULLIF(LAG(revenue) OVER (ORDER BY month), 0) * 100, 2
    ) AS mom_growth_pct
FROM monthly
ORDER BY month;

-- ── 5. CONVERSION FUNNEL ANALYSIS ────────────────────────────
SELECT
    COUNT(DISTINCT session_id)                                          AS sessions,
    COUNT(DISTINCT CASE WHEN event = 'product_view'   THEN session_id END) AS product_views,
    COUNT(DISTINCT CASE WHEN event = 'add_to_cart'    THEN session_id END) AS add_to_cart,
    COUNT(DISTINCT CASE WHEN event = 'checkout_start' THEN session_id END) AS checkout_start,
    COUNT(DISTINCT CASE WHEN event = 'purchase'       THEN session_id END) AS purchases,
    ROUND(
        COUNT(DISTINCT CASE WHEN event = 'add_to_cart' THEN session_id END) * 100.0
        / NULLIF(COUNT(DISTINCT CASE WHEN event = 'product_view' THEN session_id END), 0), 1
    ) AS view_to_cart_pct,
    ROUND(
        COUNT(DISTINCT CASE WHEN event = 'purchase' THEN session_id END) * 100.0
        / NULLIF(COUNT(DISTINCT session_id), 0), 1
    ) AS overall_conversion_pct
FROM user_events;

-- ── 6. COHORT RETENTION ANALYSIS ─────────────────────────────
WITH first_orders AS (
    SELECT customer_id,
           TO_CHAR(MIN(order_date), 'YYYY-MM') AS cohort_month
    FROM orders GROUP BY customer_id
),
cohort_activity AS (
    SELECT
        f.cohort_month,
        TO_CHAR(o.order_date, 'YYYY-MM') AS order_month,
        COUNT(DISTINCT o.customer_id)     AS active_customers
    FROM orders o
    JOIN first_orders f ON o.customer_id = f.customer_id
    GROUP BY f.cohort_month, TO_CHAR(o.order_date, 'YYYY-MM')
),
cohort_size AS (
    SELECT cohort_month, COUNT(DISTINCT customer_id) AS cohort_size
    FROM first_orders GROUP BY cohort_month
)
SELECT
    ca.cohort_month,
    ca.order_month,
    ca.active_customers,
    cs.cohort_size,
    ROUND(ca.active_customers * 100.0 / cs.cohort_size, 1) AS retention_pct
FROM cohort_activity ca
JOIN cohort_size cs ON ca.cohort_month = cs.cohort_month
ORDER BY ca.cohort_month, ca.order_month;

-- ── 7. RFM CUSTOMER SEGMENTATION ─────────────────────────────
WITH rfm_raw AS (
    SELECT
        customer_id,
        (CURRENT_DATE - MAX(order_date)::DATE)   AS recency_days,
        COUNT(DISTINCT order_id)                  AS frequency,
        ROUND(SUM(order_value)::NUMERIC, 2)       AS monetary
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency_days ASC)  AS r_score,
        NTILE(5) OVER (ORDER BY frequency DESC)     AS f_score,
        NTILE(5) OVER (ORDER BY monetary DESC)      AS m_score
    FROM rfm_raw
)
SELECT *,
    (r_score + f_score + m_score) AS rfm_total,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN '⭐ Champions'
        WHEN r_score >= 3 AND f_score >= 3                  THEN '💚 Loyal'
        WHEN r_score >= 4 AND f_score <= 2                  THEN '🆕 New Customers'
        WHEN r_score <= 2 AND f_score >= 3                  THEN '⚠️  At Risk'
        WHEN r_score = 1  AND f_score = 1                   THEN '❌ Lost'
        ELSE                                                     '🔵 Potential'
    END AS segment
FROM rfm_scores
ORDER BY rfm_total DESC;

-- ── 8. AVERAGE ORDER VALUE TREND ─────────────────────────────
SELECT
    TO_CHAR(order_date, 'YYYY-Q')    AS year_quarter,
    COUNT(DISTINCT order_id)          AS orders,
    ROUND(AVG(order_value)::NUMERIC, 2) AS avg_order_value,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP
          (ORDER BY order_value)::NUMERIC, 2) AS median_order_value
FROM orders
WHERE order_status = 'Delivered'
GROUP BY TO_CHAR(order_date, 'YYYY-Q')
ORDER BY year_quarter;
