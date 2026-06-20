-- ===== Commit 122 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup: Create a table with an array type (pass-by-ref) to trigger expanded datum handling
DROP TABLE IF EXISTS test_agg1 CASCADE;
CREATE TABLE test_agg1 (id INT, arr INT[]);
INSERT INTO test_agg1 VALUES (1, ARRAY[1,2,3]), (2, ARRAY[4,5,6]);

-- Execution: Use array_agg which has no finalfn, returns pass-by-ref result
SELECT id, array_agg(arr) FROM test_agg1 GROUP BY id;

-- Teardown
DROP TABLE IF EXISTS test_agg1 CASCADE;

-- --- Test Case 2 ---
-- Setup: Create a table with text type (pass-by-ref) and use string_agg which has no finalfn
DROP TABLE IF EXISTS test_agg2 CASCADE;
CREATE TABLE test_agg2 (id INT, val TEXT);
INSERT INTO test_agg2 VALUES (1, 'a'), (1, 'b'), (2, 'c');

-- Execution: Use string_agg with partial aggregation (enable hashagg if needed)
SET enable_hashagg = on;
SELECT id, string_agg(val, ',') FROM test_agg2 GROUP BY id;
RESET enable_hashagg;

-- Teardown
DROP TABLE IF EXISTS test_agg2 CASCADE;

-- --- Test Case 3 ---
-- Setup: Create a table with nullable integer and use an aggregate that can produce NULL transition values
DROP TABLE IF EXISTS test_agg3 CASCADE;
CREATE TABLE test_agg3 (id INT, val INT);
INSERT INTO test_agg3 VALUES (1, NULL), (1, 10), (2, NULL);

-- Execution: Use avg() which has a finalfn, but the transition value may be null for groups with all nulls
SELECT id, avg(val) FROM test_agg3 GROUP BY id;

-- Teardown
DROP TABLE IF EXISTS test_agg3 CASCADE;

-- --- Test Case 4 ---
DROP TABLE IF EXISTS c122_t CASCADE;
CREATE TABLE c122_t (id int, v numeric);
INSERT INTO c122_t VALUES (1,10.5),(1,20.5),(2,3.3),(2,4.4);
SELECT id, avg(v), array_agg(v) FROM c122_t GROUP BY id ORDER BY id;
DROP TABLE IF EXISTS c122_t CASCADE;

-- --- Test Case 5 ---
DROP TABLE IF EXISTS c122_agg1 CASCADE;
CREATE TABLE c122_agg1 (id int, arr int[]);
INSERT INTO c122_agg1 SELECT i, ARRAY[i, i+1, i+2] FROM generate_series(1,20) i;
SELECT id, array_agg(arr) FROM c122_agg1 GROUP BY id ORDER BY id LIMIT 5;
DROP TABLE IF EXISTS c122_agg1 CASCADE;

-- --- Test Case 6 ---
DROP TABLE IF EXISTS c122_agg2 CASCADE;
CREATE TABLE c122_agg2 (grp int, val jsonb);
INSERT INTO c122_agg2 SELECT i%5, jsonb_build_object('k', i) FROM generate_series(1,50) i;
SELECT grp, jsonb_agg(val ORDER BY (val->>'k')::int) FROM c122_agg2 GROUP BY grp ORDER BY grp;
DROP TABLE IF EXISTS c122_agg2 CASCADE;

-- --- Test Case 7 ---
DROP TYPE IF EXISTS c122_comp CASCADE;
CREATE TYPE c122_comp AS (x int, y text);
DROP TABLE IF EXISTS c122_agg3 CASCADE;
CREATE TABLE c122_agg3 (grp int, v c122_comp);
INSERT INTO c122_agg3 SELECT i%3, ROW(i, i::text)::c122_comp FROM generate_series(1,30) i;
SELECT grp, count(*), array_agg(v) FROM c122_agg3 GROUP BY grp ORDER BY grp;
DROP TABLE IF EXISTS c122_agg3 CASCADE;
DROP TYPE IF EXISTS c122_comp CASCADE;

