import json
from pathlib import Path

d = json.load(open('outputs/_improved_sql_v7.json'))

# commit 150: 独立第二实例崩溃恢复, 覆盖144的rm_startup. 主实例不受影响.
# 全内联在一个 \! 命令里. 用唯一端口/socket避免和主评测实例(55432)冲突.
crash_sql = r"""CREATE TABLE c150_marker(id int);
\! SD=/tmp/c150crash_$$; rm -rf $SD; mkdir -p $SD/d $SD/s; initdb -D $SD/d >/dev/null 2>&1; pg_ctl -D $SD/d -o "-k $SD/s -p 55499" -w start >/dev/null 2>&1; psql -h $SD/s -p 55499 -d postgres -c "SELECT pg_sleep(6)" >/dev/null 2>&1 & sleep 1.5; VP=$(psql -h $SD/s -p 55499 -d postgres -tA -c "SELECT pid FROM pg_stat_activity WHERE query LIKE '%pg_sleep(6)%' AND pid!=pg_backend_pid()" 2>/dev/null|head -1); kill -9 $VP 2>/dev/null; sleep 4; pg_ctl -D $SD/d -m fast -w stop >/dev/null 2>&1; rm -rf $SD
DROP TABLE c150_marker;"""

d['150'] = [crash_sql]
json.dump(d, open('outputs/_improved_sql_v10.json', 'w'), ensure_ascii=False, indent=2)
print('v10: 150 second-instance crash block added')
