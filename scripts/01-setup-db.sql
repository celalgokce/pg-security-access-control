-- =====================================================
-- BLM4522 Proje 3: Veritabanı Kurulumu
-- Hassas veri içeren örnek HR/Finans veritabanı
-- =====================================================

-- pgcrypto extension'ını yükle
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- pgaudit extension'ını yükle
CREATE EXTENSION IF NOT EXISTS pgaudit;

-- =====================================================
-- Tablolar
-- =====================================================

-- Departmanlar
CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(50) NOT NULL,
    manager_id INTEGER
);

-- Çalışanlar (hassas veri: maaş, TC kimlik)
CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    dept_id INTEGER REFERENCES departments(dept_id),
    salary DECIMAL(10,2),
    tc_kimlik VARCHAR(11),          -- Hassas: şifrelenecek
    phone VARCHAR(20),
    hire_date DATE DEFAULT CURRENT_DATE,
    is_active BOOLEAN DEFAULT true
);

-- Kullanıcı hesapları (hassas veri: şifre)
CREATE TABLE user_accounts (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,      -- Hash'lenecek
    emp_id INTEGER REFERENCES employees(emp_id),
    role VARCHAR(20) DEFAULT 'user',
    last_login TIMESTAMP,
    is_locked BOOLEAN DEFAULT false
);

-- Finansal işlemler (hassas veri)
CREATE TABLE financial_transactions (
    txn_id SERIAL PRIMARY KEY,
    emp_id INTEGER REFERENCES employees(emp_id),
    txn_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(10,2) NOT NULL,
    txn_type VARCHAR(20),
    description TEXT,
    credit_card_enc BYTEA           -- Şifrelenmiş kredi kartı
);

-- Login denemeleri (audit için)
CREATE TABLE login_attempts (
    attempt_id SERIAL PRIMARY KEY,
    username VARCHAR(50),
    attempt_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    success BOOLEAN,
    failure_reason VARCHAR(100)
);

-- =====================================================
-- Örnek Veri
-- =====================================================

-- Departmanlar
INSERT INTO departments (dept_name) VALUES
('Bilgi Teknolojileri'),
('İnsan Kaynakları'),
('Finans'),
('Pazarlama'),
('Satış');

-- Çalışanlar
INSERT INTO employees (first_name, last_name, email, dept_id, salary, tc_kimlik, phone) VALUES
('Ahmet', 'Yılmaz', 'ahmet.yilmaz@sirket.com', 1, 35000.00, '12345678901', '05551001001'),
('Fatma', 'Kaya', 'fatma.kaya@sirket.com', 2, 32000.00, '23456789012', '05551001002'),
('Mehmet', 'Demir', 'mehmet.demir@sirket.com', 3, 40000.00, '34567890123', '05551001003'),
('Ayşe', 'Çelik', 'ayse.celik@sirket.com', 1, 28000.00, '45678901234', '05551001004'),
('Ali', 'Öztürk', 'ali.ozturk@sirket.com', 4, 30000.00, '56789012345', '05551001005'),
('Zeynep', 'Arslan', 'zeynep.arslan@sirket.com', 5, 27000.00, '67890123456', '05551001006'),
('Mustafa', 'Doğan', 'mustafa.dogan@sirket.com', 1, 45000.00, '78901234567', '05551001007'),
('Elif', 'Şahin', 'elif.sahin@sirket.com', 3, 38000.00, '89012345678', '05551001008'),
('Hasan', 'Yıldız', 'hasan.yildiz@sirket.com', 2, 29000.00, '90123456789', '05551001009'),
('Merve', 'Aydın', 'merve.aydin@sirket.com', 5, 26000.00, '01234567890', '05551001010');

-- Büyük veri seti
INSERT INTO employees (first_name, last_name, email, dept_id, salary, tc_kimlik, phone)
SELECT
    'Calisan_' || i,
    'Soyad_' || i,
    'calisan' || i || '@sirket.com',
    1 + (i % 5),
    (random() * 30000 + 20000)::decimal(10,2),
    LPAD((random() * 99999999999)::bigint::text, 11, '0'),
    '0555' || LPAD(i::text, 7, '0')
FROM generate_series(11, 200) AS i;

-- Finansal işlemler
INSERT INTO financial_transactions (emp_id, amount, txn_type, description)
SELECT
    1 + (i % 200),
    (random() * 5000 + 100)::decimal(10,2),
    (ARRAY['maas','prim','avans','harcama'])[1 + (i % 4)],
    'İşlem açıklaması ' || i
FROM generate_series(1, 1000) AS i;

-- Kayıt sayıları
SELECT 'departments' AS tablo, COUNT(*) AS kayit FROM departments
UNION ALL SELECT 'employees', COUNT(*) FROM employees
UNION ALL SELECT 'financial_transactions', COUNT(*) FROM financial_transactions;
