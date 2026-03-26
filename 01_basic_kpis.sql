-- ================================================================
-- E-Commerce SQL Analysis — 01 Basic KPIs
-- Author  : Mohani Gupta | mohanigupta279@gmail.com
-- ================================================================

-- ── 1. All-Time Business KPIs ─────────────────────────────────
SELECT
    COUNT(DISTINCT o.order_id)      AS total_orders,
    COUNT(DISTINCT o.customer_id)   AS total_customers,
    ROUND(SUM(o.order_value)::NUMERIC, 2)  AS total_revenue,
    ROUND(AVG(o.order_value)::NUMERIC, 2)  AS avg_order_value,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP
          (ORDER BY o.order_value)::NUMERIC, 2) AS median_order_value,
    MIN(o.order_date)::DATE  AS first_order_date,
    MAX(o.order_date)::DATE  AS latest_order_date
FROM orders o
WHERE order_status = 'Delivered';

-- ── 2. Revenue by Year & Month ───────────────────────────────
SELECT
    EXTRACT(YEAR  FROM order_date)::INT AS year,
    EXTRACT(MONTH FROM order_date)::INT AS month,
    TO_CHAR(order_date, 'Month')        AS month_name,
    COUNT(DISTINCT order_id)            AS orders,
    ROUND(SUM(order_value)::NUMERIC, 2) AS revenue
FROM orders
WHERE order_status = 'Delivered'
GROUP BY 1, 2, 3
ORDER BY 1, 2;

-- ── 3. Orders & Revenue by Status ────────────────────────────
SELECT
    order_status,
    COUNT(*)                            AS orders,
    ROUND(SUM(order_value)::NUMERIC, 2) AS order_value,
    ROUND(AVG(order_value)::NUMERIC, 2) AS avg_value
FROM orders
GROUP BY order_status
ORDER BY order_value DESC;

-- ── 4. Customer Acquisition Over Time ────────────────────────
SELECT
    TO_CHAR(signup_date, 'YYYY-MM') AS cohort_month,
    COUNT(*)                         AS new_customers
FROM customers
GROUP BY TO_CHAR(signup_date, 'YYYY-MM')
ORDER BY cohort_month;

-- ── 5. Top 10 Revenue Days ────────────────────────────────────
SELECT
    order_date::DATE              AS date,
    COUNT(DISTINCT order_id)       AS orders,
    ROUND(SUM(order_value)::NUMERIC, 2) AS daily_revenue
FROM orders
WHERE order_status = 'Delivered'
GROUP BY order_date::DATE
ORDER BY daily_revenue DESC
LIMIT 10;
