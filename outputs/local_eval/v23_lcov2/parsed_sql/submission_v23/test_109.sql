-- ===== Commit 109 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS t1 CASCADE;
DROP TABLE IF EXISTS t2 CASCADE;
CREATE TABLE t1 (a int, b int);
CREATE TABLE t2 (c int, d int);
INSERT INTO t1 SELECT generate_series(1,100), generate_series(1,100);
INSERT INTO t2 SELECT generate_series(1,100), generate_series(1,100);
ANALYZE t1, t2;

-- Execution: Force a parameterized nested loop join that may use Memoize
SET enable_hashjoin = off;
SET enable_mergejoin = off;
SET enable_nestloop = on;
EXPLAIN (COSTS OFF) SELECT * FROM t1, t2 WHERE t1.a = t2.c AND t1.b = 1;
SELECT * FROM t1, t2 WHERE t1.a = t2.c AND t1.b = 1;

-- Teardown
DROP TABLE IF EXISTS t1 CASCADE;
DROP TABLE IF EXISTS t2 CASCADE;
RESET enable_hashjoin;
RESET enable_mergejoin;
RESET enable_nestloop;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS t1 CASCADE;
DROP TABLE IF EXISTS t2 CASCADE;
CREATE TABLE t1 (a int PRIMARY KEY);
CREATE TABLE t2 (b int REFERENCES t1(a));
INSERT INTO t1 SELECT generate_series(1,10);
INSERT INTO t2 SELECT generate_series(1,10);
ANALYZE t1, t2;

-- Execution: Use a parameterized join that might fail reparameterization due to outer rel mismatch
SET enable_hashjoin = off;
SET enable_mergejoin = off;
SET enable_nestloop = on;
EXPLAIN (COSTS OFF) SELECT * FROM t1, t2 WHERE t1.a = t2.b AND t2.b = 5;
SELECT * FROM t1, t2 WHERE t1.a = t2.b AND t2.b = 5;

-- Teardown
DROP TABLE IF EXISTS t1 CASCADE;
DROP TABLE IF EXISTS t2 CASCADE;
RESET enable_hashjoin;
RESET enable_mergejoin;
RESET enable_nestloop;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS t1 CASCADE;
DROP TABLE IF EXISTS t2 CASCADE;
CREATE TABLE t1 (x int, y int);
CREATE TABLE t2 (z int, w int);
INSERT INTO t1 SELECT generate_series(1,50), generate_series(1,50);
INSERT INTO t2 SELECT generate_series(1,50), generate_series(1,50);
ANALYZE t1, t2;

-- Execution: Use a subquery with parameterized join and Memoize
SET enable_hashjoin = off;
SET enable_mergejoin = off;
SET enable_nestloop = on;
EXPLAIN (COSTS OFF) SELECT * FROM t1 WHERE t1.x IN (SELECT t2.z FROM t2 WHERE t2.w = t1.y AND t2.z > 10);
SELECT * FROM t1 WHERE t1.x IN (SELECT t2.z FROM t2 WHERE t2.w = t1.y AND t2.z > 10);

-- Teardown
DROP TABLE IF EXISTS t1 CASCADE;
DROP TABLE IF EXISTS t2 CASCADE;
RESET enable_hashjoin;
RESET enable_mergejoin;
RESET enable_nestloop;

-- --- Test Case 4 ---
DROP TABLE IF EXISTS c109_prt1 CASCADE;
DROP TABLE IF EXISTS c109_prt2 CASCADE;
CREATE TABLE c109_prt1 (a int, b int, c varchar) PARTITION BY RANGE(a);
CREATE TABLE c109_prt1_p1 PARTITION OF c109_prt1 FOR VALUES FROM (0) TO (250);
CREATE TABLE c109_prt1_p2 PARTITION OF c109_prt1 FOR VALUES FROM (250) TO (500) PARTITION BY LIST (c);
CREATE TABLE c109_prt1_p2_p1 PARTITION OF c109_prt1_p2 FOR VALUES IN ('0000','0001');
CREATE TABLE c109_prt1_p2_p2 PARTITION OF c109_prt1_p2 FOR VALUES IN ('0002','0003');
CREATE TABLE c109_prt1_p3 PARTITION OF c109_prt1 FOR VALUES FROM (500) TO (600) PARTITION BY RANGE (b);
CREATE TABLE c109_prt1_p3_p1 PARTITION OF c109_prt1_p3 FOR VALUES FROM (0) TO (13);
CREATE TABLE c109_prt1_p3_p2 PARTITION OF c109_prt1_p3 FOR VALUES FROM (13) TO (25);
INSERT INTO c109_prt1 SELECT i, i % 25, to_char(i % 4, 'FM0000') FROM generate_series(0, 599, 2) i;
ANALYZE c109_prt1;
CREATE TABLE c109_prt2 (a int, b int, c varchar) PARTITION BY RANGE(b);
CREATE TABLE c109_prt2_p1 PARTITION OF c109_prt2 FOR VALUES FROM (0) TO (250);
CREATE TABLE c109_prt2_p2 PARTITION OF c109_prt2 FOR VALUES FROM (250) TO (500) PARTITION BY LIST (c);
CREATE TABLE c109_prt2_p2_p1 PARTITION OF c109_prt2_p2 FOR VALUES IN ('0000','0001');
CREATE TABLE c109_prt2_p2_p2 PARTITION OF c109_prt2_p2 FOR VALUES IN ('0002','0003');
CREATE TABLE c109_prt2_p3 PARTITION OF c109_prt2 FOR VALUES FROM (500) TO (600) PARTITION BY RANGE (a);
CREATE TABLE c109_prt2_p3_p1 PARTITION OF c109_prt2_p3 FOR VALUES FROM (0) TO (13);
CREATE TABLE c109_prt2_p3_p2 PARTITION OF c109_prt2_p3 FOR VALUES FROM (13) TO (25);
INSERT INTO c109_prt2 SELECT i % 25, i, to_char(i % 4, 'FM0000') FROM generate_series(0, 599, 3) i;
ANALYZE c109_prt2;
SET enable_partitionwise_join = on;
SELECT count(*) FROM c109_prt1 t1 LEFT JOIN LATERAL
  (SELECT t2.a AS t2a, t2.c AS t2c, t2.b AS t2b, t3.b AS t3b
     FROM c109_prt1 t2 JOIN c109_prt2 t3 ON (t2.a = t3.b AND t2.c = t3.c)) ss
  ON t1.a = ss.t2a AND t1.c = ss.t2c WHERE t1.b = 0;
RESET enable_partitionwise_join;
DROP TABLE IF EXISTS c109_prt1 CASCADE;
DROP TABLE IF EXISTS c109_prt2 CASCADE;

-- --- Test Case 5 ---
DROP TABLE IF EXISTS c109_a CASCADE;
DROP TABLE IF EXISTS c109_b CASCADE;
DROP TABLE IF EXISTS c109_c CASCADE;
CREATE TABLE c109_a (id int, x int);
CREATE TABLE c109_b (id int, y int);
CREATE TABLE c109_c (id int, z int);
INSERT INTO c109_a SELECT i, i FROM generate_series(1,100) i;
INSERT INTO c109_b SELECT i, i*2 FROM generate_series(1,100) i;
INSERT INTO c109_c SELECT i, i*3 FROM generate_series(1,100) i;
ANALYZE c109_a, c109_b, c109_c;
SET enable_hashjoin=off; SET enable_mergejoin=off; SET enable_nestloop=on;
EXPLAIN SELECT * FROM c109_a, c109_b, c109_c
  WHERE c109_a.id=c109_b.id AND c109_b.id=c109_c.id AND c109_a.x=5;
SELECT * FROM c109_a, c109_b, c109_c
  WHERE c109_a.id=c109_b.id AND c109_b.id=c109_c.id AND c109_a.x=5;
RESET enable_hashjoin; RESET enable_mergejoin; RESET enable_nestloop;
DROP TABLE IF EXISTS c109_a CASCADE; DROP TABLE IF EXISTS c109_b CASCADE; DROP TABLE IF EXISTS c109_c CASCADE;

-- --- Test Case 6 ---
DROP TABLE IF EXISTS c109_p CASCADE;
DROP TABLE IF EXISTS c109_q CASCADE;
CREATE TABLE c109_p (a int, b int);
CREATE TABLE c109_q (a int, c int);
INSERT INTO c109_p SELECT i, i%10 FROM generate_series(1,200) i;
INSERT INTO c109_q SELECT i, i%5 FROM generate_series(1,200) i;
ANALYZE c109_p, c109_q;
SET enable_hashjoin=off; SET enable_mergejoin=off; SET enable_nestloop=on;
SELECT COUNT(*) FROM c109_p WHERE c109_p.b IN (SELECT c109_q.c FROM c109_q WHERE c109_q.a = c109_p.a AND c109_q.c > 2);
RESET enable_hashjoin; RESET enable_mergejoin; RESET enable_nestloop;
DROP TABLE IF EXISTS c109_p CASCADE; DROP TABLE IF EXISTS c109_q CASCADE;

