-- =====================================================
-- BLM4522 Proje 3: Kullanıcı ve Rol Yönetimi
-- =====================================================

-- =====================================================
-- 1. ROL OLUŞTURMA
-- =====================================================

-- Admin rolü: Tam yetki
CREATE ROLE db_admin WITH LOGIN PASSWORD 'admin_secure_2024!';

-- Developer rolü: Okuma + yazma (sınırlı)
CREATE ROLE db_developer WITH LOGIN PASSWORD 'dev_secure_2024!';

-- Analyst rolü: Sadece okuma
CREATE ROLE db_analyst WITH LOGIN PASSWORD 'analyst_secure_2024!';

-- HR rolü: Sadece çalışan verilerine erişim
CREATE ROLE db_hr WITH LOGIN PASSWORD 'hr_secure_2024!';

-- Readonly rolü: Genel okuma
CREATE ROLE db_readonly WITH LOGIN PASSWORD 'readonly_2024!';

-- Grup rolleri (login yok, sadece yetki grubu)
CREATE ROLE read_only_group NOLOGIN;
CREATE ROLE read_write_group NOLOGIN;
CREATE ROLE admin_group NOLOGIN;

-- =====================================================
-- 2. YETKI ATAMA (GRANT)
-- =====================================================

-- Veritabanı bağlantı yetkisi
GRANT CONNECT ON DATABASE securitydb TO db_admin, db_developer, db_analyst, db_hr, db_readonly;

-- Schema yetkisi
GRANT USAGE ON SCHEMA public TO db_admin, db_developer, db_analyst, db_hr, db_readonly;

-- === Admin: Tam yetki ===
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO db_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO db_admin;
GRANT admin_group TO db_admin;

-- === Developer: Okuma + yazma (hassas veriler hariç) ===
GRANT SELECT, INSERT, UPDATE ON employees TO db_developer;
GRANT SELECT, INSERT, UPDATE ON departments TO db_developer;
GRANT SELECT ON financial_transactions TO db_developer;
-- Developer maaş ve TC kimlik göremez (view üzerinden)
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO db_developer;
GRANT read_write_group TO db_developer;

-- === Analyst: Sadece okuma ===
GRANT SELECT ON ALL TABLES IN SCHEMA public TO db_analyst;
GRANT read_only_group TO db_analyst;

-- === HR: Çalışan verileri (finans hariç) ===
GRANT SELECT, INSERT, UPDATE ON employees TO db_hr;
GRANT SELECT ON departments TO db_hr;
GRANT USAGE ON SEQUENCE employees_emp_id_seq TO db_hr;
-- HR finansal işlemleri göremez

-- === Readonly: Genel okuma ===
GRANT SELECT ON departments, employees TO db_readonly;
-- Readonly hassas tabloları göremez

-- =====================================================
-- 3. YETKİ KALIRMA (REVOKE)
-- =====================================================

-- Public şemadan varsayılan yetkileri kaldır
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;

-- Developer'dan hassas tablo yetkisi kaldır
REVOKE ALL ON user_accounts FROM db_developer;
REVOKE ALL ON login_attempts FROM db_developer;

-- Readonly'den hassas tablolar
REVOKE ALL ON financial_transactions FROM db_readonly;
REVOKE ALL ON user_accounts FROM db_readonly;
REVOKE ALL ON login_attempts FROM db_readonly;

-- HR'den finans tablosu
REVOKE ALL ON financial_transactions FROM db_hr;

-- =====================================================
-- 4. GÜVENLİ VIEW'LAR (Hassas veri maskeleme)
-- =====================================================

-- Çalışan bilgileri (TC kimlik maskelenmiş)
CREATE OR REPLACE VIEW v_employees_safe AS
SELECT
    emp_id,
    first_name,
    last_name,
    email,
    dept_id,
    phone,
    hire_date,
    is_active,
    -- TC kimlik maskeleme: sadece son 4 hane
    '***' || RIGHT(tc_kimlik, 4) AS tc_kimlik_masked,
    -- Maaş gizli
    CASE
        WHEN current_user IN ('admin', 'db_admin', 'db_hr')
        THEN salary
        ELSE NULL
    END AS salary
FROM employees;

GRANT SELECT ON v_employees_safe TO db_developer, db_analyst, db_readonly;

-- Finansal özet (detay gizli)
CREATE OR REPLACE VIEW v_financial_summary AS
SELECT
    dept_id,
    txn_type,
    COUNT(*) AS islem_sayisi,
    SUM(amount) AS toplam_tutar,
    AVG(amount)::decimal(10,2) AS ortalama_tutar
FROM financial_transactions ft
JOIN employees e ON ft.emp_id = e.emp_id
GROUP BY dept_id, txn_type;

GRANT SELECT ON v_financial_summary TO db_analyst;

-- =====================================================
-- 5. YETKİLERİ KONTROL ET
-- =====================================================

-- Kullanıcıları listele
SELECT usename, usesuper, usecreatedb
FROM pg_user
WHERE usename LIKE 'db_%'
ORDER BY usename;

-- Tablo yetkilerini listele
SELECT
    grantee,
    table_name,
    string_agg(privilege_type, ', ') AS yetkiler
FROM information_schema.table_privileges
WHERE grantee LIKE 'db_%'
GROUP BY grantee, table_name
ORDER BY grantee, table_name;

\echo ''
\echo '=============================='
\echo '  Kullanıcı ve Roller Oluşturuldu'
\echo '=============================='
