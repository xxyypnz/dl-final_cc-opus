-- ===== Commit 148 =====
-- Source:  - 

-- --- Test Case 1 ---
SELECT 1;

-- --- Test Case 2 ---
SET track_commit_timestamp = off;
DROP TABLE IF EXISTS c148_t CASCADE;
CREATE TABLE c148_t (id int);
INSERT INTO c148_t SELECT generate_series(1, 10);
BEGIN;
SAVEPOINT sp1;
INSERT INTO c148_t VALUES (100);
SAVEPOINT sp2;
INSERT INTO c148_t VALUES (200);
RELEASE SAVEPOINT sp2;
COMMIT;
SELECT COUNT(*) FROM c148_t;
DROP TABLE IF EXISTS c148_t CASCADE;

