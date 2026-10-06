-- ============================================================================
-- Script:      03_runaway_temp_pga.sql
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

COL sid_ser FORMAT a16 HEAD "SID,Serial#"
COL username FORMAT a16 HEAD "Username"
COL sql_id FORMAT a13 HEAD "Current SQL_ID"
COL tablespace FORMAT a18 HEAD "Tablespace"
COL temp_mb FORMAT 999,999,990.99 HEAD "Temp Used (MB)"

PROMPT >>> CHECK: TOP 10 RUNAWAY TEMP TABLESPACE CONSUMERS
PROMPT --------------------------------------------------------------------------------

SELECT *
FROM (
    SELECT 
        s.sid || ',' || s.serial# AS sid_ser,
        s.username,
        s.sql_id,
        u.tablespace,
        ROUND((u.blocks * dt.block_size) / (1024 * 1024), 2) AS temp_mb
    FROM v$sort_usage u
    JOIN v$session s ON u.session_addr = s.saddr
    JOIN dba_tablespaces dt ON u.tablespace = dt.tablespace_name
    ORDER BY u.blocks DESC
)
WHERE ROWNUM <= 10;

SET FEEDBACK ON