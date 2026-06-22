-- ===== Commit 150 =====
-- Source:  - 

-- --- Test Case 1 ---
SELECT 1;

-- --- Test Case 2 ---
DROP TABLE IF EXISTS c112_late_owned CASCADE;
DROP ROLE IF EXISTS c112_late_owner;
CREATE ROLE c112_late_owner;
CREATE TABLE c112_late_owned (id int);
INSERT INTO c112_late_owned VALUES (1);
ALTER TABLE c112_late_owned OWNER TO c112_late_owner;
ALTER DATABASE regression OWNER TO c112_late_owner;
ALTER ROLE CURRENT_USER NOSUPERUSER;
VACUUM c112_late_owned;
VACUUM pg_catalog.pg_authid;
ANALYZE c112_late_owned;
ANALYZE pg_catalog.pg_authid;

