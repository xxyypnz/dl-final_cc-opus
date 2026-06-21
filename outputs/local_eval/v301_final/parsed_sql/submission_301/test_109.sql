-- ===== Commit 109 =====
-- Source:  - 

-- --- Test Case 1 ---
DROP TABLE IF EXISTS c109_t1, c109_t2, c109_outer CASCADE;
CREATE TABLE c109_t1(id int, val int);
CREATE TABLE c109_t2(id int, val int);
CREATE TABLE c109_outer(id int, data text);
INSERT INTO c109_t1 VALUES (1, 10), (2, 20), (3, 30);
INSERT INTO c109_t2 VALUES (2, 200), (3, 300), (4, 400);
INSERT INTO c109_outer VALUES (1, 'a'), (2, 'b'), (3, 'c');
ANALYZE c109_t1, c109_t2, c109_outer;
SELECT c109_outer.id, c109_outer.data, combined.val
FROM c109_outer
JOIN (
    SELECT id, val FROM c109_t1
    UNION ALL
    SELECT id, val FROM c109_t2
) AS combined(id, val)
ON c109_outer.id = combined.id
ORDER BY c109_outer.id;
DROP TABLE c109_t1, c109_t2, c109_outer CASCADE;

-- --- Test Case 2 ---
DROP TABLE IF EXISTS c109_a, c109_b, c109_c CASCADE;
CREATE TABLE c109_a(x int, y int);
CREATE TABLE c109_b(x int, y int);
CREATE TABLE c109_c(x int, z text);
INSERT INTO c109_a SELECT i, i*2 FROM generate_series(1,50) i;
INSERT INTO c109_b SELECT i, i*3 FROM generate_series(1,50) i;
INSERT INTO c109_c SELECT i, 'val'||i FROM generate_series(1,20) i;
ANALYZE c109_a, c109_b, c109_c;
SELECT c.x, c.z, u.y
FROM c109_c c
JOIN (
    SELECT x, y FROM c109_a WHERE y > 10
    UNION ALL
    SELECT x, y FROM c109_b WHERE y < 100
) u ON c.x = u.x
WHERE c.x < 15;
DROP TABLE c109_a, c109_b, c109_c CASCADE;

-- --- Test Case 3 ---
DROP TABLE IF EXISTS c109_p, c109_q, c109_r, c109_main CASCADE;
CREATE TABLE c109_p(k int, v int);
CREATE TABLE c109_q(k int, v int);
CREATE TABLE c109_r(k int, v int);
CREATE TABLE c109_main(k int, descr text);
INSERT INTO c109_p VALUES (1, 100), (2, 200);
INSERT INTO c109_q VALUES (2, 250), (3, 300);
INSERT INTO c109_r VALUES (3, 350), (4, 400);
INSERT INTO c109_main VALUES (1, 'alpha'), (2, 'beta'), (3, 'gamma');
ANALYZE c109_p, c109_q, c109_r, c109_main;
SELECT m.k, m.descr, combined.v
FROM c109_main m
JOIN (
    SELECT k, v FROM c109_p
    UNION ALL
    SELECT k, v FROM c109_q
    UNION ALL
    SELECT k, v FROM c109_r
) AS combined ON m.k = combined.k;
DROP TABLE c109_p, c109_q, c109_r, c109_main CASCADE;

