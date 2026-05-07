PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS Users (
  user_id  INTEGER PRIMARY KEY AUTOINCREMENT,
  name     TEXT    NOT NULL,
  role     TEXT    NOT NULL CHECK(role IN ('Owner','Helper')),
  username TEXT    NOT NULL UNIQUE,
  email    TEXT    UNIQUE,
  phone    TEXT,
  password TEXT    NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_users_username ON Users(username);

CREATE TABLE IF NOT EXISTS Products (
  product_id     INTEGER PRIMARY KEY AUTOINCREMENT,
  name           TEXT    NOT NULL,
  category       TEXT,
  price          REAL    NOT NULL CHECK(price >= 0),
  stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK(stock_quantity >= 0),
  min_threshold  INTEGER NOT NULL DEFAULT 0,
  description    TEXT
);
CREATE INDEX IF NOT EXISTS idx_products_category ON Products(category);

CREATE TABLE IF NOT EXISTS Sales (
  sale_id      INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id      INTEGER NOT NULL REFERENCES Users(user_id),
  date_time    TEXT    NOT NULL DEFAULT (datetime('now')),
  total_amount REAL    NOT NULL CHECK(total_amount >= 0)
);
CREATE INDEX IF NOT EXISTS idx_sales_user_id   ON Sales(user_id);
CREATE INDEX IF NOT EXISTS idx_sales_date_time ON Sales(date_time);

CREATE TABLE IF NOT EXISTS SaleItems (
  item_id    INTEGER PRIMARY KEY AUTOINCREMENT,
  sale_id    INTEGER NOT NULL REFERENCES Sales(sale_id),
  product_id INTEGER NOT NULL REFERENCES Products(product_id),
  quantity   INTEGER NOT NULL CHECK(quantity > 0),
  subtotal   REAL    NOT NULL CHECK(subtotal >= 0)
);
CREATE INDEX IF NOT EXISTS idx_saleitems_sale_id    ON SaleItems(sale_id);
CREATE INDEX IF NOT EXISTS idx_saleitems_product_id ON SaleItems(product_id);


CREATE TABLE IF NOT EXISTS Payments (
  payment_id INTEGER PRIMARY KEY AUTOINCREMENT,
  sale_id    INTEGER NOT NULL UNIQUE REFERENCES Sales(sale_id),
  method     TEXT    NOT NULL CHECK(method IN ('Cash','GCash','QR')),
  status     TEXT    NOT NULL CHECK(status IN ('Success','Failed'))
);
CREATE INDEX IF NOT EXISTS idx_payments_sale_id ON Payments(sale_id);

CREATE TABLE IF NOT EXISTS InventoryLogs (
  log_id           INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id       INTEGER NOT NULL REFERENCES Products(product_id),
  change_type      TEXT    NOT NULL CHECK(change_type IN ('sale','restock','spoilage')),
  quantity_changed INTEGER NOT NULL,
  date_time        TEXT    NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_invlogs_product_id ON InventoryLogs(product_id);
CREATE INDEX IF NOT EXISTS idx_invlogs_date_time  ON InventoryLogs(date_time);

CREATE TABLE IF NOT EXISTS Expenses (
  expense_id      INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id         INTEGER NOT NULL REFERENCES Users(user_id),
  description     TEXT    NOT NULL,
  amount          REAL    NOT NULL CHECK(amount >= 0),
  due_date        TEXT,
  reminder_status TEXT    NOT NULL DEFAULT 'Pending'
                          CHECK(reminder_status IN ('Pending','Sent','Dismissed'))
);
CREATE INDEX IF NOT EXISTS idx_expenses_user_id  ON Expenses(user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_due_date ON Expenses(due_date);


-- Users
INSERT INTO Users (name, role, username, email, password) VALUES
  ('Maria Santos', 'Owner',  'maria_owner', 'maria@bytebite.com', 'hashed_pw_1'),
  ('Jose Reyes',   'Helper', 'jose_helper', 'jose@bytebite.com',  'hashed_pw_2');

-- Products
INSERT INTO Products (name, category, price, stock_quantity, min_threshold, description) VALUES
  ('Burger',      'Food',     120.00, 50, 10, 'Classic beef burger'),
  ('Fries',       'Food',      60.00, 80, 15, 'Crispy salted fries'),
  ('Iced Coffee', 'Beverage',  85.00, 40, 10, 'Cold brewed iced coffee');

-- Sale
INSERT INTO Sales (user_id, date_time, total_amount) VALUES
  (1, '2025-06-01 10:30:00', 265.00);

-- SaleItems  (1x Burger + 1x Fries + 1x Iced Coffee)
INSERT INTO SaleItems (sale_id, product_id, quantity, subtotal) VALUES
  (1, 1, 1, 120.00),
  (1, 2, 1,  60.00),
  (1, 3, 1,  85.00);

-- Payment
INSERT INTO Payments (sale_id, method, status) VALUES
  (1, 'GCash', 'Success');

-- InventoryLogs  (stock deducted after sale)
INSERT INTO InventoryLogs (product_id, change_type, quantity_changed, date_time) VALUES
  (1, 'sale', -1, '2025-06-01 10:30:00'),
  (2, 'sale', -1, '2025-06-01 10:30:00'),
  (3, 'sale', -1, '2025-06-01 10:30:00');

-- Expense
INSERT INTO Expenses (user_id, description, amount, due_date, reminder_status) VALUES
  (1, 'Monthly electricity bill', 3200.00, '2025-06-15', 'Pending');
