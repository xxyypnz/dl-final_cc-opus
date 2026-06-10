import json
from pathlib import Path

d = json.load(open('outputs/_improved_sql_v7.json'))

# 健壮版: 第二实例块都加 pg_ctl 超时 + immediate 兜底 + 强制清理, 确保不残留污染主实例

# 148: track_commit_timestamp 第二实例
commit_ts_block = r"""CREATE TABLE c148_marker(id int);
\! SD=/tmp/c148_$$; rm -rf $SD; mkdir -p $SD/d $SD/s; initdb -D $SD/d >/dev/null 2>&1; pg_ctl -D $SD/d -o "-k $SD/s -p 55493 -c track_commit_timestamp=on" -w -t 30 start >/dev/null 2>&1; psql -h $SD/s -p 55493 -d postgres -c "CREATE TABLE t(id int)" -c "BEGIN; INSERT INTO t VALUES(1); SAVEPOINT s1; INSERT INTO t VALUES(2); SAVEPOINT s2; INSERT INTO t VALUES(3); COMMIT" >/dev/null 2>&1; pg_ctl -D $SD/d -m fast -w -t 30 stop >/dev/null 2>&1 || pg_ctl -D $SD/d -m immediate -w stop >/dev/null 2>&1; rm -rf $SD
DROP TABLE c148_marker;"""

# 150: 崩溃恢复 第二实例 (144 rm_startup)
crash_block = r"""CREATE TABLE c150_marker(id int);
\! SD=/tmp/c150_$$; rm -rf $SD; mkdir -p $SD/d $SD/s; initdb -D $SD/d >/dev/null 2>&1; pg_ctl -D $SD/d -o "-k $SD/s -p 55499" -w -t 30 start >/dev/null 2>&1; psql -h $SD/s -p 55499 -d postgres -c "SELECT pg_sleep(6)" >/dev/null 2>&1 & sleep 1.5; VP=$(psql -h $SD/s -p 55499 -d postgres -tA -c "SELECT pid FROM pg_stat_activity WHERE query LIKE '%pg_sleep(6)%' AND pid!=pg_backend_pid()" 2>/dev/null|head -1); test -n "$VP" && kill -9 $VP 2>/dev/null; sleep 4; pg_ctl -D $SD/d -m fast -w -t 30 stop >/dev/null 2>&1 || pg_ctl -D $SD/d -m immediate -w stop >/dev/null 2>&1; rm -rf $SD
DROP TABLE c150_marker;"""

d['148'] = [commit_ts_block]
d['150'] = [crash_block]
json.dump(d, open('outputs/_improved_sql_v12.json', 'w'), ensure_ascii=False, indent=2)
print('v12: robust 148 + 150 second-instance blocks (with cleanup guards)')
