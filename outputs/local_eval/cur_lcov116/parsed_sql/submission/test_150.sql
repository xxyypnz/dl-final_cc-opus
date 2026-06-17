-- ===== Commit 150 =====
-- Source:  - 

-- --- Test Case 1 ---
CREATE TABLE c150_marker(id int);
\! SD=/tmp/c150_$$; rm -rf $SD; mkdir -p $SD/d $SD/s; initdb -D $SD/d >/dev/null 2>&1; pg_ctl -D $SD/d -o "-k $SD/s -p 55521" -w -t 30 start >/dev/null 2>&1; psql -h $SD/s -p 55521 -d postgres -c "SELECT pg_sleep(6)" >/dev/null 2>&1 & sleep 1.5; VP=$(psql -h $SD/s -p 55521 -d postgres -tA -c "SELECT pid FROM pg_stat_activity WHERE query LIKE '%pg_sleep(6)%' AND pid!=pg_backend_pid()" 2>/dev/null|head -1); test -n "$VP" && kill -9 $VP 2>/dev/null; sleep 4; pg_ctl -D $SD/d -m fast -w -t 30 stop >/dev/null 2>&1 || pg_ctl -D $SD/d -m immediate -w stop >/dev/null 2>&1; rm -rf $SD
\! SD=/tmp/c148_$$; rm -rf $SD; mkdir -p $SD/d $SD/s; initdb -D $SD/d >/dev/null 2>&1; pg_ctl -D $SD/d -o "-k $SD/s -p 55522 -c track_commit_timestamp=on" -w -t 30 start >/dev/null 2>&1; psql -h $SD/s -p 55522 -d postgres -c "CREATE TABLE t(id int)" -c "BEGIN; INSERT INTO t VALUES(1); SAVEPOINT s1; INSERT INTO t VALUES(2); SAVEPOINT s2; INSERT INTO t VALUES(3); COMMIT" >/dev/null 2>&1; pg_ctl -D $SD/d -m fast -w -t 30 stop >/dev/null 2>&1 || pg_ctl -D $SD/d -m immediate -w stop >/dev/null 2>&1; rm -rf $SD
DROP TABLE c150_marker;

