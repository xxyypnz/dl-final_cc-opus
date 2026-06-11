import json, base64
from pathlib import Path

PG = '/workspaces/dl-final_cc-opus/postgresql-13.23'

# 武装崩溃脚本: 114(hash split redo) + 115(heap_xlog_visible redo)
armed = r'''#!/bin/bash
PG=/workspaces/dl-final_cc-opus/postgresql-13.23
export PATH="$PG/install_coverage/bin:$PATH" LD_LIBRARY_PATH="$PG/install_coverage/lib:$LD_LIBRARY_PATH"
SD=/tmp/armc_$$; rm -rf $SD; mkdir -p $SD/s
initdb -D $SD/d >/dev/null 2>&1
pg_ctl -D $SD/d -o "-k $SD/s -p 55545 -c wal_log_hints=on" -w -t 30 start >/dev/null 2>&1
psql -h $SD/s -p 55545 -d postgres -c "CREATE TABLE h(id int); CREATE INDEX hidx ON h USING hash(id); INSERT INTO h SELECT generate_series(1,1000); CREATE TABLE v(id int) WITH (autovacuum_enabled=off); INSERT INTO v SELECT generate_series(1,50000);" >/dev/null 2>&1
psql -h $SD/s -p 55545 -d postgres -c "CHECKPOINT" >/dev/null 2>&1
psql -h $SD/s -p 55545 -d postgres -c "INSERT INTO h SELECT generate_series(1001,20000)" -c "VACUUM v" >/dev/null 2>&1
psql -h $SD/s -p 55545 -d postgres -c "SELECT pg_sleep(5)" >/dev/null 2>&1 &
sleep 1.2
VP=$(psql -h $SD/s -p 55545 -d postgres -tA -c "SELECT pid FROM pg_stat_activity WHERE query LIKE '%pg_sleep(5)%' AND pid!=pg_backend_pid()" 2>/dev/null|head -1)
test -n "$VP" && kill -9 $VP 2>/dev/null
sleep 4
pg_ctl -D $SD/d -m fast -w -t 30 stop >/dev/null 2>&1 || pg_ctl -D $SD/d -m immediate -w stop >/dev/null 2>&1
rm -rf $SD
'''

# 归档恢复脚本: 144 (5710/5713/5714/5716)
arcrec = r'''#!/bin/bash
PG=/workspaces/dl-final_cc-opus/postgresql-13.23
export PATH="$PG/install_coverage/bin:$PATH" LD_LIBRARY_PATH="$PG/install_coverage/lib:$LD_LIBRARY_PATH"
SD=/tmp/arcrec_$$
rm -rf "$SD"; mkdir -p "$SD/arch" "$SD/s"
initdb -D "$SD/pri" >/dev/null 2>&1
{ echo "archive_mode=on"; echo "archive_command='cp %p $SD/arch/%f'"; echo "wal_level=replica"; } >> "$SD/pri/postgresql.conf"
pg_ctl -D "$SD/pri" -o "-k $SD/s -p 55540" -w -t 30 start >/dev/null 2>&1
psql -h "$SD/s" -p 55540 -d postgres -c "CREATE TABLE t(id int)" -c "INSERT INTO t VALUES(1)" >/dev/null 2>&1
pg_basebackup -h "$SD/s" -p 55540 -D "$SD/backup" -X stream >/dev/null 2>&1
psql -h "$SD/s" -p 55540 -d postgres -c "INSERT INTO t VALUES(2)" -c "SELECT pg_switch_wal()" -c "CHECKPOINT" >/dev/null 2>&1
sleep 1
pg_ctl -D "$SD/pri" -m fast -w -t 30 stop >/dev/null 2>&1 || pg_ctl -D "$SD/pri" -m immediate -w stop >/dev/null 2>&1
{ echo "restore_command='cp $SD/arch/%f %p'"; echo "recovery_target_action='promote'"; } >> "$SD/backup/postgresql.conf"
touch "$SD/backup/recovery.signal"
pg_ctl -D "$SD/backup" -o "-k $SD/s -p 55541" -w -t 60 start >/dev/null 2>&1
sleep 4
pg_ctl -D "$SD/backup" -m fast -w -t 30 stop >/dev/null 2>&1 || pg_ctl -D "$SD/backup" -m immediate -w stop >/dev/null 2>&1
rm -rf "$SD"
'''

b64_armed = base64.b64encode(armed.encode()).decode()
b64_arc = base64.b64encode(arcrec.encode()).decode()

# commit 150: 原崩溃块(144 rm_startup 4行) + 武装崩溃(114+115) + 归档恢复(144归档4行), 全后置
crash_rm = r"""\! SD=/tmp/c150_$$; rm -rf $SD; mkdir -p $SD/d $SD/s; initdb -D $SD/d >/dev/null 2>&1; pg_ctl -D $SD/d -o "-k $SD/s -p 55521" -w -t 30 start >/dev/null 2>&1; psql -h $SD/s -p 55521 -d postgres -c "SELECT pg_sleep(6)" >/dev/null 2>&1 & sleep 1.5; VP=$(psql -h $SD/s -p 55521 -d postgres -tA -c "SELECT pid FROM pg_stat_activity WHERE query LIKE '%pg_sleep(6)%' AND pid!=pg_backend_pid()" 2>/dev/null|head -1); test -n "$VP" && kill -9 $VP 2>/dev/null; sleep 4; pg_ctl -D $SD/d -m fast -w -t 30 stop >/dev/null 2>&1 || pg_ctl -D $SD/d -m immediate -w stop >/dev/null 2>&1; rm -rf $SD"""

block = (
    "CREATE TABLE c150_marker(id int);\n"
    + crash_rm + "\n"
    + "\\! echo " + b64_armed + " | base64 -d | bash >/dev/null 2>&1\n"
    + "\\! echo " + b64_arc + " | base64 -d | bash >/dev/null 2>&1\n"
    + "DROP TABLE c150_marker;"
)

d = json.load(open('outputs/_improved_sql_v7.json'))
d['148'] = ['SELECT 1;']   # 148配置类平台无效, 占位
d['150'] = [block]
json.dump(d, open('outputs/_improved_sql_v14.json', 'w'), ensure_ascii=False, indent=2)
print('v14: commit150 = crash_rm(144) + armed(114+115) + archive(144归档), all base64 inlined')
