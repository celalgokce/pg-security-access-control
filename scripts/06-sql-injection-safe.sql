-- =====================================================
-- BLM4522 Proje 3: SQL Injection Korunma Yöntemleri
-- =====================================================

\echo '=============================='
\echo '  SQL INJECTION KORUNMA'
\echo '=============================='

-- =====================================================
-- 1. PREPARED STATEMENTS (Parameterized Queries)
-- =====================================================

\echo ''
\echo '=== 1. PREPARED STATEMENTS ==='

-- Prepared statement oluştur
PREPARE safe_employee_search(text) AS
    SELECT emp_id, first_name, last_name, email
    FROM employees
    WHERE email = $1;

-- Normal kullanım
\echo ''
\echo 'Normal arama (prepared statement):'
EXECUTE safe_employee_search('ahmet.yilmaz@sirket.com');

-- Injection denemesi → GÜVENLİ
\echo ''
\echo 'Injection denemesi (prepared statement ile GÜVENLİ):'
EXECUTE safe_employee_search(''' OR ''1''=''1');
\echo '→ Hiçbir sonuç dönmedi! Injection başarısız.'

-- Prepared statement temizle
DEALLOCATE safe_employee_search;

-- =====================================================
-- 2. STORED PROCEDURE / FUNCTION
-- =====================================================

\echo ''
\echo '=== 2. GÜVENLİ FONKSİYON ==='

-- Güvenli arama fonksiyonu
CREATE OR REPLACE FUNCTION safe_search_employee(p_email TEXT)
RETURNS TABLE (
    emp_id INTEGER,
    first_name VARCHAR,
    last_name VARCHAR,
    email VARCHAR
)
LANGUAGE plpgsql
SECURITY DEFINER  -- Fonksiyon sahibinin yetkileriyle çalışır
AS $$
BEGIN
    -- Input validation
    IF p_email IS NULL OR LENGTH(p_email) > 100 THEN
        RAISE EXCEPTION 'Geçersiz email parametresi';
    END IF;

    -- Parameterized query (injection güvenli)
    RETURN QUERY
    SELECT e.emp_id, e.first_name, e.last_name, e.email
    FROM employees e
    WHERE e.email = p_email;
END;
$$;

-- Test: Normal kullanım
\echo ''
\echo 'Güvenli fonksiyon - normal arama:'
SELECT * FROM safe_search_employee('ahmet.yilmaz@sirket.com');

-- Test: Injection denemesi
\echo ''
\echo 'Güvenli fonksiyon - injection denemesi:'
SELECT * FROM safe_search_employee(''' OR ''1''=''1');
\echo '→ Sonuç yok! Fonksiyon güvenli.'

-- =====================================================
-- 3. GÜVENLİ LOGIN FONKSİYONU
-- =====================================================

\echo ''
\echo '=== 3. GÜVENLİ LOGIN ==='

CREATE OR REPLACE FUNCTION safe_login(
    p_username TEXT,
    p_password TEXT
)
RETURNS TABLE (
    user_id INTEGER,
    username VARCHAR,
    role VARCHAR,
    login_result TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id INTEGER;
    v_username VARCHAR;
    v_role VARCHAR;
    v_hash TEXT;
BEGIN
    -- Input validation
    IF p_username IS NULL OR LENGTH(p_username) > 50 THEN
        RAISE EXCEPTION 'Geçersiz kullanıcı adı';
    END IF;

    IF p_password IS NULL OR LENGTH(p_password) < 6 THEN
        RAISE EXCEPTION 'Şifre en az 6 karakter olmalı';
    END IF;

    -- Parameterized query ile kullanıcı bul
    SELECT ua.user_id, ua.username, ua.role, ua.password_hash
    INTO v_user_id, v_username, v_role, v_hash
    FROM user_accounts ua
    WHERE ua.username = p_username
    AND ua.is_locked = false;

    IF v_user_id IS NULL THEN
        -- Başarısız giriş logla
        INSERT INTO login_attempts (username, success, failure_reason)
        VALUES (p_username, false, 'Kullanıcı bulunamadı');

        RETURN QUERY SELECT NULL::integer, p_username::varchar, NULL::varchar, 'BAŞARISIZ: Kullanıcı bulunamadı'::text;
        RETURN;
    END IF;

    -- Şifre kontrolü (bcrypt)
    IF v_hash = crypt(p_password, v_hash) THEN
        -- Başarılı giriş
        UPDATE user_accounts SET last_login = NOW() WHERE user_accounts.user_id = v_user_id;
        INSERT INTO login_attempts (username, success)
        VALUES (p_username, true);

        RETURN QUERY SELECT v_user_id, v_username, v_role, '✓ GİRİŞ BAŞARILI'::text;
    ELSE
        -- Başarısız giriş
        INSERT INTO login_attempts (username, success, failure_reason)
        VALUES (p_username, false, 'Yanlış şifre');

        RETURN QUERY SELECT NULL::integer, p_username::varchar, NULL::varchar, '✗ BAŞARISIZ: Yanlış şifre'::text;
    END IF;
END;
$$;

-- Test: Doğru şifre
\echo ''
\echo 'Login testi (doğru şifre):'
SELECT * FROM safe_login('ahmet.yilmaz', 'Sifre123!');

-- Test: Yanlış şifre
\echo ''
\echo 'Login testi (yanlış şifre):'
SELECT * FROM safe_login('ahmet.yilmaz', 'YanlisSifre');

-- Test: Injection denemesi
\echo ''
\echo 'Login injection denemesi:'
SELECT * FROM safe_login(''' OR ''1''=''1'' --', 'herhangi');
\echo '→ Injection başarısız! Fonksiyon güvenli.'

-- =====================================================
-- 4. INPUT VALIDATION FONKSİYONU
-- =====================================================

\echo ''
\echo '=== 4. INPUT VALIDATION ==='

CREATE OR REPLACE FUNCTION validate_input(
    p_input TEXT,
    p_type TEXT DEFAULT 'text'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    -- NULL kontrolü
    IF p_input IS NULL THEN
        RETURN false;
    END IF;

    -- Tehlikeli karakter kontrolü
    IF p_input ~ '[;''"\-\-]' THEN
        RAISE WARNING 'Tehlikeli karakter tespit edildi: %', p_input;
        RETURN false;
    END IF;

    -- Tip bazlı doğrulama
    CASE p_type
        WHEN 'email' THEN
            RETURN p_input ~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
        WHEN 'phone' THEN
            RETURN p_input ~ '^\+?[0-9]{10,15}$';
        WHEN 'tc_kimlik' THEN
            RETURN p_input ~ '^[0-9]{11}$';
        ELSE
            RETURN LENGTH(p_input) <= 200;
    END CASE;
END;
$$;

-- Test
\echo ''
\echo 'Input validation testleri:'
SELECT
    input_text,
    input_type,
    validate_input(input_text, input_type) AS gecerli_mi
FROM (VALUES
    ('ahmet@email.com', 'email'),
    (''' OR 1=1 --', 'email'),
    ('05551234567', 'phone'),
    ('12345678901', 'tc_kimlik'),
    ('DROP TABLE users', 'text')
) AS t(input_text, input_type);

-- =====================================================
-- 5. KARŞILAŞTIRMA TABLOSU
-- =====================================================

\echo ''
\echo '=============================='
\echo '  KARŞILAŞTIRMA'
\echo '=============================='
\echo ''
\echo '  GÜVENSİZ (String Concatenation):'
\echo '    "SELECT * FROM users WHERE email=''" + input + "''"'
\echo '    → SQL Injection''a AÇIK!'
\echo ''
\echo '  GÜVENLİ (Prepared Statement):'
\echo '    "SELECT * FROM users WHERE email = $1"'
\echo '    → Parametre ayrı gönderilir, injection İMKANSIZ'
\echo ''
\echo '  GÜVENLİ (Stored Procedure):'
\echo '    "SELECT * FROM safe_search_employee($1)"'
\echo '    → Input validation + parameterized query'
\echo ''
\echo '=============================='
