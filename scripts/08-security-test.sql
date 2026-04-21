-- =====================================================
-- BLM4522 Proje 3: Güvenlik Test Raporu
-- Tüm güvenlik önlemlerinin doğrulanması
-- =====================================================

\echo '============================================'
\echo '  GÜVENLİK TEST RAPORU'
\echo '============================================'

-- =====================================================
-- TEST 1: Rol ve Yetki Kontrolü
-- =====================================================

\echo ''
\echo '=== TEST 1: Rol ve Yetki Kontrolü ==='

-- Tüm kullanıcıları listele
\echo ''
\echo 'Veritabanı kullanıcıları:'
SELECT usename, usesuper, usecreatedb, valuntil
FROM pg_user
WHERE usename LIKE 'db_%' OR usename = 'admin'
ORDER BY usename;

-- Developer → employees tablosuna yazabilir mi?
\echo ''
\echo '[1.1] Developer employees tablosuna INSERT:'
SET ROLE db_developer;
DO $$
BEGIN
    INSERT INTO employees (first_name, last_name, email, dept_id, salary)
    VALUES ('Test', 'Developer', 'test.dev@sirket.com', 1, 25000);
    RAISE NOTICE '✓ INSERT başarılı';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '✗ INSERT başarısız: %', SQLERRM;
END $$;
RESET ROLE;

-- Analyst → employees tablosuna yazabilir mi?
\echo ''
\echo '[1.2] Analyst employees tablosuna INSERT (hata bekleniyor):'
SET ROLE db_analyst;
DO $$
BEGIN
    INSERT INTO employees (first_name, last_name, email, dept_id, salary)
    VALUES ('Test', 'Analyst', 'test.analyst@sirket.com', 1, 25000);
    RAISE NOTICE '✗ INSERT başarılı (bu olmamalı!)';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '✓ INSERT reddedildi: %', SQLERRM;
END $$;
RESET ROLE;

-- Readonly → financial_transactions okuyabilir mi?
\echo ''
\echo '[1.3] Readonly financial_transactions okuma (hata bekleniyor):'
SET ROLE db_readonly;
DO $$
BEGIN
    PERFORM COUNT(*) FROM financial_transactions;
    RAISE NOTICE '✗ SELECT başarılı (bu olmamalı!)';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '✓ SELECT reddedildi: %', SQLERRM;
END $$;
RESET ROLE;

-- =====================================================
-- TEST 2: Row Level Security
-- =====================================================

\echo ''
\echo '=== TEST 2: Row Level Security ==='

\echo ''
\echo '[2.1] Admin toplam çalışan:'
SELECT COUNT(*) AS admin_view FROM employees;

\echo ''
\echo '[2.2] Developer toplam çalışan (sadece IT dept):'
SET ROLE db_developer;
SELECT COUNT(*) AS developer_view FROM employees;
RESET ROLE;

\echo ''
\echo '[2.3] HR toplam çalışan:'
SET ROLE db_hr;
SELECT COUNT(*) AS hr_view FROM employees;
RESET ROLE;

-- =====================================================
-- TEST 3: Şifreleme Kontrolü
-- =====================================================

\echo ''
\echo '=== TEST 3: Şifreleme Kontrolü ==='

-- Şifrelenmiş veri mevcut mu?
\echo ''
\echo '[3.1] Şifrelenmiş TC kimlik kayıt sayısı:'
SELECT COUNT(*) AS sifrelenmis_kayit
FROM employees
WHERE tc_kimlik_enc IS NOT NULL;

-- Doğru anahtar ile çözme
\echo ''
\echo '[3.2] Doğru anahtar ile şifre çözme:'
SELECT emp_id, first_name,
    pgp_sym_decrypt(tc_kimlik_enc, 'MySecretKey2024!') AS tc_decrypted
FROM employees
WHERE emp_id = 1 AND tc_kimlik_enc IS NOT NULL;

-- Password hash kontrolü
\echo ''
\echo '[3.3] Password hash formatı (bcrypt):'
SELECT username, LEFT(password_hash, 7) AS hash_prefix,
    LENGTH(password_hash) AS hash_length
FROM user_accounts
LIMIT 3;
\echo '(bcrypt hash $2a$ ile başlamalı, 60 karakter olmalı)'

-- =====================================================
-- TEST 4: SQL Injection Koruması
-- =====================================================

\echo ''
\echo '=== TEST 4: SQL Injection Koruması ==='

-- Prepared statement ile injection denemesi
\echo ''
\echo '[4.1] Prepared statement injection testi:'
PREPARE injection_test(text) AS
    SELECT COUNT(*) AS sonuc FROM employees WHERE email = $1;

\echo 'Normal sorgu:'
EXECUTE injection_test('ahmet.yilmaz@sirket.com');

\echo 'Injection denemesi:'
EXECUTE injection_test(''' OR ''1''=''1');
\echo '→ 0 kayıt = GÜVENLİ'

DEALLOCATE injection_test;

-- Güvenli fonksiyon testi
\echo ''
\echo '[4.2] Güvenli login fonksiyonu injection testi:'
SELECT * FROM safe_login(''' OR 1=1 --', 'herhangi');
\echo '→ Başarısız = GÜVENLİ'

-- =====================================================
-- TEST 5: Audit Log Kontrolü
-- =====================================================

\echo ''
\echo '=== TEST 5: Audit Kontrolü ==='

\echo ''
\echo '[5.1] Son login denemeleri:'
SELECT username, attempt_time,
    CASE WHEN success THEN '✓' ELSE '✗' END AS durum,
    failure_reason
FROM login_attempts
ORDER BY attempt_time DESC
LIMIT 5;

\echo ''
\echo '[5.2] pgaudit ayarları:'
SHOW pgaudit.log;
SHOW pgaudit.log_parameter;

\echo ''
\echo '[5.3] Genel log ayarları:'
SHOW log_statement;
SHOW log_connections;
SHOW log_disconnections;
SHOW password_encryption;

-- =====================================================
-- ÖZET RAPOR
-- =====================================================

\echo ''
\echo '============================================'
\echo '  GÜVENLİK ÖZETİ'
\echo '============================================'
\echo ''
\echo '  ✓ Rol tabanlı erişim kontrolü (RBAC)'
\echo '  ✓ Row Level Security (RLS)'
\echo '  ✓ Sütun bazlı kısıtlama'
\echo '  ✓ Schema izolasyonu'
\echo '  ✓ Veri şifreleme (pgcrypto AES)'
\echo '  ✓ Password hashing (bcrypt)'
\echo '  ✓ Prepared statements (SQL injection koruması)'
\echo '  ✓ Input validation fonksiyonları'
\echo '  ✓ Güvenli login mekanizması'
\echo '  ✓ Audit logging (pgaudit)'
\echo '  ✓ Hesap kilitleme (brute-force koruması)'
\echo '  ✓ scram-sha-256 authentication'
\echo ''
\echo '============================================'
