-- ===== Commit 125 =====
-- Source:  - 

-- --- Test Case 1 ---
SET lock_timeout = 0;
SET statement_timeout = 0;
DROP TABLE IF EXISTS c125_conc CASCADE;
CREATE TABLE c125_conc (id int primary key, v text);
INSERT INTO c125_conc SELECT g,'x' FROM generate_series(1,50) g;
VACUUM c125_conc;
SHOW port \gset
SELECT current_setting('unix_socket_directories') AS sockdir \gset
\setenv PGPORT :port
\setenv PGHOST :sockdir
\setenv PGDATABASE regression
\! psql -c "BEGIN; SELECT * FROM c125_conc WHERE id=1 FOR KEY SHARE; SELECT pg_sleep(3); COMMIT;" >/dev/null 2>&1 &
\! psql -c "BEGIN; SELECT * FROM c125_conc WHERE id=1 FOR SHARE; SELECT pg_sleep(3); COMMIT;" >/dev/null 2>&1 &
SELECT pg_sleep(1.5);
DELETE FROM c125_conc WHERE id=1;
SELECT pg_sleep(2.5);
SET lock_timeout = 1000;
SET statement_timeout = 5000;
DROP TABLE IF EXISTS c125_conc CASCADE;

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

