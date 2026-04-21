# Proje 3: Veritabanı Güvenliği ve Erişim Kontrolü

## Amaç
Veritabanı güvenliği üzerine odaklanarak kullanıcı erişim yönetimi, veri şifreleme, SQL injection koruması ve audit logging konularını uygulamak.

## Kullanılan Teknolojiler
- PostgreSQL 16
- Docker & Docker Compose
- pgcrypto (veri şifreleme)
- pgaudit (audit logging)
- SSL/TLS
- Row Level Security (RLS)

## Kapsam
1. **Erişim Yönetimi:** Rol tabanlı erişim kontrolü (RBAC), GRANT/REVOKE, RLS
2. **Authentication:** pg_hba.conf, scram-sha-256, SSL bağlantı
3. **Veri Şifreleme:** pgcrypto ile AES şifreleme, password hashing
4. **SQL Injection:** Saldırı demosu ve korunma yöntemleri
5. **Audit Logging:** pgaudit ile kullanıcı aktivite izleme

## Kurulum

```bash
cd docker/
docker compose up -d

# Örnek DB ve kullanıcıları oluştur
docker exec -i pg-security psql -U admin -d securitydb < scripts/01-setup-db.sql
docker exec -i pg-security psql -U admin -d securitydb < scripts/02-users-roles.sql
```

## Video
[Video linki](./video/README.md)
