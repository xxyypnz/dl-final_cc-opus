-- ===== Commit 150 =====
-- Source:  - 

-- --- Test Case 1 ---
SELECT 1;

-- --- Test Case 2 ---
SET lock_timeout = 0;
SET statement_timeout = 0;
SHOW port \gset
SELECT current_setting('unix_socket_directories') AS sockdir \gset
\setenv PGPORT :port
\setenv PGHOST :sockdir
\setenv PGDATABASE regression
\! psql -c "SELECT pg_sleep(8)" >/dev/null 2>&1 &
SELECT pg_sleep(1);
\! P=$(psql -tA -c "SELECT pid FROM pg_stat_activity WHERE query LIKE '%pg_sleep(8)%' AND pid!=pg_backend_pid()" 2>/dev/null | head -1); kill -9 $P 2>/dev/null
SELECT pg_sleep(5);

