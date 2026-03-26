-- ================================================================
-- E-Commerce SQL Analysis — Database Schema
-- Author  : Mohani Gupta | mohanigupta279@gmail.com
-- Tool    : PostgreSQL 15+
-- ================================================================

-- ── Create & connect to database ─────────────────────────────
-- Run: createdb ecommerce_db
-- Then: psql -U postgres -d ecommerce_db -f schema/create_tables.sql

-- ── Customers ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS customers (
    customer_id   SERIAL        PRIMARY KEY,
    first_name    VARCHAR(80)   NOT NULL,
    last_name     VARCHAR(80)   NOT NULL,
    email         VARCHAR(200)  UNIQUE NOT NULL,
    city          VARCHAR(80),
    country       VARCHAR(80)   DEFAULT 'India',
    signup_date   DATE          NOT NULL,
    is_active     BOOLEAN       DEFAULT TRUE
);

-- ── Products ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS products (
    product_id    SERIAL        PRIMARY KEY,
    product_name  VARCHAR(200)  NOT NULL,
    category      VARCHAR(80)   NOT NULL,
    sub_category  VARCHAR(80),
    unit_price    NUMERIC(10,2) NOT NULL,
    cost_price    NUMERIC(10,2) NOT NULL,
    brand         VARCHAR(100),
    is_active     BOOLEAN DEFAULT TRUE
);

-- ── Orders ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS orders (
    order_id      SERIAL        PRIMARY KEY,
    customer_id   INT           NOT NULL REFERENCES customers(customer_id),
    order_date    TIMESTAMPTZ   NOT NULL,
    order_value   NUMERIC(12,2) NOT NULL,
    order_status  VARCHAR(30)   DEFAULT 'Delivered',
    ship_mode     VARCHAR(50),
    CONSTRAINT chk_status CHECK (
        order_status IN ('Delivered','Cancelled','Returned','Processing')
    )
);

-- ── Order Items ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS order_items (
    item_id      SERIAL        PRIMARY KEY,
    order_id     INT           NOT NULL REFERENCES orders(order_id),
    product_id   INT           NOT NULL REFERENCES products(product_id),
    quantity     INT           NOT NULL DEFAULT 1,
    unit_price   NUMERIC(10,2) NOT NULL,
    discount_pct NUMERIC(5,2)  DEFAULT 0,
    line_total   NUMERIC(12,2) GENERATED ALWAYS AS
                 (quantity * unit_price * (1 - discount_pct / 100)) STORED
);

-- ── Reviews ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS reviews (
    review_id    SERIAL  PRIMARY KEY,
    product_id   INT     NOT NULL REFERENCES products(product_id),
    customer_id  INT     NOT NULL REFERENCES customers(customer_id),
    rating       NUMERIC(3,2) CHECK (rating BETWEEN 1 AND 5),
    review_date  DATE    NOT NULL
);

-- ── User Events (Funnel) ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_events (
    event_id     BIGSERIAL   PRIMARY KEY,
    session_id   VARCHAR(50) NOT NULL,
    customer_id  INT         REFERENCES customers(customer_id),
    event        VARCHAR(50) NOT NULL,
    event_time   TIMESTAMPTZ NOT NULL,
    product_id   INT         REFERENCES products(product_id)
);

-- ── Indexes ───────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_orders_date       ON orders(order_date);
CREATE INDEX IF NOT EXISTS idx_orders_customer   ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_items_order       ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_items_product     ON order_items(product_id);
CREATE INDEX IF NOT EXISTS idx_events_session    ON user_events(session_id);
CREATE INDEX IF NOT EXISTS idx_events_type       ON user_events(event);

-- ── Verify ────────────────────────────────────────────────────
SELECT tablename, tableowner
FROM pg_catalog.pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
