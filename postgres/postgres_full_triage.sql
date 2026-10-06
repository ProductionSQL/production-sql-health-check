-- ============================================================================
-- Script:      postgres_full_triage.sql
-- Product:     The 5-Minute Production SQL Health Check
-- Author:      Production SQL (productionsql.com)
-- Compatibility: PostgreSQL 12 through 17+ (Self-Hosted, AWS RDS / Aurora)
-- Safety:      100% Read-Only. Strict row limits. Zero locking overhead.
-- ============================================================================

\timing off
\pset pager off

\echo '================================================================================'
\echo ' PRODUCTION SQL: 5-MINUTE POSTGRESQL TRIAGE REPORT'
\echo '================================================================================'
\echo ''

-- ----------------------------------------------------------------------------
-- CHECK 1: TRANSACTIONS ACTIVE LONGER THAN 30 SECONDS
-- ----------------------------------------------------------------------------
\echo '>>> CHECK 1: TRANSACTIONS ACTIVE OR IDLE-IN-TRANSACTION > 30s'
\echo '--------------------------------------------------------------------------------'

SELECT 
    pid,
    usename,
    client_addr,
    application_name,
    state,
    ROUND(EXTRACT(EPOCH FROM (clock_timestamp() - xact_start))::numeric, 1) AS xact_age_sec,
    wait_event_type,
    wait_event,
    LEFT(REGEXP_REPLACE(query, '\s+', ' ', 'g'), 60) AS query_snippet
FROM pg_stat_activity
WHERE (
    (state != 'idle' AND (clock_timestamp() - xact_start) > INTERVAL '30 seconds')
    OR 
    (state = 'idle in transaction' AND (clock_timestamp() - state_change) > INTERVAL '30 seconds')
)
ORDER BY xact_start ASC NULLS LAST
LIMIT 10;

\echo ''

-- ----------------------------------------------------------------------------
-- CHECK 2: LOCK CONTENTION TREE
-- ----------------------------------------------------------------------------
\echo '>>> CHECK 2: ACTIVE LOCK CONTENTION TREE'
\echo '--------------------------------------------------------------------------------'

SELECT 
    blocked.pid AS blocked_pid,
    blocked.usename AS blocked_user,
    UNNEST(pg_blocking_pids(blocked.pid)) AS blocker_pid,
    ROUND(EXTRACT(EPOCH FROM (clock_timestamp() - blocked.state_change))::numeric, 1) AS wait_sec,
    blocked.wait_event_type,
    blocked.wait_event,
    LEFT(REGEXP_REPLACE(blocked.query, '\s+', ' ', 'g'), 50) AS blocked_query
FROM pg_stat_activity blocked
WHERE CARDINALITY(pg_blocking_pids(blocked.pid)) > 0
ORDER BY wait_sec DESC
LIMIT 10;

\echo ''

-- ----------------------------------------------------------------------------
-- CHECK 3: BUFFER CACHE HIT RATIO
-- ----------------------------------------------------------------------------
\echo '>>> CHECK 3: BUFFER CACHE HIT RATIO'
\echo '--------------------------------------------------------------------------------'

SELECT 
    ROUND(
        SUM(heap_blks_hit) * 100.0 / NULLIF(SUM(heap_blks_hit + heap_blks_read), 0), 2
    ) AS buffer_cache_hit_pct
FROM pg_statio_user_tables;

\echo ''

-- ----------------------------------------------------------------------------
-- CHECK 4: DEAD TUPLE RATIO (BLOAT WARNING)
-- ----------------------------------------------------------------------------
\echo '>>> CHECK 4: TOP 5 TABLES BY DEAD TUPLE RATIO'
\echo '--------------------------------------------------------------------------------'

SELECT 
    schemaname || '.' || relname AS table_name,
    n_live_tup,
    n_dead_tup,
    ROUND((n_dead_tup * 100.0 / NULLIF(n_live_tup + n_dead_tup, 0))::numeric, 2) AS dead_pct,
    last_autovacuum
FROM pg_stat_user_tables
WHERE (n_live_tup + n_dead_tup) > 1000
ORDER BY n_dead_tup DESC
LIMIT 5;

\echo ''
\echo '================================================================================'
\echo ' END OF REPORT - To inspect execution plans, run:'
\echo ' EXPLAIN (ANALYZE, BUFFERS) <query>;'
\echo '================================================================================'
\echo ''