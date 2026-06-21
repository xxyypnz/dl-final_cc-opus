-- ===== Commit 133 =====
-- Source:  - 

-- --- Test Case 1 ---
SELECT COUNT(*) FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='pg_catalog';
SELECT COUNT(*) FROM pg_proc WHERE pronamespace='pg_catalog'::regnamespace;
SELECT COUNT(*) FROM pg_type WHERE typnamespace='pg_catalog'::regnamespace;

-- --- Test Case 2 ---
DROP TABLE IF EXISTS c133_t1 CASCADE;
CREATE TABLE c133_t1 (id oid, val text);
INSERT INTO c133_t1 SELECT oid, relname FROM pg_class WHERE relkind='r' LIMIT 20;
SELECT COUNT(DISTINCT id) FROM c133_t1;
SELECT * FROM c133_t1 WHERE id = (SELECT min(oid) FROM pg_class WHERE relkind='r');
DROP TABLE IF EXISTS c133_t1 CASCADE;

