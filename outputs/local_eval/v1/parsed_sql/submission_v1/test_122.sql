-- ===== Commit 122 =====
-- Source:  - 

-- --- Test Case 1 ---
DROP TABLE IF EXISTS c122_t CASCADE;
CREATE TABLE c122_t (id int, v numeric);
INSERT INTO c122_t VALUES (1,10.5),(1,20.5),(2,3.3),(2,4.4);
SELECT id, avg(v), array_agg(v) FROM c122_t GROUP BY id ORDER BY id;
DROP TABLE IF EXISTS c122_t CASCADE;

