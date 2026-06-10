import json
from pathlib import Path

# v13: 把 148配置块 和 144崩溃块 都放到 commit 150 末尾(所有主SQL之后),串行无wait,强制清理。
# commit 148 恢复为占位(不碰任何C文件), 避免中间位置的第二实例污染后续主覆盖。
d = json.load(open('outputs/_improved_sql_v7.json'))

# commit 148: 占位(去掉中间位置的第二实例块)
d['148'] = ['SELECT 1;']

# commit 150: 崩溃块(144) + 148配置块, 都在末尾, 无wait, 强清理
combined_block = r"""CREATE TABLE c150_marker(id int);
\! SD=/tmp/c150_$$; rm -rf $SD; mkdir -p $SD/d $SD/s; initdb -D $SD/d >/dev/null 2>&1; pg_ctl -D $SD/d -o "-k $SD/s -p 55521" -w -t 30 start >/dev/null 2>&1; psql -h $SD/s -p 55521 -d postgres -c "SELECT pg_sleep(6)" >/dev/null 2>&1 & sleep 1.5; VP=$(psql -h $SD/s -p 55521 -d postgres -tA -c "SELECT pid FROM pg_stat_activity WHERE query LIKE '%pg_sleep(6)%' AND pid!=pg_backend_pid()" 2>/dev/null|head -1); test -n "$VP" && kill -9 $VP 2>/dev/null; sleep 4; pg_ctl -D $SD/d -m fast -w -t 30 stop >/dev/null 2>&1 || pg_ctl -D $SD/d -m immediate -w stop >/dev/null 2>&1; rm -rf $SD
\! SD=/tmp/c148_$$; rm -rf $SD; mkdir -p $SD/d $SD/s; initdb -D $SD/d >/dev/null 2>&1; pg_ctl -D $SD/d -o "-k $SD/s -p 55522 -c track_commit_timestamp=on" -w -t 30 start >/dev/null 2>&1; psql -h $SD/s -p 55522 -d postgres -c "CREATE TABLE t(id int)" -c "BEGIN; INSERT INTO t VALUES(1); SAVEPOINT s1; INSERT INTO t VALUES(2); SAVEPOINT s2; INSERT INTO t VALUES(3); COMMIT" >/dev/null 2>&1; pg_ctl -D $SD/d -m fast -w -t 30 stop >/dev/null 2>&1 || pg_ctl -D $SD/d -m immediate -w stop >/dev/null 2>&1; rm -rf $SD
DROP TABLE c150_marker;"""

d['150'] = [combined_block]
json.dump(d, open('outputs/_improved_sql_v13.json', 'w'), ensure_ascii=False, indent=2)
print('v13: 148 placeholder, crash+148blocks both at commit 150 tail')
