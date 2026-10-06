-- ============================================================================
-- Script:      mysql_full_triage.sql
-- Product:     The 5-Minute Production SQL Health Check
-- Author:      Production SQL (productionsql.com)
-- Compatibility: MySQL 5.7, 8.0, 8.4+ (Self-Hosted, AWS RDS / Aurora MySQL)
-- Safety:      100% Read-Only. Uses performance_schema and sys schemas.
-- ============================================================================

SELECT '================================================================================' AS '';
SELECT ' PRODUCTION SQL: 5-MINUTE MYSQL TRIAGE REPORT' AS '';
SELECT '================================================================================' AS '';

-- ----------------------------------------------------------------------------
-- CHECK 1: TRANSACTIONS RUNNING > 30 SECONDS
-- ----------------------------------------------------------------------------
SELECT '>>> CHECK 1: ACTIVE INNODB TRANSACTIONS > 30 SECONDS' AS '';

SELECT 
    t.trx_id,
    t.trx_mysql_thread_id AS thread_id,
    t.trx_state,
    ROUND(TIME_TO_SEC(TIMEDIFF(NOW(), t.trx_started))) AS elapsed_sec,
    t.trx_rows_locked,
    t.trx_rows_modified,
    LEFT(t.trx_query, 60) AS query_snippet
FROM information_schema.innodb_trx t
WHERE TIME_TO_SEC(TIMEDIFF(NOW(), t.trx_started)) > 30
ORDER BY t.trx_started ASC
LIMIT 10;

-- ----------------------------------------------------------------------------
-- CHECK 2: ACTIVE INNODB LOCK WAITS (WHO BLOCKS WHOM)
-- ----------------------------------------------------------------------------
SELECT '>>> CHECK 2: ACTIVE INNODB LOCK WAITS' AS '';

SELECT 
    waiting_trx_id,
    waiting_pid,
    blocking_trx_id,
    blocking_pid,
    wait_age,
    sql_kill_blocking_query
FROM sys.innodb_lock_waits
LIMIT 10;

-- ----------------------------------------------------------------------------
-- CHECK 3: INNODB BUFFER POOL HIT RATIO
-- Target: > 99%. Under 95% indicates disk thrashing.
-- ----------------------------------------------------------------------------
SELECT '>>> CHECK 3: INNODB BUFFER POOL READ EFFICIENCY' AS '';

SELECT 
    variable_name,
    variable_value
FROM performance_schema.global_status
WHERE variable_name IN (
    'Innodb_buffer_pool_read_requests',
    'Innodb_buffer_pool_reads',
    'Innodb_buffer_pool_pages_dirty'
);

-- ----------------------------------------------------------------------------
-- CHECK 4: TOP 5 STATEMENTS BY TOTAL LATENCY (SYS SCHEMA)
-- ----------------------------------------------------------------------------
SELECT '>>> CHECK 4: TOP STATEMENTS BY TOTAL TIME SPENT' AS '';

SELECT 
    query,
    exec_count,
    total_latency,
    rows_sent_avg,
    rows_examined_avg,
    full_scan
FROM sys.statement_analysis
ORDER BY total_latency DESC
LIMIT 5;

SELECT '================================================================================' AS '';
SELECT ' END OF REPORT - Inspect execution plans with: EXPLAIN ANALYZE <query>;' AS '';
SELECT '================================================================================' AS '';