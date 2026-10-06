-- ============================================================================
-- Script:      02_high_iops_queries.sql
-- Product:     The 5-Minute Production SQL Health Check
-- Author:      Production SQL (productionsql.com)
-- Engine:      MySQL 5.7, 8.0, 8.4+ (AWS RDS, Aurora, Self-Hosted)
-- Safety:      100% Read-Only. Safe under high load.
-- ============================================================================

SELECT '>>> CHECK: TOP 10 STATEMENTS BY TOTAL EXECUTION LATENCY & FULL SCANS' AS '';

SELECT 
    query,
    exec_count,
    total_latency,
    rows_sent_avg,
    rows_examined_avg,
    full_scan
FROM sys.statement_analysis
ORDER BY total_latency DESC
LIMIT 10;