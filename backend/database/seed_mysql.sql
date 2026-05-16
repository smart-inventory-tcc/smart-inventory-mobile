INSERT IGNORE INTO users (username, password, role, created_at) VALUES
('owner', '$2a$10$bN8I9FoJ7H5ubfBHtYfL6.IS63RoAXg5RcJkNcUy7l1LBuXE/djXu', 'Owner', '2026-05-10 08:00:00');

INSERT IGNORE INTO suppliers (name, phone, address, email) VALUES
('Ibu Sari Supplies', '+628123456789', 'Jl. Kenanga No. 5', 'sari@example.com'),
('CV Sumber Jaya', '+628987654321', 'Jl. Melati No. 12', 'sumberjaya@example.com');

INSERT IGNORE INTO categories (category_name, description) VALUES
('Minuman', 'Produk minuman untuk UMKM'),
('Makanan Ringan', 'Produk snack dan kudapan');

INSERT IGNORE INTO items (barcode, name, price, stock, min_stock, category_id, supplier_id, image_url) VALUES
('BCODE001', 'Air Mineral 600ml', 5000.00, 120, 20, 1, 1, ''),
('BCODE002', 'Keripik Singkong', 15000.00, 60, 15, 2, 2, '');

INSERT IGNORE INTO stock_transactions (item_id, user_id, type, quantity, created_at) VALUES
(1, 1, 'IN', 120, '2026-05-10 08:30:00'),
(2, 1, 'IN', 60, '2026-05-10 08:45:00');
