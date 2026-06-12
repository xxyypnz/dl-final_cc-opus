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

