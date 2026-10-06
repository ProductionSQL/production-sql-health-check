-- ============================================================================
-- Script:      02_lock_contention_tree.sql
-- Product:     The 5-Minute Production SQL Health Check
-- Author:      Production SQL (productionsql.com)
-- Engine:      PostgreSQL 12 - 17+ (AWS RDS, Aurora, Self-Hosted)
-- Safety:      100% Read-Only. Safe under high load.
-- ============================================================================

\timing off
\pset pager off

\echo '>>> CHECK: ACTIVE LOCK CONTENTION TREE (BLOCKING VS BLOCKED)'
\echo '--------------------------------------------------------------------------------'

SELECT 
    blocked.pid AS blocked_pid,
    blocked.usename AS blocked_user,
    blocked.state AS blocked_state,
    UNNEST(pg_blocking_pids(blocked.pid)) AS blocker_pid,
    ROUND(EXTRACT(EPOCH FROM (clock_timestamp() - blocked.state_change))::numeric, 1) AS wait_sec,
    blocked.wait_event_type,
    blocked.wait_event,
    LEFT(REGEXP_REPLACE(blocked.query, '\s+', ' ', 'g'), 60) AS blocked_query
FROM pg_stat_activity blocked
WHERE CARDINALITY(pg_blocking_pids(blocked.pid)) > 0
ORDER BY wait_sec DESC
LIMIT 15;