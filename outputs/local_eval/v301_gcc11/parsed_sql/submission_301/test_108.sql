-- ===== Commit 108 =====
-- Source:  - 

-- --- Test Case 1 ---
DROP TABLE IF EXISTS c108_base CASCADE;
CREATE TABLE c108_base (id INT, val INT);
INSERT INTO c108_base VALUES (1, 10), (2, 20), (3, 30);
SELECT * FROM (
  SELECT id, val FROM c108_base
  UNION ALL
  SELECT id, val FROM c108_base
  UNION ALL
  SELECT id, val FROM c108_base
) AS u WHERE id > 1;
DROP TABLE c108_base CASCADE;

-- --- Test Case 2 ---
DROP TABLE IF EXISTS c108_t1, c108_t2 CASCADE;
CREATE TABLE c108_t1 (a int, b text);
CREATE TABLE c108_t2 (a int, b text);
INSERT INTO c108_t1 VALUES (1, 'x'), (2, 'y');
INSERT INTO c108_t2 VALUES (3, 'z'), (4, 'w');
SELECT a, COUNT(*) FROM (
  SELECT a, b FROM c108_t1
  UNION ALL
  SELECT a, b FROM c108_t2
) sub GROUP BY a ORDER BY a;
DROP TABLE c108_t1, c108_t2 CASCADE;

