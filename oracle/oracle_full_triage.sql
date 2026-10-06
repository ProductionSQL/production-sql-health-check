-- ============================================================================
-- Script:      oracle_full_triage.sql
-- Product:     The 5-Minute Production SQL Health Check
-- Author:      Production SQL (productionsql.com)
-- Compatibility: Oracle 12c, 19c, 21c, 23c (Self-Hosted, EC2, AWS RDS/Aurora)
-- Safety:      100% Read-Only. Minimal dynamic view queries. Safe under high load.
-- ============================================================================

SET PAGESIZE 50
SET LINESIZE 220
SET FEEDBACK OFF
SET TIMING OFF
SET TRIMSPOOL ON
SET TAB OFF

CLEAR COLUMNS
CLEAR BREAKS

COL event FORMAT a35 HEAD "Wait Event"
COL wait_class FORMAT a16 HEAD "Wait Class"
COL total_waits FORMAT 999,999,999 HEAD "Total Waits"
COL time_waited_sec FORMAT 999,999,990 HEAD "Time Waited (s)"
COL avg_wait_ms FORMAT 99,990.99 HEAD "Avg Wait (ms)"

PROMPT ================================================================================
PROMPT  PRODUCTION SQL: 5-MINUTE ORACLE TRIAGE REPORT
PROMPT  Timestamp: &_DATE
PROMPT ================================================================================
PROMPT

-- ----------------------------------------------------------------------------
-- CHECK 1: TOP 10 NON-IDLE WAIT EVENTS
-- Identifies the primary bottleneck across the instance since startup.
-- ----------------------------------------------------------------------------
PROMPT >>> CHECK 1: TOP 10 NON-IDLE WAIT EVENTS (SYSTEM-WIDE)
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

PROMPT

-- ----------------------------------------------------------------------------
-- CHECK 2: ACTIVE BLOCKING LOCK CHAINS
-- Shows root blocking sessions, who they are blocking, wait times, and SQL IDs.
-- ----------------------------------------------------------------------------
PROMPT >>> CHECK 2: ACTIVE BLOCKING LOCK TREE (WHO IS BLOCKING WHOM)
PROMPT --------------------------------------------------------------------------------

COL blocker FORMAT a18 HEAD "Blocker (SID,Ser#)"
COL blocked FORMAT a18 HEAD "Blocked (SID,Ser#)"
COL blocker_user FORMAT a14 HEAD "Blocker User"
COL blocked_user FORMAT a14 HEAD "Blocked User"
COL sql_id FORMAT a13 HEAD "Blocked SQL_ID"
COL seconds_in_wait FORMAT 999,990 HEAD "Wait (s)"
COL wait_event FORMAT a30 HEAD "Wait Event"

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

PROMPT

-- ----------------------------------------------------------------------------
-- CHECK 3: CURRENT ACTIVE SESSIONS (BURNING CPU OR WAITING)
-- Snapshots all active user foreground processes right now.
-- ----------------------------------------------------------------------------
PROMPT >>> CHECK 3: CURRENT FOREGROUND SESSIONS RUNNING / WAITING
PROMPT --------------------------------------------------------------------------------

COL sid_ser FORMAT a14 HEAD "SID,Serial#"
COL username FORMAT a14 HEAD "User"
COL status FORMAT a8 HEAD "Status"
COL sql_id FORMAT a13 HEAD "Current SQL"
COL prev_sql_id FORMAT a13 HEAD "Prev SQL"
COL state FORMAT a14 HEAD "State"
COL machine FORMAT a20 TRUNC HEAD "Client Machine"
COL program FORMAT a22 TRUNC HEAD "Program"
COL elapsed_sec FORMAT 999,990 HEAD "Active (s)"

SELECT 
    s.sid || ',' || s.serial# AS sid_ser,
    s.username,
    s.status,
    s.sql_id,
    s.prev_sql_id,
    s.event,
    ROUND(s.last_call_et) AS elapsed_sec,
    s.machine,
    s.program
FROM v$session s
WHERE s.type = 'USER'
  AND s.status = 'ACTIVE'
  AND s.wait_class != 'Idle'
ORDER BY s.last_call_et DESC;

PROMPT

-- ----------------------------------------------------------------------------
-- CHECK 4: RUNAWAY TEMP TABLESPACE USAGE
-- Pinpoints disk sorting and hash join spills causing Ora-01652 errors.
-- ----------------------------------------------------------------------------
PROMPT >>> CHECK 4: RUNAWAY TEMP USAGE BY SESSION
PROMPT --------------------------------------------------------------------------------

COL tablespace FORMAT a15 HEAD "Tablespace"
COL temp_mb FORMAT 999,999,990.99 HEAD "Temp Used (MB)"

SELECT 
    s.sid || ',' || s.serial# AS sid_ser,
    s.username,
    s.sql_id,
    u.tablespace,
    ROUND((u.blocks * dt.block_size) / (1024 * 1024), 2) AS temp_mb
FROM v$sort_usage u
JOIN v$session s ON u.session_addr = s.saddr
JOIN dba_tablespaces dt ON u.tablespace = dt.tablespace_name
WHERE ROWNUM <= 10
ORDER BY u.blocks DESC;

PROMPT

-- ----------------------------------------------------------------------------
-- CHECK 5: HIGH-LOAD SQL BY BUFFER GETS & DISK READS (LAST EXECUTIONS)
-- Identifies queries lacking proper indexing or driving high AWS RDS IOPS.
-- ----------------------------------------------------------------------------
PROMPT >>> CHECK 5: TOP 5 QUERIES CONSUMING MEMORY/DISK IOPS
PROMPT --------------------------------------------------------------------------------

COL sql_id FORMAT a13 HEAD "SQL ID"
COL executions FORMAT 999,999,999 HEAD "Executions"
COL buffer_gets_per_exec FORMAT 999,999,990 HEAD "Buffers/Exec"
COL disk_reads_per_exec FORMAT 999,999,990 HEAD "Disk Reads/Exec"
COL cpu_sec_per_exec FORMAT 9,990.999 HEAD "CPU(s)/Exec"
COL sql_text_short FORMAT a45 TRUNC HEAD "SQL Snippet"

SELECT *
FROM (
    SELECT 
        sql_id,
        executions,
        ROUND(buffer_gets / NULLIF(executions, 0)) AS buffer_gets_per_exec,
        ROUND(disk_reads / NULLIF(executions, 0)) AS disk_reads_per_exec,
        ROUND((cpu_time / 1000000) / NULLIF(executions, 0), 3) AS cpu_sec_per_exec,
        REPLACE(REPLACE(SUBSTR(sql_text, 1, 45), CHR(10), ' '), CHR(13), ' ') AS sql_text_short
    FROM v$sqlstats
    WHERE executions > 0
    ORDER BY buffer_gets DESC
)
WHERE ROWNUM <= 5;

PROMPT
PROMPT ================================================================================
PROMPT  END OF REPORT - For detailed execution plan diagnosis, run:
PROMPT  SELECT * FROM table(DBMS_XPLAN.DISPLAY_CURSOR('sql_id', NULL, 'ALLSTATS LAST'));
PROMPT ================================================================================
PROMPT

SET FEEDBACK ON