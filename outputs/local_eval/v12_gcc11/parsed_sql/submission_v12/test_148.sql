-- ===== Commit 148 =====
-- Source:  - 

-- --- Test Case 1 ---
CREATE TABLE c148_marker(id int);
\! SD=/tmp/c148_$$; rm -rf $SD; mkdir -p $SD/d $SD/s; initdb -D $SD/d >/dev/null 2>&1; pg_ctl -D $SD/d -o "-k $SD/s -p 55493 -c track_commit_timestamp=on" -w -t 30 start >/dev/null 2>&1; psql -h $SD/s -p 55493 -d postgres -c "CREATE TABLE t(id int)" -c "BEGIN; INSERT INTO t VALUES(1); SAVEPOINT s1; INSERT INTO t VALUES(2); SAVEPOINT s2; INSERT INTO t VALUES(3); COMMIT" >/dev/null 2>&1; pg_ctl -D $SD/d -m fast -w -t 30 stop >/dev/null 2>&1 || pg_ctl -D $SD/d -m immediate -w stop >/dev/null 2>&1; rm -rf $SD
DROP TABLE c148_marker;

