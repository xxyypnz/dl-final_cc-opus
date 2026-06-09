-- ===== Commit 112 =====
-- Source:  - 

-- --- Test Case 1 ---
DROP ROLE IF EXISTS c112_role;
CREATE ROLE c112_role LOGIN;
SET ROLE c112_role;
VACUUM pg_catalog.pg_authid;
RESET ROLE;
DROP ROLE IF EXISTS c112_role;

-- --- Test Case 2 ---
DROP ROLE IF EXISTS c112_role2;
CREATE ROLE c112_role2 LOGIN;
SET ROLE c112_role2;
VACUUM (ANALYZE) pg_catalog.pg_authid;
RESET ROLE;
DROP ROLE IF EXISTS c112_role2;

