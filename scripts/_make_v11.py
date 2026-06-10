import json
from pathlib import Path

d = json.load(open('outputs/_improved_sql_v7.json'))

# 150: 第二实例崩溃恢复(144 rm_startup, 4行) + track_commit_timestamp(148, 2行)
# 两个独立第二实例, 都不影响主实例
crash_block = r"""CREATE TABLE c150_marker(id int);
\! SD=/tmp/c150crash_$$; rm -rf $SD; mkdir -p $SD/d $SD/s; initdb -D $SD/d >/dev/null 2>&1; pg_ctl -D $SD/d -o "-k $SD/s -p 55499" -w start >/dev/null 2>&1; psql -h $SD/s -p 55499 -d postgres -c "SELECT pg_sleep(6)" >/dev/null 2>&1 & sleep 1.5; VP=$(psql -h $SD/s -p 55499 -d postgres -tA -c "SELECT pid FROM pg_stat_activity WHERE query LIKE '%pg_sleep(6)%' AND pid!=pg_backend_pid()" 2>/dev/null|head -1); kill -9 $VP 2>/dev/null; sleep 4; pg_ctl -D $SD/d -m fast -w stop >/dev/null 2>&1; rm -rf $SD
DROP TABLE c150_marker;"""

commit_ts_block = r"""CREATE TABLE c148_marker(id int);
\! SD=/tmp/c148_$$; rm -rf $SD; mkdir -p $SD/d $SD/s; initdb -D $SD/d >/dev/null 2>&1; pg_ctl -D $SD/d -o "-k $SD/s -p 55498 -c track_commit_timestamp=on" -w start >/dev/null 2>&1; psql -h $SD/s -p 55498 -d postgres -c "CREATE TABLE t(id int)" -c "BEGIN; INSERT INTO t VALUES(1); SAVEPOINT s1; INSERT INTO t VALUES(2); SAVEPOINT s2; INSERT INTO t VALUES(3); COMMIT" -c "SELECT pg_xact_commit_timestamp(xmin) FROM t" >/dev/null 2>&1; pg_ctl -D $SD/d -m fast -w stop >/dev/null 2>&1; rm -rf $SD
DROP TABLE c148_marker;"""

# 148 的块放进 commit 148(它自己), 崩溃块放 150
d['148'] = [commit_ts_block]
d['150'] = [crash_block]
json.dump(d, open('outputs/_improved_sql_v11.json', 'w'), ensure_ascii=False, indent=2)
print('v11: 148(track_ts) + 150(crash) second-instance blocks added')
