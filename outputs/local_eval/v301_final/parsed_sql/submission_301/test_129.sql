-- ===== Commit 129 =====
-- Source:  - 

-- --- Test Case 1 ---
DROP TABLE IF EXISTS c129_large, c129_small CASCADE;
CREATE TABLE c129_large AS SELECT i AS id, md5(i::text) AS data FROM generate_series(1, 5000) i;
CREATE TABLE c129_small AS SELECT i AS id, md5(i::text) AS data FROM generate_series(1, 2500) i;
ANALYZE c129_large, c129_small;
SET work_mem = '1MB';
SET enable_hashjoin = on;
SET enable_mergejoin = off;
SET enable_nestloop = off;
SELECT COUNT(*) FROM c129_large JOIN c129_small ON c129_large.id = c129_small.id;
RESET work_mem;
RESET enable_hashjoin;
RESET enable_mergejoin;
RESET enable_nestloop;
DROP TABLE c129_large, c129_small CASCADE;

-- --- Test Case 2 ---
DROP TABLE IF EXISTS c129_h1, c129_h2 CASCADE;
CREATE TABLE c129_h1(x int, y text);
CREATE TABLE c129_h2(x int, z text);
INSERT INTO c129_h1 SELECT i, 'row'||i FROM generate_series(1,1000) i;
INSERT INTO c129_h2 SELECT i, 'col'||i FROM generate_series(1,800) i;
ANALYZE c129_h1, c129_h2;
SET enable_hashjoin = on;
SELECT COUNT(*) FROM c129_h1 JOIN c129_h2 ON c129_h1.x = c129_h2.x;
RESET enable_hashjoin;
DROP TABLE c129_h1, c129_h2 CASCADE;

