-- ============================================================================
-- Script:      01_top_wait_events.sql
-- Product:     The 5-Minute Production SQL Health Check
-- Author:      Production SQL (productionsql.com)
-- Engine:      Oracle 12c - 23c (AWS RDS, Aurora, Self-Hosted)
-- Safety:      100% Read-Only. Safe under high load.
-- ============================================================================

SET PAGESIZE 50
SET LINESIZE 200
SET FEEDBACK OFF
SET TIMING OFF
SET TRIMSPOOL ON

COL event FORMAT a40 HEAD "Wait Event"
COL wait_class FORMAT a18 HEAD "Wait Class"
COL total_waits FORMAT 999,999,999 HEAD "Total Waits"
COL time_waited_sec FORMAT 999,999,990 HEAD "Time Waited (s)"
COL avg_wait_ms FORMAT 99,990.99 HEAD "Avg Wait (ms)"

PROMPT >>> CHECK: TOP 10 NON-IDLE SYSTEM WAIT EVENTS
PROMPT --------------------------------------------------------------------------------

SELECT *
FROM (
    SELECT 
        event,
        wait_class,
        total_waits,
        ROUND(time_waited_micro / 1000000) AS time_waited_sec,
        ROUND(time_waited_micro / NULLIF(total_waits * 1000, 0), 2) AS avg_wait_ms
    FROM v$system_event
    WHERE wait_class != 'Idle'
    ORDER BY time_waited_micro DESC
)
WHERE ROWNUM <= 10;

SET FEEDBACK ON