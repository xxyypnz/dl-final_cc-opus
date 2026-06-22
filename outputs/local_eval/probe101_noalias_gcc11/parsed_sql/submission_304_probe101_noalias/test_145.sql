-- ===== Commit 145 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS test_reorder CASCADE;
CREATE TABLE test_reorder (id INT, val TEXT);
INSERT INTO test_reorder SELECT generate_series(1, 100), 'data' || generate_series(1, 100);
CREATE INDEX idx_test_reorder ON test_reorder (id);

-- Execution: Use an index scan with reordering (e.g., ORDER BY) and then rescan via a cursor or multiple executions
BEGIN;
DECLARE c CURSOR FOR SELECT * FROM test_reorder ORDER BY id;
FETCH 10 FROM c;
FETCH 10 FROM c;  -- This triggers a rescan of the index scan
CLOSE c;
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_reorder CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS test_empty CASCADE;
CREATE TABLE test_empty (id INT, val TEXT);
CREATE INDEX idx_test_empty ON test_empty (id);

-- Execution: Use an index scan with reordering on empty table, then rescan
BEGIN;
DECLARE c CURSOR FOR SELECT * FROM test_empty ORDER BY id;
FETCH 1 FROM c;  -- No rows, but rescan still occurs
CLOSE c;
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_empty CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS test_dup CASCADE;
CREATE TABLE test_dup (id INT, val TEXT);
INSERT INTO test_dup VALUES (1, 'a'), (1, 'b'), (2, 'c'), (2, 'd');
CREATE INDEX idx_test_dup ON test_dup (id);

-- Execution: Use an index scan with reordering and rescan to trigger the fix
BEGIN;
DECLARE c CURSOR FOR SELECT * FROM test_dup ORDER BY id;
FETCH 2 FROM c;
FETCH 2 FROM c;  -- Rescan after partial fetch
CLOSE c;
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_dup CASCADE;

-- --- Test Case 4 ---
DROP TABLE IF EXISTS c145_poly CASCADE;
DROP TABLE IF EXISTS c145_outer CASCADE;
CREATE TABLE c145_poly (id int, p polygon);
INSERT INTO c145_poly
  SELECT g,
         ('((' || g || ',' || g || '),('
               || (g+50) || ',' || (g+50) || '),('
               || (g+1)  || ',' || g || '))')::polygon
  FROM generate_series(1,1000) AS g;
CREATE INDEX c145_poly_gist ON c145_poly USING gist (p);
CREATE TABLE c145_outer (qx int);
INSERT INTO c145_outer VALUES (10),(50),(200),(400);
SET enable_seqscan = off;
SET enable_material = off;
SELECT o.qx, count(l.id)
FROM c145_outer o
CROSS JOIN LATERAL (
  SELECT id
  FROM c145_poly
  ORDER BY p <-> point(o.qx + 50, o.qx)
  LIMIT 3
) l
GROUP BY o.qx
ORDER BY o.qx;
RESET enable_seqscan;
RESET enable_material;
DROP TABLE c145_outer;
DROP TABLE c145_poly;

