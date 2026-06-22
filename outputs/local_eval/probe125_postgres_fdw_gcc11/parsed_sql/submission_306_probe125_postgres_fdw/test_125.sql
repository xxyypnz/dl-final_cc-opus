-- ===== Commit 125 =====
-- Source:  - 

-- --- Test Case 1 ---
SET lock_timeout = 0;
SET statement_timeout = 0;
CREATE EXTENSION IF NOT EXISTS postgres_fdw;
DROP SERVER IF EXISTS c125_loopback_srv CASCADE;
DROP USER MAPPING IF EXISTS FOR CURRENT_USER SERVER c125_loopback_srv;
DROP TABLE IF EXISTS c125_fdw_conc CASCADE;
CREATE TABLE c125_fdw_conc (id int primary key, v text);
INSERT INTO c125_fdw_conc SELECT g, 'x' FROM generate_series(1,50) g;
VACUUM c125_fdw_conc;
CREATE SERVER c125_loopback_srv FOREIGN DATA WRAPPER postgres_fdw OPTIONS (dbname 'regression');
CREATE USER MAPPING FOR CURRENT_USER SERVER c125_loopback_srv OPTIONS (user '');
DROP FOREIGN TABLE IF EXISTS c125_fdw_conc_ft;
CREATE FOREIGN TABLE c125_fdw_conc_ft (id int, v text) SERVER c125_loopback_srv OPTIONS (table_name 'c125_fdw_conc');
BEGIN;
SELECT * FROM c125_fdw_conc_ft WHERE id = 1 FOR SHARE;
DELETE FROM c125_fdw_conc WHERE id = 1;
COMMIT;
DROP FOREIGN TABLE IF EXISTS c125_fdw_conc_ft;
DROP SERVER IF EXISTS c125_loopback_srv CASCADE;
DROP TABLE IF EXISTS c125_fdw_conc CASCADE;
SET lock_timeout = 1000;
SET statement_timeout = 5000;

-- --- Test Case 2 ---
DROP TABLE IF EXISTS c125_heap CASCADE;
CREATE TABLE c125_heap (id int, val text);
INSERT INTO c125_heap SELECT i, repeat('x', 50) FROM generate_series(1, 500) i;
VACUUM c125_heap;
UPDATE c125_heap SET val = repeat('y', 50) WHERE id BETWEEN 1 AND 100;
UPDATE c125_heap SET val = repeat('z', 50) WHERE id BETWEEN 101 AND 200;
SELECT COUNT(*) FROM c125_heap WHERE val LIKE 'y%';
DROP TABLE IF EXISTS c125_heap CASCADE;

-- --- Test Case 3 ---
DROP TABLE IF EXISTS c125_del CASCADE;
CREATE TABLE c125_del (id int PRIMARY KEY, v text);
INSERT INTO c125_del SELECT i, 'v'||i FROM generate_series(1,200) i;
VACUUM c125_del;
DELETE FROM c125_del WHERE id % 3 = 0;
SELECT COUNT(*) FROM c125_del;
DROP TABLE IF EXISTS c125_del CASCADE;

-- --- Test Case 4 ---
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

-- --- Test Case 5 ---
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

