-- ===== Commit 143 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS parent_table CASCADE;
CREATE TABLE parent_table (id INT, data TEXT) PARTITION BY RANGE (id);
CREATE TABLE child_table PARTITION OF parent_table FOR VALUES FROM (1) TO (100);
CREATE INDEX idx_parent ON parent_table(id);
CREATE INDEX idx_child ON child_table(id);

-- Execution
DROP INDEX idx_parent;

-- Teardown
DROP TABLE IF EXISTS parent_table CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS parent_table2 CASCADE;
CREATE TABLE parent_table2 (id INT, data TEXT) PARTITION BY RANGE (id);
CREATE TABLE child_table2 PARTITION OF parent_table2 FOR VALUES FROM (1) TO (100);
CREATE INDEX idx_parent2 ON parent_table2(id);
CREATE INDEX idx_child2 ON child_table2(id);

-- Execution
DROP INDEX CONCURRENTLY idx_parent2;

-- Teardown
DROP TABLE IF EXISTS parent_table2 CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS plain_table CASCADE;
CREATE TABLE plain_table (id INT, data TEXT);
CREATE INDEX idx_plain ON plain_table(id);

-- Execution
DROP INDEX idx_plain;

-- Teardown
DROP TABLE IF EXISTS plain_table CASCADE;

-- --- Test Case 4 ---
DROP TABLE IF EXISTS wrongdrop143 CASCADE;
CREATE TABLE wrongdrop143 (a int) PARTITION BY RANGE (a);
CREATE TABLE wrongdrop143_1 PARTITION OF wrongdrop143 FOR VALUES FROM (0) TO (10);
CREATE INDEX wrongdrop143_a_idx ON wrongdrop143 (a);
DROP TABLE wrongdrop143_a_idx;
DROP INDEX wrongdrop143_a_idx;
DROP TABLE IF EXISTS wrongdrop143 CASCADE;

-- --- Test Case 5 ---
DROP TABLE IF EXISTS c143_parent CASCADE;
CREATE TABLE c143_parent (id int, data text) PARTITION BY RANGE (id);
CREATE TABLE c143_child PARTITION OF c143_parent FOR VALUES FROM (1) TO (100);
CREATE INDEX c143_idx ON c143_parent (id);
DROP INDEX c143_idx;
DROP TABLE IF EXISTS c143_parent CASCADE;

-- --- Test Case 6 ---
DROP TABLE IF EXISTS c143_idx_t CASCADE;
CREATE TABLE c143_idx_t (id int, val text) PARTITION BY RANGE (id);
CREATE TABLE c143_idx_child1 PARTITION OF c143_idx_t FOR VALUES FROM (1) TO (100);
CREATE TABLE c143_idx_child2 PARTITION OF c143_idx_t FOR VALUES FROM (100) TO (200);
CREATE INDEX c143_pidx ON c143_idx_t (id);
INSERT INTO c143_idx_t SELECT i, 'v'||i FROM generate_series(1,150) i;
DROP INDEX IF EXISTS c143_pidx;
DROP TABLE IF EXISTS c143_idx_t CASCADE;

-- --- Test Case 7 ---
DROP TABLE IF EXISTS c143_t2 CASCADE;
CREATE TABLE c143_t2 (x int, y int) PARTITION BY HASH (x);
CREATE TABLE c143_t2_p0 PARTITION OF c143_t2 FOR VALUES WITH (MODULUS 3, REMAINDER 0);
CREATE TABLE c143_t2_p1 PARTITION OF c143_t2 FOR VALUES WITH (MODULUS 3, REMAINDER 1);
CREATE TABLE c143_t2_p2 PARTITION OF c143_t2 FOR VALUES WITH (MODULUS 3, REMAINDER 2);
CREATE INDEX ON c143_t2 (x);
INSERT INTO c143_t2 SELECT i, i*2 FROM generate_series(1,30) i;
DROP TABLE IF EXISTS c143_t2 CASCADE;

-- --- Test Case 8 ---
DROP TABLE IF EXISTS c143_t3 CASCADE;
CREATE TABLE c143_t3 (a int) PARTITION BY LIST (a);
CREATE TABLE c143_t3_odd PARTITION OF c143_t3 FOR VALUES IN (1,3,5,7,9);
CREATE TABLE c143_t3_even PARTITION OF c143_t3 FOR VALUES IN (2,4,6,8,10);
CREATE INDEX c143_idx3 ON c143_t3 (a);
INSERT INTO c143_t3 SELECT (i%10)+1 FROM generate_series(1,50) i;
DROP INDEX IF EXISTS c143_idx3;
DROP TABLE IF EXISTS c143_t3 CASCADE;

