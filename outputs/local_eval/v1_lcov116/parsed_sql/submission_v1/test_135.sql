-- ===== Commit 135 =====
-- Source:  - 

-- --- Test Case 1 ---
DROP VIEW IF EXISTS c135_setop_v CASCADE;
CREATE VIEW c135_setop_v AS SELECT 1+1 UNION ALL SELECT 2+2;
SELECT pg_get_viewdef('c135_setop_v'::regclass, true);
DROP VIEW IF EXISTS c135_setop_v CASCADE;

-- --- Test Case 2 ---
DROP VIEW IF EXISTS c135_setop_v2 CASCADE;
DROP TABLE IF EXISTS c135_t CASCADE;
CREATE TABLE c135_t (a int);
INSERT INTO c135_t VALUES (1);
CREATE VIEW c135_setop_v2 AS SELECT a+1 FROM c135_t UNION SELECT a*2 FROM c135_t ORDER BY 1;
SELECT pg_get_viewdef('c135_setop_v2'::regclass, true);
DROP VIEW IF EXISTS c135_setop_v2 CASCADE;
DROP TABLE IF EXISTS c135_t CASCADE;

