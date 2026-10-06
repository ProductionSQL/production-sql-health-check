-- ============================================================================
-- Script:      03_buffer_pool_and_trx.sql
-- Product:     The 5-Minute Production SQL Health Check
-- Author:      Production SQL (productionsql.com)
-- Engine:      MySQL 5.7, 8.0, 8.4+ (AWS RDS, Aurora, Self-Hosted)
-- Safety:      100% Read-Only. Safe under high load.
-- ============================================================================

SELECT '>>> CHECK A: ACTIVE INNODB TRANSACTIONS OPEN > 30 SECONDS' AS '';

SELECT 
    t.trx_id,
    t.trx_mysql_thread_id AS thread_id,
    t.trx_state,
    ROUND(TIME_TO_SEC(TIMEDIFF(NOW(), t.trx_started))) AS elapsed_sec,
    t.trx_rows_locked,
    t.trx_rows_modified,
    LEFT(t.trx_query, 80) AS query_snippet
FROM information_schema.innodb_trx t
WHERE TIME_TO_SEC(TIMEDIFF(NOW(), t.trx_started)) > 30
ORDER BY t.trx_started ASC
LIMIT 10;

SELECT '>>> CHECK B: INNODB BUFFER POOL EFFICIENCY METRICS' AS '';

SELECT 
    variable_name,
    variable_value
FROM performance_schema.global_status
WHERE variable_name IN (
    'Innodb_buffer_pool_read_requests',
    'Innodb_buffer_pool_reads',
    'Innodb_buffer_pool_pages_dirty',
    'Innodb_buffer_pool_wait_free'
);