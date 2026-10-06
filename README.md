# The 5-Minute Production SQL Health Check
**Diagnostic Triage Kits for Oracle, PostgreSQL, and MySQL**  
Published by [Production SQL](https://productionsql.com)

---

## ⚡ Production Safety Rules
1. **100% Read-Only:** All queries target engine diagnostic views, system catalogs, and session tables. No DDL, no DML, no locks taken.
2. **Aggressive Limits:** Every check enforces strict row limits (`LIMIT`, `ROWNUM`, or `FETCH FIRST`) to prevent buffer bloat or terminal stalls.
3. **AWS RDS / Cloud Compatible:** Designed to run without root/OS access on Amazon RDS, Aurora, and self-hosted instances.

---

## 🚀 Quick Start Instructions

### 1. Oracle
Run via SQL*Plus, SQLcl, or your preferred SQL IDE:
```bash
sqlplus / as sysdba @oracle/oracle_full_triage.sql