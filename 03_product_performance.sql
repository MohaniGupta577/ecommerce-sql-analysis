-- ================================================================
-- E-Commerce SQL Analysis — 03 Product Performance
-- Author  : Mohani Gupta | mohanigupta279@gmail.com
-- ================================================================

-- ── 1. Product Revenue & Margin ──────────────────────────────
SELECT
    p.product_name,
    p.category,
    p.sub_category,
    SUM(oi.quantity)                          AS units_sold,
    ROUND(SUM(oi.line_total)::NUMERIC, 2)     AS revenue,
    ROUND(AVG(oi.discount_pct)::NUMERIC, 2)   AS avg_discount_pct,
    ROUND(SUM(oi.line_total - p.cost_price * oi.quantity)
          ::NUMERIC, 2)                        AS gross_profit,
    ROUND(
        SUM(oi.line_total - p.cost_price * oi.quantity)
        / NULLIF(SUM(oi.line_total), 0) * 100, 2
    ) AS margin_pct
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders   o ON oi.order_id   = o.order_id
WHERE o.order_status = 'Delivered'
GROUP BY p.product_id, p.product_name, p.category, p.sub_category
ORDER BY revenue DESC
LIMIT 20;

-- ── 2. Category Performance Summary ──────────────────────────
SELECT
    category,
    COUNT(DISTINCT p.product_id)              AS products_in_category,
    SUM(oi.quantity)                          AS total_units_sold,
    ROUND(SUM(oi.line_total)::NUMERIC, 2)     AS total_revenue,
    ROUND(AVG(r.rating)::NUMERIC, 2)          AS avg_rating,
    ROUND(SUM(oi.line_total) * 100.0
          / SUM(SUM(oi.line_total)) OVER (), 2) AS revenue_share_pct
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders   o ON oi.order_id   = o.order_id
LEFT JOIN reviews r ON p.product_id = r.product_id
WHERE o.order_status = 'Delivered'
GROUP BY category
ORDER BY total_revenue DESC;

-- ── 3. Under-Performing Products (Low Revenue + Low Rating) ──
SELECT
    p.product_name,
    p.category,
    SUM(oi.quantity)                        AS units_sold,
    ROUND(SUM(oi.line_total)::NUMERIC, 2)   AS revenue,
    ROUND(AVG(r.rating)::NUMERIC, 2)        AS avg_rating
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders   o ON oi.order_id   = o.order_id
LEFT JOIN reviews r ON p.product_id = r.product_id
WHERE o.order_status = 'Delivered'
GROUP BY p.product_id, p.product_name, p.category
HAVING SUM(oi.line_total) < (
           SELECT AVG(cat_rev) FROM (
               SELECT SUM(oi2.line_total) AS cat_rev
               FROM order_items oi2
               JOIN orders o2 ON oi2.order_id = o2.order_id
               WHERE o2.order_status = 'Delivered'
               GROUP BY oi2.product_id
           ) sub
       )
   AND AVG(r.rating) < 3.0
ORDER BY revenue ASC;
