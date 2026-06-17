-- ===== Commit 113 =====
-- Source:  - 

-- --- Test Case 1 ---
DROP TABLE IF EXISTS c113_break CASCADE;
CREATE TABLE c113_break (id int, filler text) WITH (autovacuum_enabled=false, fillfactor=10);
INSERT INTO c113_break SELECT g, repeat('x',7500) FROM generate_series(1,3000) g;
CREATE INDEX c113_break_idx ON c113_break(id);
DELETE FROM c113_break WHERE id > 5;
ANALYZE c113_break;
EXPLAIN SELECT * FROM c113_break WHERE id > 2900;
SELECT count(*) FROM c113_break WHERE id > 2900;
DROP TABLE IF EXISTS c113_break CASCADE;

