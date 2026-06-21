-- ===== Commit 135 =====
-- Source:  - 

-- --- Test Case 1 ---
DROP TABLE IF EXISTS c135_noname CASCADE;
CREATE TABLE c135_noname (id int, val text);
INSERT INTO c135_noname VALUES (1,'a'),(2,'b');
SELECT id+0, val||'' FROM c135_noname ORDER BY 1;
SELECT 1+1, 'hello'||' '||'world';
SELECT CASE WHEN id > 1 THEN 'big' ELSE 'small' END FROM c135_noname;
DROP TABLE IF EXISTS c135_noname CASCADE;

-- --- Test Case 2 ---
DROP VIEW IF EXISTS c135_v1 CASCADE;
CREATE VIEW c135_v1 AS SELECT 1+1 AS result, now() AS ts, 'str'||'cat' AS s;
SELECT pg_get_viewdef('c135_v1'::regclass, true);
DROP VIEW IF EXISTS c135_v1 CASCADE;

-- --- Test Case 3 ---
SELECT 1+2, 'a'||'b', length('test'), upper('hello');
SELECT COALESCE(NULL, 1), NULLIF(1,1), GREATEST(1,2,3);
SELECT array_length(ARRAY[1,2,3], 1), cardinality(ARRAY[1,2,3]);

