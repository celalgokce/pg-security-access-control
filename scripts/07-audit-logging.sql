-- =====================================================
-- BLM4522 Proje 3: Audit Logging (pgaudit)
-- =====================================================

\echo '=============================='
\echo '  AUDIT LOGGING YAPILANDIRMASI'
\echo '=============================='

-- =====================================================
-- 1. pgaudit KURULUMU VE YAPILANDIRMA
-- =====================================================

\echo ''
\echo '=== 1. pgaudit Durumu ==='

-- pgaudit extension kontrolü
CREATE EXTENSION IF NOT EXISTS pgaudit;

-- Mevcut audit ayarlarını göster
SELECT name, setting, short_desc
FROM pg_settings
WHERE name LIKE 'pgaudit%'
ORDER BY name;

-- =====================================================
-- 2. AUDIT LOG SEVİYELERİ
-- =====================================================

\echo ''
\echo '=== 2. Audit Seviyeleri Yapılandırması ==='

-- Tüm DML ve DDL işlemlerini logla
-- (docker-compose.yml'de zaten ayarlandı:
--  pgaudit.log = 'all'
--  pgaudit.log_parameter = on)

-- Obje bazlı audit (belirli tablolar için)
-- Admin rolü için detaylı audit
ALTER ROLE db_admin SET pgaudit.log = 'all';
ALTER ROLE db_developer SET pgaudit.log = 'write, ddl';
ALTER ROLE db_analyst SET pgaudit.log = 'read';
ALTER ROLE db_hr SET pgaudit.log = 'all';

\echo 'Rol bazlı audit seviyeleri ayarlandı:'
\echo '  db_admin    → all (tüm işlemler)'
\echo '  db_developer → write, ddl (yazma + şema değişiklikleri)'
\echo '  db_analyst  → read (okuma işlemleri)'
\echo '  db_hr       → all (tüm işlemler)'

-- =====================================================
-- 3. AUDIT TEST İŞLEMLERİ
-- =====================================================

\echo ''
\echo '=== 3. Audit Test İşlemleri ==='

-- SELECT işlemi (READ audit)
\echo ''
\echo '[TEST 1] SELECT işlemi (audit: READ):'
SELECT emp_id, first_name, email FROM employees WHERE emp_id = 1;

-- INSERT işlemi (WRITE audit)
\echo ''
\echo '[TEST 2] INSERT işlemi (audit: WRITE):'
INSERT INTO login_attempts (username, success, failure_reason, ip_address)
VALUES ('test_audit_user', false, 'Audit test', '192.168.1.100');

-- UPDATE işlemi (WRITE audit)
\echo ''
\echo '[TEST 3] UPDATE işlemi (audit: WRITE):'
UPDATE employees SET phone = '05559999999' WHERE emp_id = 1;

-- DDL işlemi (DDL audit)
\echo ''
\echo '[TEST 4] DDL işlemi (audit: DDL):'
CREATE TABLE IF NOT EXISTS audit_test_table (
    id SERIAL PRIMARY KEY,
    data TEXT
);
DROP TABLE IF EXISTS audit_test_table;

-- =====================================================
-- 4. LOG ANALİZİ
-- =====================================================

\echo ''
\echo '=== 4. Log Analizi ==='
\echo ''
\echo 'PostgreSQL logları Docker ile görüntülenebilir:'
\echo '  docker logs pg-security 2>&1 | grep AUDIT'
\echo ''
\echo 'Örnek log formatı:'
\echo '  AUDIT: SESSION,1,1,READ,SELECT,TABLE,public.employees,...'
\echo '  AUDIT: SESSION,2,1,WRITE,INSERT,TABLE,public.login_attempts,...'

-- =====================================================
-- 5. LOGIN DENEMELERİ RAPORU
-- =====================================================

\echo ''
\echo '=== 5. Login Denemeleri Raporu ==='

-- Son login denemeleri
SELECT
    username,
    attempt_time,
    ip_address,
    CASE WHEN success THEN '✓ Başarılı' ELSE '✗ Başarısız' END AS durum,
    failure_reason
FROM login_attempts
ORDER BY attempt_time DESC
LIMIT 10;

-- Başarısız giriş istatistikleri
\echo ''
\echo 'Başarısız giriş istatistikleri:'
SELECT
    username,
    COUNT(*) AS basarisiz_deneme,
    MAX(attempt_time) AS son_deneme
FROM login_attempts
WHERE success = false
GROUP BY username
HAVING COUNT(*) >= 1
ORDER BY basarisiz_deneme DESC;

-- =====================================================
-- 6. HESAP KİLİTLEME MEKANİZMASI
-- =====================================================

\echo ''
\echo '=== 6. Hesap Kilitleme ==='

-- 3'ten fazla başarısız deneme → hesap kilitle
CREATE OR REPLACE FUNCTION check_and_lock_account()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    fail_count INTEGER;
BEGIN
    IF NEW.success = false THEN
        SELECT COUNT(*) INTO fail_count
        FROM login_attempts
        WHERE username = NEW.username
        AND success = false
        AND attempt_time > NOW() - INTERVAL '30 minutes';

        IF fail_count >= 3 THEN
            UPDATE user_accounts
            SET is_locked = true
            WHERE username = NEW.username;
            RAISE WARNING 'HESAP KİLİTLENDİ: % (30 dk içinde 3+ başarısız deneme)', NEW.username;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

-- Trigger oluştur
DROP TRIGGER IF EXISTS trg_check_lock ON login_attempts;
CREATE TRIGGER trg_check_lock
    AFTER INSERT ON login_attempts
    FOR EACH ROW
    EXECUTE FUNCTION check_and_lock_account();

\echo 'Hesap kilitleme mekanizması aktif (3 başarısız deneme → kilitle)'

-- =====================================================
-- 7. AUDIT RAPOR VIEW'LARI
-- =====================================================

\echo ''
\echo '=== 7. Audit Rapor View''ları ==='

-- Günlük aktivite özeti
CREATE OR REPLACE VIEW v_daily_activity AS
SELECT
    DATE(attempt_time) AS tarih,
    COUNT(*) AS toplam_deneme,
    SUM(CASE WHEN success THEN 1 ELSE 0 END) AS basarili,
    SUM(CASE WHEN NOT success THEN 1 ELSE 0 END) AS basarisiz,
    COUNT(DISTINCT username) AS benzersiz_kullanici,
    COUNT(DISTINCT ip_address) AS benzersiz_ip
FROM login_attempts
GROUP BY DATE(attempt_time)
ORDER BY tarih DESC;

\echo 'Günlük aktivite özeti:'
SELECT * FROM v_daily_activity;

-- Kilitli hesaplar
\echo ''
\echo 'Kilitli hesaplar:'
SELECT user_id, username, role, is_locked, last_login
FROM user_accounts
WHERE is_locked = true;

\echo ''
\echo '=============================='
\echo '  AUDIT LOGGING TAMAMLANDI'
\echo '=============================='
\echo ''
\echo 'Önemli komutlar:'
\echo '  docker logs pg-security 2>&1 | grep AUDIT  → Audit logları'
\echo '  docker logs pg-security 2>&1 | tail -50     → Son loglar'
