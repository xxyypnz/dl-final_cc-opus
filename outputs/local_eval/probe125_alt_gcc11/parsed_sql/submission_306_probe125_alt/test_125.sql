-- ===== Commit 125 =====
-- Source:  - 

-- --- Test Case 1 ---
SET lock_timeout = '300ms';
SET statement_timeout = '1500ms';
DROP TABLE IF EXISTS c125_px CASCADE;
CREATE TABLE c125_px (id int primary key, v text) WITH (autovacuum_enabled = false);
INSERT INTO c125_px SELECT g, 'x' FROM generate_series(1, 20) g;
VACUUM c125_px;
BEGIN;
SELECT * FROM c125_px WHERE id = 1 FOR KEY SHARE;
PREPARE TRANSACTION 'c125_px_1';
BEGIN;
SELECT * FROM c125_px WHERE id = 1 FOR SHARE;
PREPARE TRANSACTION 'c125_px_2';
DELETE FROM c125_px WHERE id = 1;
ROLLBACK PREPARED 'c125_px_1';
ROLLBACK PREPARED 'c125_px_2';
DROP TABLE IF EXISTS c125_px CASCADE;
RESET lock_timeout;
RESET statement_timeout;

-- --- Test Case 2 ---
SET lock_timeout = 0;
SET statement_timeout = 0;
DROP TABLE IF EXISTS c125_sv CASCADE;
CREATE TABLE c125_sv (id int primary key, v text) WITH (autovacuum_enabled = false);
INSERT INTO c125_sv SELECT g, 'x' FROM generate_series(1, 20) g;
VACUUM c125_sv;
BEGIN;
SELECT * FROM c125_sv WHERE id = 1 FOR KEY SHARE;
SAVEPOINT c125_sv_s1;
SELECT * FROM c125_sv WHERE id = 1 FOR SHARE;
SAVEPOINT c125_sv_s2;
DELETE FROM c125_sv WHERE id = 1;
ROLLBACK TO c125_sv_s1;
COMMIT;
DROP TABLE IF EXISTS c125_sv CASCADE;

-- --- Test Case 3 ---
DROP FUNCTION IF EXISTS c125_lock_row(int) CASCADE;
DROP TABLE IF EXISTS c125_pw CASCADE;
CREATE TABLE c125_pw (id int primary key, v text) WITH (autovacuum_enabled = false);
INSERT INTO c125_pw SELECT g, 'x' FROM generate_series(1, 20000) g;
VACUUM c125_pw;
CREATE FUNCTION c125_lock_row(i int) RETURNS int
LANGUAGE SQL PARALLEL SAFE AS
$$
  SELECT id FROM c125_pw WHERE id = i FOR SHARE;
  SELECT i;
$$;
SET force_parallel_mode = on;
SET parallel_setup_cost = 0;
SET parallel_tuple_cost = 0;
SET min_parallel_table_scan_size = 0;
SET parallel_leader_participation = off;
SET max_parallel_workers_per_gather = 4;
BEGIN;
SELECT sum(c125_lock_row(1)) FROM generate_series(1, 20000) g;
DELETE FROM c125_pw WHERE id = 1;
COMMIT;
RESET force_parallel_mode;
RESET parallel_setup_cost;
RESET parallel_tuple_cost;
RESET min_parallel_table_scan_size;
RESET parallel_leader_participation;
RESET max_parallel_workers_per_gather;
DROP FUNCTION IF EXISTS c125_lock_row(int) CASCADE;
DROP TABLE IF EXISTS c125_pw CASCADE;

-- --- Test Case 4 ---
DROP TABLE IF EXISTS c125_heap CASCADE;
CREATE TABLE c125_heap (id int, val text);
INSERT INTO c125_heap SELECT i, repeat('x', 50) FROM generate_series(1, 500) i;
VACUUM c125_heap;
UPDATE c125_heap SET val = repeat('y', 50) WHERE id BETWEEN 1 AND 100;
UPDATE c125_heap SET val = repeat('z', 50) WHERE id BETWEEN 101 AND 200;
SELECT COUNT(*) FROM c125_heap WHERE val LIKE 'y%';
DROP TABLE IF EXISTS c125_heap CASCADE;

-- --- Test Case 5 ---
DROP TABLE IF EXISTS c125_del CASCADE;
CREATE TABLE c125_del (id int PRIMARY KEY, v text);
INSERT INTO c125_del SELECT i, 'v'||i FROM generate_series(1,200) i;
VACUUM c125_del;
DELETE FROM c125_del WHERE id % 3 = 0;
SELECT COUNT(*) FROM c125_del;
DROP TABLE IF EXISTS c125_del CASCADE;

-- --- Test Case 6 ---
DROP TABLE IF EXISTS c125_upd CASCADE;
CREATE TABLE c125_upd (id int, val text);
INSERT INTO c125_upd SELECT i, 'v'||i FROM generate_series(1,300) i;
VACUUM ANALYZE c125_upd;
UPDATE c125_upd SET val = 'updated_'||id WHERE id BETWEEN 1 AND 100;
UPDATE c125_upd SET val = 'pass2_'||id WHERE id BETWEEN 50 AND 150;
DELETE FROM c125_upd WHERE id BETWEEN 200 AND 300;
VACUUM c125_upd;
SELECT COUNT(*) FROM c125_upd;
DROP TABLE IF EXISTS c125_upd CASCADE;

-- --- Test Case 7 ---
DROP TABLE IF EXISTS c125_303_del CASCADE;
CREATE TABLE c125_303_del (id int PRIMARY KEY, v text);
INSERT INTO c125_303_del
SELECT i, repeat('v', 80) FROM generate_series(1, 600) i;
VACUUM c125_303_del;
UPDATE c125_303_del SET v = repeat('u', 80) WHERE id BETWEEN 1 AND 150;
VACUUM c125_303_del;
DELETE FROM c125_303_del WHERE id BETWEEN 1 AND 300;
SELECT count(*) FROM c125_303_del;
DROP TABLE IF EXISTS c125_303_del CASCADE;

