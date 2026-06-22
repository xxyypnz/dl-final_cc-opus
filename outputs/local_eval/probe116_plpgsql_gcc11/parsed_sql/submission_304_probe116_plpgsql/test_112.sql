-- ===== Commit 112 =====
-- Source:  - 

-- --- Test Case 1 ---
DROP TABLE IF EXISTS c112_vac CASCADE;
CREATE TABLE c112_vac (id int);
INSERT INTO c112_vac SELECT generate_series(1,100);
VACUUM c112_vac;
ANALYZE c112_vac;
VACUUM (ANALYZE) c112_vac;
DROP TABLE IF EXISTS c112_vac CASCADE;

-- --- Test Case 2 ---
VACUUM pg_catalog.pg_class;
ANALYZE pg_catalog.pg_class;
VACUUM (ANALYZE) pg_catalog.pg_class;

