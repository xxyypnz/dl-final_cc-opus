-- ===== Commit 144 =====
-- Source:  - 

-- --- Test Case 1 ---
DROP TABLE IF EXISTS c144_base CASCADE;
CREATE TABLE c144_base (id int, v text);
INSERT INTO c144_base SELECT i, 'val'||i FROM generate_series(1,100) i;
CHECKPOINT;
SELECT pg_current_wal_lsn();
SELECT * FROM c144_base WHERE id = 42;
CHECKPOINT;
DROP TABLE IF EXISTS c144_base CASCADE;

