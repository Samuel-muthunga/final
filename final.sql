
-- E-COMMERCE STORE DATABASE SCHEMA (MySQL)
-- Filename: ecommerce_db.sql
-- Purpose: Full-featured relational database schema + sample data + helpful views & procedures
-- Notes: Designed for MySQL 8+. Adjust engine/charset as needed.

DROP DATABASE IF EXISTS ecommerce_store;
CREATE DATABASE ecommerce_store CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ecommerce_store;

-- -----------------------------------------------------
-- Table: users (customers and employees)
-- -----------------------------------------------------
CREATE TABLE users (
    user_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(30),
    is_employee BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Table: roles (for employees/admins)
-- -----------------------------------------------------
CREATE TABLE roles (
    role_id SMALLINT AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE user_roles (
    user_id BIGINT NOT NULL,
    role_id SMALLINT NOT NULL,
    assigned_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(role_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Table: addresses
-- -----------------------------------------------------
CREATE TABLE addresses (
    address_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    label VARCHAR(50), -- e.g., 'home', 'office'
    line1 VARCHAR(255) NOT NULL,
    line2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    region VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) NOT NULL,
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Table: categories (hierarchical)
-- -----------------------------------------------------
CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    parent_id INT DEFAULT NULL,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    FOREIGN KEY (parent_id) REFERENCES categories(category_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Table: products
-- -----------------------------------------------------
CREATE TABLE products (
    product_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    sku VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(12,2) NOT NULL CHECK (price >= 0),
    weight_kg DECIMAL(8,3) DEFAULT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Table: product_categories (many-to-many)
-- -----------------------------------------------------
CREATE TABLE product_categories (
    product_id BIGINT NOT NULL,
    category_id INT NOT NULL,
    PRIMARY KEY (product_id, category_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Table: product_images
-- -----------------------------------------------------
CREATE TABLE product_images (
    image_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT NOT NULL,
    url VARCHAR(1000) NOT NULL,
    alt_text VARCHAR(255),
    display_order INT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Table: inventory (stock)
-- -----------------------------------------------------
CREATE TABLE inventory (
    inventory_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT NOT NULL UNIQUE,
    quantity INT NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    reorder_level INT NOT NULL DEFAULT 0,
    last_restocked DATETIME,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Table: coupons
-- -----------------------------------------------------
CREATE TABLE coupons (
    coupon_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255),
    discount_type ENUM('percentage','fixed') NOT NULL,
    discount_amount DECIMAL(12,2) NOT NULL CHECK (discount_amount >= 0),
    max_uses INT DEFAULT NULL,
    used_count INT NOT NULL DEFAULT 0,
    valid_from DATE,
    valid_until DATE,
    active BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Table: carts (active shopping cart per user)
-- -----------------------------------------------------
CREATE TABLE carts (
    cart_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE (user_id)
) ENGINE=InnoDB;

CREATE TABLE cart_items (
    cart_item_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    cart_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    added_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cart_id) REFERENCES carts(cart_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT,
    UNIQUE (cart_id, product_id)
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Orders and order items
-- -----------------------------------------------------
CREATE TABLE orders (
    order_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    shipping_address_id BIGINT NOT NULL,
    billing_address_id BIGINT NOT NULL,
    order_status ENUM('pending','paid','processing','shipped','delivered','cancelled','refunded') NOT NULL DEFAULT 'pending',
    subtotal DECIMAL(12,2) NOT NULL CHECK (subtotal >= 0),
    shipping_fee DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (shipping_fee >= 0),
    tax DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (tax >= 0),
    discount DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (discount >= 0),
    total DECIMAL(12,2) NOT NULL CHECK (total >= 0),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE RESTRICT,
    FOREIGN KEY (shipping_address_id) REFERENCES addresses(address_id) ON DELETE RESTRICT,
    FOREIGN KEY (billing_address_id) REFERENCES addresses(address_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE order_items (
    order_item_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL CHECK (unit_price >= 0),
    quantity INT NOT NULL CHECK (quantity > 0),
    line_total DECIMAL(12,2) NOT NULL CHECK (line_total >= 0),
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Payments & transactions
-- -----------------------------------------------------
CREATE TABLE payments (
    payment_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    payment_method ENUM('mpesa','card','bank_transfer','wallet','cash_on_delivery') NOT NULL,
    amount DECIMAL(12,2) NOT NULL CHECK (amount >= 0),
    currency VARCHAR(10) NOT NULL DEFAULT 'KES',
    payment_status ENUM('pending','paid','failed','refunded') NOT NULL DEFAULT 'pending',
    provider_transaction_id VARCHAR(255),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Shipments
-- -----------------------------------------------------
CREATE TABLE shipments (
    shipment_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL UNIQUE,
    carrier VARCHAR(100),
    tracking_number VARCHAR(255) UNIQUE,
    shipped_at DATETIME,
    estimated_delivery DATE,
    delivered_at DATETIME,
    status ENUM('label_created','shipped','in_transit','out_for_delivery','delivered','exception') DEFAULT 'label_created',
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Reviews and ratings (customers leave reviews on products)
-- -----------------------------------------------------
CREATE TABLE reviews (
    review_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    rating TINYINT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(255),
    body TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (product_id, user_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Wishlist (many-to-many users to products)
-- -----------------------------------------------------
CREATE TABLE wishlists (
    wishlist_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL DEFAULT 'My wishlist',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE wishlist_items (
    wishlist_item_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    wishlist_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    added_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (wishlist_id) REFERENCES wishlists(wishlist_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    UNIQUE (wishlist_id, product_id)
) ENGINE=InnoDB;


-- -----------------------------------------------------
-- Audit log (simple)
-- -----------------------------------------------------
CREATE TABLE audit_log (
    audit_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    entity VARCHAR(100) NOT NULL,
    entity_id VARCHAR(100),
    action VARCHAR(50) NOT NULL,
    performed_by BIGINT,
    details JSON,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (performed_by) REFERENCES users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Helpful indexes
-- -----------------------------------------------------
CREATE INDEX idx_products_name ON products(name);
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_inventory_product ON inventory(product_id);

-- -----------------------------------------------------
-- Triggers: Maintain inventory consistency (simple example)
-- BEFORE inserting an order_item, ensure enough stock exists.
-- -----------------------------------------------------
DELIMITER $$
CREATE TRIGGER trg_check_inventory_before_insert_order_item
BEFORE INSERT ON order_items
FOR EACH ROW
BEGIN
    DECLARE avail INT;
    SELECT quantity INTO avail FROM inventory WHERE product_id = NEW.product_id FOR UPDATE;
    IF avail IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Inventory record not found for product';
    END IF;
    IF avail < NEW.quantity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient inventory for product';
    END IF;
END$$

CREATE TRIGGER trg_decrement_inventory_after_insert_order_item
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    UPDATE inventory SET quantity = quantity - NEW.quantity, last_restocked = last_restocked
    WHERE product_id = NEW.product_id;
END$$
DELIMITER ;

-- -----------------------------------------------------
-- Stored Procedure: Place an order (simplified example)
-- Assumptions: order items are provided in a temp table or application will insert order and order_items in a transaction.
-- This procedure shows an example of capturing an order, charging half upfront (business rule), and creating payment record.
-- -----------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_create_order_half_upfront (
    IN p_user_id BIGINT,
    IN p_shipping_address_id BIGINT,
    IN p_billing_address_id BIGINT,
    IN p_subtotal DECIMAL(12,2),
    IN p_shipping_fee DECIMAL(12,2),
    IN p_tax DECIMAL(12,2),
    IN p_discount DECIMAL(12,2),
    OUT o_order_id BIGINT
)
BEGIN
    DECLARE v_total DECIMAL(12,2);
    SET v_total = p_subtotal + p_shipping_fee + p_tax - p_discount;
    -- Create order with status 'pending'
    INSERT INTO orders (user_id, shipping_address_id, billing_address_id, subtotal, shipping_fee, tax, discount, total, order_status)
    VALUES (p_user_id, p_shipping_address_id, p_billing_address_id, p_subtotal, p_shipping_fee, p_tax, p_discount, v_total, 'pending');
    SET o_order_id = LAST_INSERT_ID();
    
    -- Create payment record representing half upfront hold
    INSERT INTO payments (order_id, payment_method, amount, currency, payment_status)
    VALUES (o_order_id, 'mpesa', ROUND(v_total/2,2), 'KES', 'pending');
    
    -- Log audit
    INSERT INTO audit_log (entity, entity_id, action, performed_by, details)
    VALUES ('order', o_order_id, 'created_pending_half_upfront', p_user_id, JSON_OBJECT('total', v_total));
END$$
DELIMITER ;

-- -----------------------------------------------------
-- Sample data (small set)
-- -----------------------------------------------------
INSERT INTO roles (role_name) VALUES ('admin'),('support'),('warehouse');
INSERT INTO users (email, password_hash, first_name, last_name, phone, is_employee)
VALUES
('alice@example.com','<hash>','Alice','Mwangi','+254700111222',FALSE),
('bob@example.com','<hash>','Bob','Otieno','+254700333444',TRUE),
('carol@example.com','<hash>','Carol','Kamau',NULL,FALSE);

INSERT INTO user_roles (user_id, role_id) VALUES (2,1);

INSERT INTO categories (name, description) VALUES
('Clothing','All clothing items'),
('Electronics','Gadgets and devices'),
('Home','Home and living');

INSERT INTO products (sku, name, description, price, weight_kg)
VALUES
('SKU-TSHIRT-001','Basic T-Shirt','Cotton t-shirt',499.00,0.2),
('SKU-MUG-001','Coffee Mug','Ceramic mug',299.00,0.4),
('SKU-PHONE-001','Budget Phone','Android smartphone',12999.00,0.18);

INSERT INTO product_categories (product_id, category_id) VALUES (1,1),(2,3),(3,2);

INSERT INTO inventory (product_id, quantity, reorder_level, last_restocked)
VALUES (1,100,10,NOW()),(2,40,5,NOW()),(3,15,2,NOW());

INSERT INTO users (email, password_hash, first_name, last_name, phone)
VALUES ('dave@example.com','<hash>','Dave','Njoroge','+254700555666');

INSERT INTO addresses (user_id, label, line1, city, region, postal_code, country, is_default)
VALUES (1,'home','1 Kibera Rd','Nairobi','Nairobi County','00100','Kenya',TRUE),
(3,'home','22 Riverside','Mombasa','Coast','80100','Kenya',TRUE);

-- -----------------------------------------------------
-- Views: summary views for common queries
-- -----------------------------------------------------
CREATE VIEW vw_product_stock AS
SELECT p.product_id, p.sku, p.name, COALESCE(i.quantity,0) AS qty, i.reorder_level
FROM products p LEFT JOIN inventory i USING(product_id);

CREATE VIEW vw_order_summary AS
SELECT o.order_id, o.user_id, CONCAT(u.first_name,' ',u.last_name) AS customer_name, o.total, o.order_status, o.created_at
FROM orders o JOIN users u ON o.user_id = u.user_id;

-- -----------------------------------------------------
-- Example queries (comments only)
-- -----------------------------------------------------
-- 1) Get products low on stock:
-- SELECT * FROM vw_product_stock WHERE qty <= reorder_level;
-- 2) Create an order via stored procedure (app would normally insert order_items afterwards):
-- CALL sp_create_order_half_upfront(1, 1, 1, 1498.00, 100.00, 50.00, 0.00, @out_order_id); SELECT @out_order_id;
-- 3) Transaction example (application side recommended):
-- START TRANSACTION;
-- INSERT INTO orders (...); INSERT INTO order_items (...); COMMIT;

-- End of SQL file
