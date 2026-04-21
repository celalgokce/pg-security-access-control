# Proje 3: Veritabanı Güvenliği ve Erişim Kontrolü

## Rapor

### 1. Giriş

Bu projede PostgreSQL veritabanı üzerinde güvenlik mekanizmalarının uygulanması amaçlanmıştır. Proje kapsamında kullanıcı ve rol yönetimi, Row Level Security (RLS), veri şifreleme, SQL injection koruması ve audit logging konuları incelenmiş ve uygulanmıştır.

**Kullanılan Teknolojiler:**
- PostgreSQL 16
- Docker & Docker Compose
- pgcrypto (simetrik şifreleme, hashing)
- pgaudit (audit logging)
- scram-sha-256 (authentication)

### 2. Ortam Kurulumu

#### 2.1 Docker ile PostgreSQL Kurulumu

Güvenlik testleri için Docker Compose kullanılarak ayrı bir PostgreSQL 16 instance oluşturulmuştur. pgaudit ve log ayarları docker-compose.yml içinde yapılandırılmıştır.

```yaml
# Önemli güvenlik parametreleri:
# - shared_preload_libraries='pgaudit'
# - pgaudit.log='all'
# - password_encryption=scram-sha-256
# - log_connections=on
```

#### 2.2 Örnek Veritabanı

HR/Finans senaryosu üzerine kurulu, hassas veri içeren bir veritabanı:
- **departments:** Departman bilgileri
- **employees:** Çalışan bilgileri (maaş, TC kimlik — hassas)
- **user_accounts:** Kullanıcı hesapları (hash'lenmiş şifreler)
- **financial_transactions:** Finansal işlemler (şifreli kredi kartı)
- **login_attempts:** Giriş denemeleri

### 3. Erişim Yönetimi (RBAC)

*(Bu bölüm uygulamadan sonra detaylandırılacaktır)*

#### 3.1 Roller
- db_admin: Tam yetki
- db_developer: Okuma + sınırlı yazma
- db_analyst: Sadece okuma
- db_hr: Çalışan verilerine erişim
- db_readonly: Genel okuma

#### 3.2 GRANT / REVOKE
#### 3.3 Row Level Security (RLS)
#### 3.4 Güvenli View'lar

### 4. Authentication Yapılandırması

*(Bu bölüm uygulamadan sonra detaylandırılacaktır)*

#### 4.1 pg_hba.conf Kuralları
#### 4.2 scram-sha-256 Encryption
#### 4.3 SSL/TLS Bağlantı

### 5. Veri Şifreleme

*(Bu bölüm uygulamadan sonra detaylandırılacaktır)*

#### 5.1 Simetrik Şifreleme (AES — pgcrypto)
#### 5.2 Password Hashing (bcrypt)
#### 5.3 Hash Fonksiyonları (SHA-256, SHA-512)
#### 5.4 Şifreli View'lar

### 6. SQL Injection Testleri

*(Bu bölüm uygulamadan sonra detaylandırılacaktır)*

#### 6.1 Saldırı Demoları
- String concatenation açığı
- UNION-based injection
- Blind injection

#### 6.2 Korunma Yöntemleri
- Prepared Statements
- Stored Procedures
- Input Validation

### 7. Audit Logging

*(Bu bölüm uygulamadan sonra detaylandırılacaktır)*

#### 7.1 pgaudit Yapılandırması
#### 7.2 Rol Bazlı Audit Seviyeleri
#### 7.3 Login Denemeleri İzleme
#### 7.4 Hesap Kilitleme Mekanizması

### 8. Güvenlik Test Raporu

*(Bu bölüm uygulamadan sonra detaylandırılacaktır)*

### 9. Sonuç

*(Proje tamamlandığında yazılacaktır)*

---

**Son Güncelleme:** Faz 1 - Ortam kurulumu ve planlama
