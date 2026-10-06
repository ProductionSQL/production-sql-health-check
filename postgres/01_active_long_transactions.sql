-- ============================================================================
-- Script:      01_active_long_transactions.sql
-- Product:     The 5-Minute Production SQL Health Check
-- Author:      Production SQL (productionsql.com)
-- Engine:      PostgreSQL 12 - 17+ (AWS RDS, Aurora, Self-Hosted)
-- Safety:      100% Read-Only. Safe under high load.
-- ============================================================================

\timing off
\pset pager off

\echo '>>> CHECK: TRANSACTIONS ACTIVE OR IDLE-IN-TRANSACTION > 30s'
\echo '--------------------------------------------------------------------------------'

SELECT 
    pid,
    usename,
    client_addr,
    application_name,
    state,
    ROUND(EXTRACT(EPOCH FROM (clock_timestamp() - xact_start))::numeric, 1) AS xact_age_sec,
    ROUND(EXTRACT(EPOCH FROM (clock_timestamp() - query_start))::numeric, 1) AS query_age_sec,
    wait_event_type,
    wait_event,
    LEFT(REGEXP_REPLACE(query, '\s+', ' ', 'g'), 75) AS query_snippet
FROM pg_stat_activity
WHERE (
    (state != 'idle' AND (clock_timestamp() - xact_start) > INTERVAL '30 seconds')
    OR 
    (state = 'idle in transaction' AND (clock_timestamp() - state_change) > INTERVAL '30 seconds')
)
ORDER BY xact_start ASC NULLS LAST
LIMIT 10;