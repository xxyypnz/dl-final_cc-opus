-- ===== Commit 122 =====
-- Source:  - 

-- --- Test Case 1 ---
DROP TABLE IF EXISTS c122_agg1 CASCADE;
CREATE TABLE c122_agg1 (id int, arr int[]);
INSERT INTO c122_agg1 SELECT i, ARRAY[i, i+1, i+2] FROM generate_series(1,20) i;
SELECT id, array_agg(arr) FROM c122_agg1 GROUP BY id ORDER BY id LIMIT 5;
DROP TABLE IF EXISTS c122_agg1 CASCADE;

-- --- Test Case 2 ---
DROP TABLE IF EXISTS c122_agg2 CASCADE;
CREATE TABLE c122_agg2 (grp int, val jsonb);
INSERT INTO c122_agg2 SELECT i%5, jsonb_build_object('k', i) FROM generate_series(1,50) i;
SELECT grp, jsonb_agg(val ORDER BY (val->>'k')::int) FROM c122_agg2 GROUP BY grp ORDER BY grp;
DROP TABLE IF EXISTS c122_agg2 CASCADE;

-- --- Test Case 3 ---
DROP TYPE IF EXISTS c122_comp CASCADE;
CREATE TYPE c122_comp AS (x int, y text);
DROP TABLE IF EXISTS c122_agg3 CASCADE;
CREATE TABLE c122_agg3 (grp int, v c122_comp);
INSERT INTO c122_agg3 SELECT i%3, ROW(i, i::text)::c122_comp FROM generate_series(1,30) i;
SELECT grp, count(*), array_agg(v) FROM c122_agg3 GROUP BY grp ORDER BY grp;
DROP TABLE IF EXISTS c122_agg3 CASCADE;
DROP TYPE IF EXISTS c122_comp CASCADE;

