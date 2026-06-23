-- ============================================================
-- Project 6 — MySQL Test Queries
-- Run these inside the MySQL prompt after connecting from EC2
-- Connect: mysql -h YOUR_RDS_ENDPOINT -P 3306 -u admin -p
-- ============================================================

-- ── STEP 1: Verify Connection ────────────────────────────────
SELECT 'Connected to RDS MySQL successfully!' AS status;
SELECT @@hostname AS rds_hostname;
SELECT VERSION() AS mysql_version;
SELECT NOW() AS current_time;

-- ── STEP 2: Check Databases ──────────────────────────────────
SHOW DATABASES;
-- Expected: appdb, information_schema, mysql,
--           performance_schema, sys

-- ── STEP 3: Use Application Database ─────────────────────────
USE appdb;
SELECT DATABASE() AS current_database;

-- ── STEP 4: Create Users Table ───────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    email       VARCHAR(150) NOT NULL UNIQUE,
    role        VARCHAR(50)  NOT NULL DEFAULT 'user',
    created_at  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
                             ON UPDATE CURRENT_TIMESTAMP
);

-- ── STEP 5: Create Products Table ────────────────────────────
CREATE TABLE IF NOT EXISTS products (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(200) NOT NULL,
    description TEXT,
    price       DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    stock       INT          NOT NULL DEFAULT 0,
    created_at  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

-- ── STEP 6: Create Orders Table ──────────────────────────────
CREATE TABLE IF NOT EXISTS orders (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    user_id     INT NOT NULL,
    product_id  INT NOT NULL,
    quantity    INT NOT NULL DEFAULT 1,
    total_price DECIMAL(10,2),
    status      ENUM('pending','processing','shipped','delivered')
                DEFAULT 'pending',
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id)    REFERENCES users(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);

-- ── STEP 7: Insert Sample Users ──────────────────────────────
INSERT INTO users (name, email, role) VALUES
  ('Vinay Kumar',    'vinay@example.com',   'admin'),
  ('AWS Engineer',   'aws@example.com',     'developer'),
  ('Cloud Learner',  'cloud@example.com',   'user'),
  ('Solutions Arch', 'sa@example.com',      'developer'),
  ('DevOps Engineer','devops@example.com',  'user');

-- ── STEP 8: Insert Sample Products ───────────────────────────
INSERT INTO products (name, description, price, stock) VALUES
  ('AWS Course',    'Complete AWS Solutions Architect course', 199.99, 100),
  ('Cloud Book',    'AWS best practices handbook',             49.99,  50),
  ('Lab Credits',   'Cloud lab environment credits',           29.99,  999);

-- ── STEP 9: Insert Sample Orders ─────────────────────────────
INSERT INTO orders (user_id, product_id, quantity, total_price, status) VALUES
  (1, 1, 1, 199.99, 'delivered'),
  (2, 2, 2,  99.98, 'shipped'),
  (3, 3, 1,  29.99, 'processing');

-- ── STEP 10: Query All Tables ─────────────────────────────────
SELECT '=== USERS ===' AS '';
SELECT * FROM users;

SELECT '=== PRODUCTS ===' AS '';
SELECT * FROM products;

SELECT '=== ORDERS ===' AS '';
SELECT * FROM orders;

-- ── STEP 11: JOIN Query ───────────────────────────────────────
SELECT '=== ORDER DETAILS (JOIN) ===' AS '';
SELECT
    o.id          AS order_id,
    u.name        AS customer,
    p.name        AS product,
    o.quantity,
    o.total_price,
    o.status,
    o.created_at
FROM orders o
JOIN users    u ON o.user_id    = u.id
JOIN products p ON o.product_id = p.id
ORDER BY o.created_at DESC;

-- ── STEP 12: Aggregate Queries ────────────────────────────────
SELECT '=== STATS ===' AS '';

SELECT COUNT(*) AS total_users FROM users;
SELECT COUNT(*) AS total_orders FROM orders;
SELECT SUM(total_price) AS total_revenue FROM orders;
SELECT AVG(total_price) AS avg_order_value FROM orders;

-- Users by role
SELECT role, COUNT(*) AS count
FROM users
GROUP BY role
ORDER BY count DESC;

-- Orders by status
SELECT status, COUNT(*) AS count, SUM(total_price) AS revenue
FROM orders
GROUP BY status;

-- ── STEP 13: Server Info ──────────────────────────────────────
SELECT '=== SERVER INFO ===' AS '';
SELECT @@hostname;
SELECT @@port;
SHOW VARIABLES LIKE 'max_connections';
SHOW VARIABLES LIKE 'version';
SHOW STATUS LIKE 'Threads_connected';

-- ── STEP 14: Show Table Structure ────────────────────────────
SHOW TABLES;
DESCRIBE users;
DESCRIBE products;
DESCRIBE orders;

-- ── STEP 15: Cleanup (run when done with testing) ─────────────
-- DROP TABLE IF EXISTS orders;
-- DROP TABLE IF EXISTS products;
-- DROP TABLE IF EXISTS users;
-- (Commented out — run manually if needed)

-- ── EXIT ──────────────────────────────────────────────────────
-- Type EXIT; to leave MySQL prompt
SELECT 'All tests complete! Type EXIT; to disconnect.' AS message;