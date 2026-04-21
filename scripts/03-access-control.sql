-- =====================================================
-- BLM4522 Proje 3: Erişim Kontrolü ve Row Level Security
-- =====================================================

-- =====================================================
-- 1. ROW LEVEL SECURITY (RLS)
-- =====================================================

-- RLS'yi aktif et
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;

-- Policy: HR tüm çalışanları görebilir
CREATE POLICY hr_all_employees ON employees
    FOR ALL
    TO db_hr
    USING (true);

-- Policy: Developer sadece kendi departmanındaki çalışanları görebilir
-- (dept_id=1 IT departmanı olarak varsayıyoruz)
CREATE POLICY dev_own_dept ON employees
    FOR SELECT
    TO db_developer
    USING (dept_id = 1);

-- Policy: Analyst tüm çalışanları okuyabilir ama güncelleyemez
CREATE POLICY analyst_read_all ON employees
    FOR SELECT
    TO db_analyst
    USING (true);

-- Policy: Readonly sadece aktif çalışanları görebilir
CREATE POLICY readonly_active ON employees
    FOR SELECT
    TO db_readonly
    USING (is_active = true);

-- Admin her zaman her şeyi görebilir
CREATE POLICY admin_all ON employees
    FOR ALL
    TO db_admin
    USING (true)
    WITH CHECK (true);

-- =====================================================
-- 2. RLS TEST
-- =====================================================

\echo ''
\echo '=== RLS TEST SONUÇLARI ==='
\echo ''

-- Admin olarak toplam kayıt
\echo 'Admin olarak toplam çalışan sayısı:'
SELECT COUNT(*) AS admin_goruntusu FROM employees;

-- Developer olarak test (SET ROLE ile simüle)
\echo ''
\echo 'Developer olarak (sadece IT dept):'
SET ROLE db_developer;
SELECT COUNT(*) AS developer_goruntusu FROM employees;
RESET ROLE;

-- Analyst olarak test
\echo ''
\echo 'Analyst olarak (tüm çalışanlar):'
SET ROLE db_analyst;
SELECT COUNT(*) AS analyst_goruntusu FROM employees;
RESET ROLE;

-- HR olarak test
\echo ''
\echo 'HR olarak (tüm çalışanlar + yazma):'
SET ROLE db_hr;
SELECT COUNT(*) AS hr_goruntusu FROM employees;
RESET ROLE;

-- =====================================================
-- 3. COLUMN LEVEL SECURİTY (Sütun Bazlı Kısıtlama)
-- =====================================================

-- Salary sütununu sadece admin ve HR görebilir
REVOKE SELECT (salary) ON employees FROM db_developer, db_analyst, db_readonly;
REVOKE SELECT (tc_kimlik) ON employees FROM db_developer, db_analyst, db_readonly;

-- Test: Developer maaş göremez
\echo ''
\echo '=== SÜTUN BAZLI KISITLAMA TEST ==='
\echo ''
\echo 'Developer salary sütununa erişim denemesi:'
SET ROLE db_developer;
-- Bu hata verecek:
SELECT emp_id, first_name, salary FROM employees LIMIT 1;
RESET ROLE;

-- =====================================================
-- 4. SCHEMA BAZLI İZOLASYON
-- =====================================================

-- Finans şeması oluştur
CREATE SCHEMA IF NOT EXISTS finance;

-- Finans tablosunu finans şemasına taşı (view ile)
CREATE OR REPLACE VIEW finance.transactions AS
SELECT * FROM public.financial_transactions;

-- Sadece finans ve admin erişebilir
GRANT USAGE ON SCHEMA finance TO db_admin;
REVOKE ALL ON SCHEMA finance FROM PUBLIC;

\echo ''
\echo '=== SCHEMA İZOLASYON ==='
\echo 'Finance şeması oluşturuldu, sadece admin erişebilir'

-- =====================================================
-- 5. AKTİF POLİCY'LERİ LİSTELE
-- =====================================================

\echo ''
\echo '=== AKTİF RLS POLİCY LİSTESİ ==='
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE tablename = 'employees'
ORDER BY policyname;
