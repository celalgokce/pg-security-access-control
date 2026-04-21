-- =====================================================
-- BLM4522 Proje 3: Veri Şifreleme (pgcrypto)
-- =====================================================

-- pgcrypto extension kontrolü
CREATE EXTENSION IF NOT EXISTS pgcrypto;

\echo '=============================='
\echo '  VERİ ŞİFRELEME DEMO'
\echo '=============================='

-- =====================================================
-- 1. SİMETRİK ŞİFRELEME (AES-256)
-- =====================================================

\echo ''
\echo '=== 1. SİMETRİK ŞİFRELEME (AES) ==='

-- Şifreleme anahtarı (gerçek uygulamada environment variable olmalı)
-- Demo amaçlı hardcoded
\set encryption_key 'MySecretKey2024!'

-- TC Kimlik numaralarını şifrele
ALTER TABLE employees ADD COLUMN IF NOT EXISTS tc_kimlik_enc BYTEA;

UPDATE employees
SET tc_kimlik_enc = pgp_sym_encrypt(tc_kimlik, 'MySecretKey2024!')
WHERE tc_kimlik IS NOT NULL AND tc_kimlik_enc IS NULL;

\echo 'TC Kimlik numaraları şifrelendi.'

-- Şifreli veriyi göster
\echo ''
\echo 'Şifreli TC Kimlik (ilk 5 kayıt):'
SELECT
    emp_id,
    first_name,
    tc_kimlik AS tc_plain,
    encode(tc_kimlik_enc, 'hex') AS tc_encrypted_hex
FROM employees
WHERE emp_id <= 5;

-- Şifreyi çöz
\echo ''
\echo 'Şifresi çözülmüş TC Kimlik:'
SELECT
    emp_id,
    first_name,
    pgp_sym_decrypt(tc_kimlik_enc, 'MySecretKey2024!') AS tc_decrypted
FROM employees
WHERE emp_id <= 5;

-- Yanlış anahtar ile deneme
\echo ''
\echo 'Yanlış anahtar ile çözme denemesi (hata bekleniyor):'
DO $$
BEGIN
    PERFORM pgp_sym_decrypt(
        (SELECT tc_kimlik_enc FROM employees WHERE emp_id = 1),
        'YanlisAnahtar123'
    );
    RAISE NOTICE 'Şifre çözüldü (bu olmamalı!)';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'HATA: Yanlış anahtar ile şifre çözülemedi! -> %', SQLERRM;
END $$;

-- =====================================================
-- 2. KREDİ KARTI ŞİFRELEME
-- =====================================================

\echo ''
\echo '=== 2. KREDİ KARTI ŞİFRELEME ==='

-- Örnek kredi kartı verisi ekle (şifrelenmiş)
UPDATE financial_transactions
SET credit_card_enc = pgp_sym_encrypt(
    '4532' || LPAD((random() * 999999999999)::bigint::text, 12, '0'),
    'MySecretKey2024!'
)
WHERE txn_id <= 10;

\echo 'Kredi kartı numaraları şifrelendi (ilk 10 işlem).'

-- Şifreli ve çözülmüş göster
SELECT
    txn_id,
    encode(credit_card_enc, 'hex') AS encrypted_card,
    pgp_sym_decrypt(credit_card_enc, 'MySecretKey2024!') AS decrypted_card
FROM financial_transactions
WHERE txn_id <= 5;

-- =====================================================
-- 3. PASSWORD HASHING (bcrypt)
-- =====================================================

\echo ''
\echo '=== 3. PASSWORD HASHING ==='

-- Kullanıcı hesapları oluştur (şifreleri hash'le)
INSERT INTO user_accounts (username, password_hash, emp_id, role) VALUES
('ahmet.yilmaz', crypt('Sifre123!', gen_salt('bf', 10)), 1, 'admin'),
('fatma.kaya', crypt('Parola456!', gen_salt('bf', 10)), 2, 'hr'),
('mehmet.demir', crypt('GucluSifre789!', gen_salt('bf', 10)), 3, 'finance'),
('ayse.celik', crypt('Test1234!', gen_salt('bf', 10)), 4, 'developer'),
('ali.ozturk', crypt('Marketing2024!', gen_salt('bf', 10)), 5, 'user')
ON CONFLICT (username) DO NOTHING;

\echo 'Kullanıcı hesapları oluşturuldu (bcrypt hash).'
\echo ''
\echo 'Hash''lenmiş şifreler:'
SELECT username, LEFT(password_hash, 30) || '...' AS hash_preview, role
FROM user_accounts;

-- Login doğrulama (doğru şifre)
\echo ''
\echo 'Login denemesi (doğru şifre):'
SELECT
    username,
    CASE
        WHEN password_hash = crypt('Sifre123!', password_hash)
        THEN '✓ GİRİŞ BAŞARILI'
        ELSE '✗ GİRİŞ BAŞARISIZ'
    END AS login_sonucu
FROM user_accounts
WHERE username = 'ahmet.yilmaz';

-- Login doğrulama (yanlış şifre)
\echo ''
\echo 'Login denemesi (yanlış şifre):'
SELECT
    username,
    CASE
        WHEN password_hash = crypt('YanlisSifre', password_hash)
        THEN '✓ GİRİŞ BAŞARILI'
        ELSE '✗ GİRİŞ BAŞARISIZ'
    END AS login_sonucu
FROM user_accounts
WHERE username = 'ahmet.yilmaz';

-- =====================================================
-- 4. HASH FONKSİYONLARI
-- =====================================================

\echo ''
\echo '=== 4. HASH FONKSİYONLARI ==='

SELECT
    'SHA-256' AS algoritma,
    encode(digest('Merhaba Dünya', 'sha256'), 'hex') AS hash_degeri
UNION ALL
SELECT
    'SHA-512',
    LEFT(encode(digest('Merhaba Dünya', 'sha512'), 'hex'), 64) || '...'
UNION ALL
SELECT
    'MD5 (güvensiz)',
    md5('Merhaba Dünya');

-- =====================================================
-- 5. ŞİFRELİ SÜTUN İÇİN GÜVENLİ VIEW
-- =====================================================

\echo ''
\echo '=== 5. GÜVENLİ VIEW ==='

CREATE OR REPLACE VIEW v_employees_encrypted AS
SELECT
    emp_id,
    first_name,
    last_name,
    email,
    dept_id,
    -- TC kimlik sadece admin görür
    CASE
        WHEN current_user IN ('admin', 'db_admin')
        THEN pgp_sym_decrypt(tc_kimlik_enc, 'MySecretKey2024!')
        ELSE '***********'
    END AS tc_kimlik,
    -- Maaş sadece HR ve admin görür
    CASE
        WHEN current_user IN ('admin', 'db_admin', 'db_hr')
        THEN salary::text
        ELSE '***'
    END AS salary
FROM employees;

\echo 'Güvenli view oluşturuldu: v_employees_encrypted'
\echo ''
\echo '=============================='
\echo '  ŞİFRELEME TAMAMLANDI'
\echo '=============================='
