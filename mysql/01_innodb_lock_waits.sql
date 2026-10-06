-- ============================================================================
-- Script:      01_innodb_lock_waits.sql
-- Product:     The 5-Minute Production SQL Health Check
-- Author:      Production SQL (productionsql.com)
-- Engine:      MySQL 5.7, 8.0, 8.4+ (AWS RDS, Aurora, Self-Hosted)
-- Safety:      100% Read-Only. Safe under high load.
-- ============================================================================

SELECT '>>> CHECK: ACTIVE INNODB LOCK WAITS (WHO BLOCKS WHOM)' AS '';

SELECT 
    waiting_trx_id,
    waiting_pid,
    blocking_trx_id,
    blocking_pid,
    wait_age,
    sql_kill_blocking_query
FROM sys.innodb_lock_waits
ORDER BY wait_age_secs DESC
LIMIT 10;