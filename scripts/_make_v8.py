import json

d = json.load(open('outputs/_improved_sql_v7.json'))

# commit 150: 崩溃恢复块,必须是合并文件的最后执行内容(触发 144 的 rm_startup)
# 用后台 backend 自杀 (kill -9) 触发 postmaster 崩溃恢复
crash_sql = r"""SET lock_timeout = 0;
SET statement_timeout = 0;
SHOW port \gset
SELECT current_setting('unix_socket_directories') AS sockdir \gset
\setenv PGPORT :port
\setenv PGHOST :sockdir
\setenv PGDATABASE regression
\! psql -c "SELECT pg_sleep(8)" >/dev/null 2>&1 &
SELECT pg_sleep(1);
\! P=$(psql -tA -c "SELECT pid FROM pg_stat_activity WHERE query LIKE '%pg_sleep(8)%' AND pid!=pg_backend_pid()" 2>/dev/null | head -1); kill -9 $P 2>/dev/null
SELECT pg_sleep(5);"""

d['150'] = [crash_sql]
json.dump(d, open('outputs/_improved_sql_v8.json', 'w'), ensure_ascii=False, indent=2)
print('150 crash-recovery block added')
print('preview:', repr(crash_sql[:120]))
