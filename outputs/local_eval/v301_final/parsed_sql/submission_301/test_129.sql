-- ===== Commit 129 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
SET work_mem = '64kB';
DROP TABLE IF EXISTS test_wide CASCADE;
CREATE TABLE test_wide (id INT, data text);
INSERT INTO test_wide SELECT generate_series(1, 100), repeat('x', 10000);

-- Execution: Hash join with large tuples and small work_mem
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF) SELECT * FROM test_wide a JOIN test_wide b ON a.id = b.id;

-- Teardown
DROP TABLE IF EXISTS test_wide CASCADE;
RESET work_mem;

-- --- Test Case 2 ---
-- Setup
SET work_mem = '64kB';
DROP TABLE IF EXISTS test_wide2 CASCADE;
CREATE TABLE test_wide2 (id INT, data text);
INSERT INTO test_wide2 SELECT generate_series(1, 50), repeat('y', 20000);

-- Execution: Hash join with very large tuples
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF) SELECT * FROM test_wide2 a JOIN test_wide2 b ON a.id = b.id;

-- Teardown
DROP TABLE IF EXISTS test_wide2 CASCADE;
RESET work_mem;

-- --- Test Case 3 ---
-- Setup
SET work_mem = '64kB';
DROP TABLE IF EXISTS test_single_wide CASCADE;
CREATE TABLE test_single_wide (id INT, data text);
INSERT INTO test_single_wide VALUES (1, repeat('z', 50000));

-- Execution: Hash join with single very wide row
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF) SELECT * FROM test_single_wide a JOIN test_single_wide b ON a.id = b.id;

-- Teardown
DROP TABLE IF EXISTS test_single_wide CASCADE;
RESET work_mem;

-- --- Test Case 4 ---
SET work_mem = '64kB'; SET enable_nestloop = off; SET enable_mergejoin = off; DROP TABLE IF EXISTS c129_wide CASCADE; CREATE TABLE c129_wide (id int, payload char(90000)); INSERT INTO c129_wide SELECT g, 'x' FROM generate_series(1, 3) g; SELECT count(a.payload), count(b.payload) FROM c129_wide a JOIN c129_wide b ON a.id = b.id; DROP TABLE IF EXISTS c129_wide CASCADE; RESET work_mem; RESET enable_nestloop; RESET enable_mergejoin;

-- --- Test Case 5 ---
DROP TABLE IF EXISTS c129_large, c129_small CASCADE;
CREATE TABLE c129_large AS
  SELECT i AS id, md5(i::text) AS data FROM generate_series(1, 5000) i;
CREATE TABLE c129_small AS
  SELECT i AS id, md5(i::text) AS data FROM generate_series(1, 2500) i;
ANALYZE c129_large, c129_small;
SET work_mem = '1MB';
SET enable_hashjoin = on;
SET enable_mergejoin = off;
SET enable_nestloop = off;
EXPLAIN ANALYZE
  SELECT COUNT(*) FROM c129_large JOIN c129_small USING (id);
RESET work_mem;
RESET enable_hashjoin;
RESET enable_mergejoin;
RESET enable_nestloop;
DROP TABLE c129_large, c129_small CASCADE;

-- --- Test Case 6 ---
DROP TABLE IF EXISTS c129_h1, c129_h2 CASCADE;
CREATE TABLE c129_h1(x int, y text);
CREATE TABLE c129_h2(x int, z text);
INSERT INTO c129_h1 SELECT i, 'row'||i FROM generate_series(1,1000) i;
INSERT INTO c129_h2 SELECT i, 'col'||i FROM generate_series(1,800) i;
ANALYZE c129_h1, c129_h2;
SET enable_hashjoin = on;
SET enable_mergejoin = off;
SET enable_nestloop = off;
EXPLAIN ANALYZE
  SELECT COUNT(*) FROM c129_h1 JOIN c129_h2 ON c129_h1.x = c129_h2.x;
RESET enable_hashjoin;
RESET enable_mergejoin;
RESET enable_nestloop;
DROP TABLE c129_h1, c129_h2 CASCADE;

