-- ===== Commit 149 =====
-- Source:  - 

-- --- Test Case 1 ---
DROP VIEW IF EXISTS c149_vw1 CASCADE;
CREATE VIEW c149_vw1 AS SELECT t.* FROM (SELECT 1 AS id, 'x'::text AS val) t;
SELECT pg_get_viewdef('c149_vw1'::regclass, true);
DROP VIEW IF EXISTS c149_vw1 CASCADE;

-- --- Test Case 2 ---
DROP TABLE IF EXISTS c149_t1 CASCADE;
DROP TABLE IF EXISTS c149_t2 CASCADE;
CREATE TABLE c149_t1 (id int, v text);
CREATE TABLE c149_t2 (id int, w int);
INSERT INTO c149_t1 VALUES (1,'a'),(2,'b');
INSERT INTO c149_t2 VALUES (1,10),(2,20);
DROP VIEW IF EXISTS c149_vw2 CASCADE;
CREATE VIEW c149_vw2 AS SELECT t1.*, t2.w FROM c149_t1 t1 JOIN c149_t2 t2 ON t1.id=t2.id;
SELECT pg_get_viewdef('c149_vw2'::regclass, true);
DROP VIEW IF EXISTS c149_vw2 CASCADE;
DROP TABLE IF EXISTS c149_t1 CASCADE;
DROP TABLE IF EXISTS c149_t2 CASCADE;

