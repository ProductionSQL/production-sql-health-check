-- ============================================================================
-- Script:      03_cache_hit_and_bloat.sql
-- Product:     The 5-Minute Production SQL Health Check
-- Author:      Production SQL (productionsql.com)
-- Engine:      PostgreSQL 12 - 17+ (AWS RDS, Aurora, Self-Hosted)
-- Safety:      100% Read-Only. Aggressive row limits.
-- ============================================================================

\timing off
\pset pager off

\echo '>>> CHECK A: BUFFER CACHE HIT RATIO'
\echo '--------------------------------------------------------------------------------'

SELECT 
    ROUND(
        SUM(heap_blks_hit) * 100.0 / NULLIF(SUM(heap_blks_hit + heap_blks_read), 0), 2
    ) AS buffer_cache_hit_pct
FROM pg_statio_user_tables;

\echo ''
\echo '>>> CHECK B: TOP 10 TABLES BY DEAD TUPLE RATIO (BLOAT WARNING)'
\echo '--------------------------------------------------------------------------------'

SELECT 
    schemaname || '.' || relname AS table_name,
    n_live_tup,
    n_dead_tup,
    ROUND((n_dead_tup * 100.0 / NULLIF(n_live_tup + n_dead_tup, 0))::numeric, 2) AS dead_pct,
    last_autovacuum,
    last_autoanalyze
FROM pg_stat_user_tables
WHERE (n_live_tup + n_dead_tup) > 1000
ORDER BY n_dead_tup DESC
LIMIT 10;