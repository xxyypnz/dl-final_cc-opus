-- ===== Commit 113 =====
-- Source:  - 

-- --- Test Case 1 ---
DROP TABLE IF EXISTS c113_endpoint CASCADE;
CREATE TABLE c113_endpoint (id int, filler text) WITH (autovacuum_enabled=false, fillfactor=10);
INSERT INTO c113_endpoint SELECT g, repeat('x', 7000) FROM generate_series(1, 300) g;
CREATE INDEX c113_endpoint_idx ON c113_endpoint(id);
DELETE FROM c113_endpoint WHERE id > 40;
ANALYZE c113_endpoint;
EXPLAIN SELECT * FROM c113_endpoint WHERE id > 280;
SELECT count(*) FROM c113_endpoint WHERE id > 280;
DROP TABLE IF EXISTS c113_endpoint CASCADE;

-- --- Test Case 2 ---
DROP TABLE IF EXISTS c113_minend CASCADE;
CREATE TABLE c113_minend (id int, filler text) WITH (autovacuum_enabled=false, fillfactor=10);
INSERT INTO c113_minend SELECT g, repeat('y', 7000) FROM generate_series(1, 300) g;
CREATE INDEX c113_minend_idx ON c113_minend(id);
DELETE FROM c113_minend WHERE id <= 260;
ANALYZE c113_minend;
EXPLAIN SELECT * FROM c113_minend WHERE id < 20;
SELECT count(*) FROM c113_minend WHERE id < 20;
DROP TABLE IF EXISTS c113_minend CASCADE;

