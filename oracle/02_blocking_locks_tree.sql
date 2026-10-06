-- ============================================================================
-- Script:      02_blocking_locks_tree.sql
-- Product:     The 5-Minute Production SQL Health Check
-- Author:      Production SQL (productionsql.com)
-- Engine:      Oracle 12c - 23c (AWS RDS, Aurora, Self-Hosted)
-- Safety:      100% Read-Only. Safe under high load.
-- ============================================================================

SET PAGESIZE 50
SET LINESIZE 220
SET FEEDBACK OFF
SET TIMING OFF
SET TRIMSPOOL ON

COL blocker FORMAT a18 HEAD "Blocker (SID,Ser#)"
COL blocker_user FORMAT a16 HEAD "Blocker User"
COL blocked FORMAT a18 HEAD "Blocked (SID,Ser#)"
COL blocked_user FORMAT a16 HEAD "Blocked User"
COL sql_id FORMAT a13 HEAD "Blocked SQL_ID"
COL seconds_in_wait FORMAT 999,990 HEAD "Wait (s)"
COL wait_event FORMAT a32 HEAD "Wait Event"

PROMPT >>> CHECK: ACTIVE BLOCKING LOCK CHAINS (WHO BLOCKS WHOM)
PROMPT --------------------------------------------------------------------------------

SELECT 
    b.sid || ',' || b.serial# AS blocker,
    b.username AS blocker_user,
    w.sid || ',' || w.serial# AS blocked,
    w.username AS blocked_user,
    w.sql_id,
    w.seconds_in_wait,
    w.event AS wait_event
FROM v$session w
JOIN v$session b ON w.blocking_session = b.sid
WHERE w.blocking_session IS NOT NULL
ORDER BY w.seconds_in_wait DESC;

SET FEEDBACK ON