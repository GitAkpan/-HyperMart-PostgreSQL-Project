
-- P1 Product Revenue Report

SELECT
    p.product_name,
    d.dept_name,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_revenue
FROM products p
JOIN departments d ON p.dept_id = d.dept_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, d.dept_name
ORDER BY total_revenue DESC;



-- P2 City-Level Customer & Order Summary
SELECT
  c.city,
  COUNT(DISTINCT c.customer_id) AS num_customers,
  COUNT(DISTINCT o.order_id)  AS completed_orders,
  ROUND(AVG(oi.quantity * oi.unit_price), 2) AS avg_order_value
FROM customers c
LEFT JOIN orders o
  ON c.customer_id = o.customer_id AND o.status = 'completed'
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.city
HAVING COUNT(DISTINCT c.customer_id) >= 2
ORDER BY completed_orders DESC;


-- P3 Department Revenue Share
SELECT
  d.dept_name,
  SUM(oi.quantity * oi.unit_price) AS dept_revenue,
  ROUND(100.0 * SUM(oi.quantity * oi.unit_price)/ SUM(SUM(oi.quantity * oi.unit_price)) OVER (), 1
  )                AS pct_of_total
FROM departments d
JOIN products p ON d.dept_id = p.dept_id
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY d.dept_id, d.dept_name
ORDER BY dept_revenue DESC;

-- P4 Above-Average Spending Customers (CTE)
WITH customer_spend AS (
  SELECT
    c.customer_id,
    c.full_name,
    c.city,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_spend
  FROM customers c
  LEFT JOIN orders o
    ON c.customer_id = o.customer_id AND o.status = 'completed'
  LEFT JOIN order_items oi ON o.order_id = oi.order_id
  GROUP BY c.customer_id, c.full_name, c.city
)
SELECT full_name, city, total_spend
FROM customer_spend
WHERE total_spend > (SELECT AVG(total_spend) FROM customer_spend)
ORDER BY total_spend DESC;


-- P5	Cancelled Order Impact

-- Business need: Finance & Operations: how much revenue was lost to cancelled orders?
-- Show by department and month.

SELECT
  d.dept_name,
  DATE_TRUNC('month', o.order_date)::DATE  AS month,
  COUNT(DISTINCT o.order_id) AS cancelled_orders,
  SUM(oi.quantity * oi.unit_price) AS lost_revenue
FROM orders o
JOIN order_items oi ON o.order_id   = oi.order_id
JOIN products p     ON oi.product_id = p.product_id
JOIN departments d  ON p.dept_id     = d.dept_id
WHERE o.status = 'cancelled'
GROUP BY d.dept_name, DATE_TRUNC('month', o.order_date)
ORDER BY month, lost_revenue DESC;

-- P6 Top Product Per Department (Chained CTEs)
WITH dept_product_qty AS (
  SELECT
    d.dept_id, d.dept_name,
    p.product_name,
    SUM(oi.quantity) AS total_qty
  FROM departments d
  JOIN products p ON d.dept_id = p.dept_id
  JOIN order_items oi ON p.product_id = oi.product_id
  GROUP BY d.dept_id, d.dept_name, p.product_id, p.product_name
),
dept_max AS (
  SELECT dept_id, MAX(total_qty) AS max_qty
  FROM dept_product_qty
  GROUP BY dept_id
)
SELECT dpq.dept_name, dpq.product_name, dpq.total_qty
FROM dept_product_qty dpq


-- P7 Products Priced Above Department Average (Correlated Subquery)

SELECT p.product_name, p.category, p.unit_price, d.dept_name
FROM products p
JOIN departments d ON p.dept_id = d.dept_id
WHERE p.unit_price > (
  SELECT AVG(p2.unit_price)
  FROM products p2
  WHERE p2.dept_id = p.dept_id
)
ORDER BY d.dept_name, p.unit_price DESC;

-- P8	Top Product Per Department	CTEs
-- Business need: Procurement:which product sold the highest total quantity in each department?
-- No window functions allowed.

WITH dept_product_qty AS (
  SELECT
    d.dept_id,
    d.dept_name,
    p.product_id,
    p.product_name,
    SUM(oi.quantity) AS total_qty
  FROM departments d
  JOIN products p     ON d.dept_id    = p.dept_id
  JOIN order_items oi ON p.product_id = oi.product_id
  GROUP BY d.dept_id, d.dept_name, p.product_id, p.product_name
),
dept_max AS (
  SELECT dept_id, MAX(total_qty) AS max_qty
  FROM dept_product_qty
  GROUP BY dept_id
)
SELECT dpq.dept_name, dpq.product_name, dpq.total_qty
FROM dept_product_qty dpq
JOIN dept_max dm
  ON dpq.dept_id = dm.dept_id
  AND dpq.total_qty = dm.max_qty
ORDER BY dpq.dept_name;

-- P9 Customer Spend Function

CREATE OR REPLACE FUNCTION get_customer_total(p_customer_id INT)
RETURNS NUMERIC AS $$
DECLARE
  v_total NUMERIC := 0;
BEGIN
  SELECT COALESCE(SUM(oi.quantity * oi.unit_price), 0)
  INTO v_total
  FROM orders o
  JOIN order_items oi ON o.order_id = oi.order_id
  WHERE o.customer_id = p_customer_id
    AND o.status = 'completed';
 
  RETURN v_total;
END;
$$ LANGUAGE plpgsql;
 
-- Usage example:
SELECT full_name, get_customer_total(customer_id) AS total_spent
FROM customers
ORDER BY total_spent DESC;


-- P10 Restock Product Procedure
CREATE OR REPLACE PROCEDURE restock_product(p_product_id INT, p_qty INT)
LANGUAGE plpgsql AS $$
BEGIN
  IF p_qty < 1 THEN
    RAISE EXCEPTION
      'Restock quantity must be at least 1, got %', p_qty;
  END IF;
 
  UPDATE products
  SET stock_qty = stock_qty + p_qty
  WHERE product_id = p_product_id;
 
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Product ID % not found', p_product_id;
  END IF;
 
  RAISE NOTICE
    'Product % restocked by % units', p_product_id, p_qty;
END;
$$;
 
-- Usage example:
CALL restock_product(3, 100);
SELECT product_name, stock_qty FROM products WHERE product_id = 4;


-- P11	Month-over-Month Revenue Growth

-- Business need:compare each month's revenue to the previous month
-- and show the percentage change to track growth momentum.


WITH monthly_rev AS (
  SELECT
    DATE_TRUNC('month', o.order_date)::DATE AS month,
    SUM(oi.quantity * oi.unit_price) AS revenue
  FROM orders o
  JOIN order_items oi ON o.order_id = oi.order_id
  WHERE o.status = 'completed'
  GROUP BY DATE_TRUNC('month', o.order_date)
)
SELECT
  TO_CHAR(month, 'Mon YYYY') AS month,
  revenue,
  LAG(revenue) OVER (ORDER BY month) AS prev_month_rev,
  ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
    / NULLIF(LAG(revenue) OVER (ORDER BY month), 0),
  1) AS growth_pct
FROM monthly_rev
ORDER BY month;


-- P12	Repeat Buyers

-- Business need:identify customers who placed 2 or more completed orders 
-- the core retention metric.

WITH order_counts AS (
  SELECT
    c.customer_id,
    c.full_name,
    c.city,
    COUNT(DISTINCT o.order_id) AS completed_orders
  FROM customers c
  JOIN orders o
    ON c.customer_id = o.customer_id
    AND o.status = 'completed'
  GROUP BY c.customer_id, c.full_name, c.city
)
SELECT full_name, city, completed_orders
FROM order_counts
WHERE completed_orders >= 2
ORDER BY completed_orders DESC;



-- P13 Top 3 Products Per Department

-- Business need:display the three best-selling products
-- in each department for the monthly promotions newsletter.
WITH product_rev AS (
  SELECT
    d.dept_id, d.dept_name,
    p.product_name,
    SUM(oi.quantity * oi.unit_price) AS revenue
  FROM departments d
  JOIN products p     ON d.dept_id    = p.dept_id
  JOIN order_items oi ON p.product_id = oi.product_id
  GROUP BY d.dept_id, d.dept_name, p.product_id, p.product_name
),
ranked AS (
  SELECT *,
    ROW_NUMBER() OVER (
      PARTITION BY dept_id
      ORDER BY revenue DESC
    ) AS rn
  FROM product_rev
)
SELECT dept_name, product_name, revenue, rn AS rank
FROM ranked
WHERE rn <= 3
ORDER BY dept_name, rn;


-- P14	Customer Spend Function

-- Business need:the customer profile screen calls get_customer_total(id)
-- to display lifetime spend in real time without embedding query logic in the application.


CREATE OR REPLACE FUNCTION get_customer_total(
  p_customer_id INT
) RETURNS NUMERIC AS $$
DECLARE
  v_total NUMERIC := 0;
BEGIN
  SELECT COALESCE(SUM(oi.quantity * oi.unit_price), 0)
  INTO v_total
  FROM orders o
  JOIN order_items oi ON o.order_id = oi.order_id
  WHERE o.customer_id = p_customer_id
    AND o.status = 'completed';
  RETURN v_total;
END;
$$ LANGUAGE plpgsql;
 
-- Usage:
SELECT full_name, get_customer_total(customer_id) AS total_spent
FROM customers ORDER BY total_spent DESC;



-- P15 Restock Product Procedure

-- Business need: Warehouse operations:staff run a morning restock job.
-- The procedure replaces manual UPDATE statements, validates input, and prints a confirmation notice.

CREATE OR REPLACE PROCEDURE restock_product(
  p_product_id INT,
  p_qty        INT
) LANGUAGE plpgsql AS $$
BEGIN
  IF p_qty < 1 THEN
    RAISE EXCEPTION
      'Quantity must be >= 1, got %', p_qty;
  END IF;
 
  UPDATE products
  SET stock_qty = stock_qty + p_qty
  WHERE product_id = p_product_id;
 
  IF NOT FOUND THEN
    RAISE EXCEPTION
      'Product ID % does not exist', p_product_id;
  END IF;
 
  RAISE NOTICE 'Product % restocked: +% units',
    p_product_id, p_qty;
END;
$$;
 
-- Usage:
CALL restock_product(3, 100);




-- P16	Bulk Status Update Procedure

-- Business need:each night, mark all orders that have been in
-- 'pending' status for more than 7 days as 'cancelled'. Log the count of affected rows.

CREATE OR REPLACE PROCEDURE cancel_stale_orders()
LANGUAGE plpgsql AS $$
DECLARE
  v_count INT;
BEGIN
  UPDATE orders
  SET    status = 'cancelled'
  WHERE  status = 'pending'
    AND  order_date < CURRENT_DATE - INTERVAL '7 days';
 
  GET DIAGNOSTICS v_count = ROW_COUNT;
 
  RAISE NOTICE
    '% pending orders cancelled (older than 7 days).',
    v_count;
END;
$$;
 
-- Usage (run nightly via pg_cron or cron job):
CALL cancel_stale_orders();
