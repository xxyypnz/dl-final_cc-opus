-- ===== Commit 143 =====
-- Source:  - 

-- --- Test Case 1 ---
DROP TABLE IF EXISTS c143_parent CASCADE;
CREATE TABLE c143_parent (id int, data text) PARTITION BY RANGE (id);
CREATE TABLE c143_child PARTITION OF c143_parent FOR VALUES FROM (1) TO (100);
CREATE INDEX c143_idx ON c143_parent (id);
DROP INDEX c143_idx;
DROP TABLE IF EXISTS c143_parent CASCADE;

