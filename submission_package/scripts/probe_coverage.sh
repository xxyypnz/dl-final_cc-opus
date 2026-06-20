#!/bin/bash
# 快速覆盖率探针: 复用已编译的 PG(gcno保留),只跑指定SQL并对单个源文件做gcov,
# 输出指定行号的执行次数。用于精准迭代单个commit,避免30min全量评测。
#
# 用法: probe_coverage.sh <sql_file> <source_rel_path> <line1,line2,...>
# 例:   probe_coverage.sh /tmp/t.sql src/backend/utils/adt/ruleutils.c 10547,10553,10569
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PG_SRC="${TOOLKIT_DIR}/postgresql-13.23"
PG_INST="${PG_SRC}/install_coverage"
PORT="${PORT:-55440}"
SOCK="/tmp/pgcov-probe-${PORT}"
DATADIR="/tmp/pgprobe-${PORT}/data"

SQL_FILE="$1"; SRC_REL="$2"; LINES="$3"
[ -f "$SQL_FILE" ] || { echo "no sql file: $SQL_FILE"; exit 1; }

export PATH="$PG_INST/bin:$PATH"
export LD_LIBRARY_PATH="$PG_INST/lib:$LD_LIBRARY_PATH"

# 清理旧 gcda,确保计数只来自本次
find "$PG_SRC" -name '*.gcda' -delete

rm -rf "$DATADIR"; mkdir -p "$DATADIR" "$SOCK"
initdb -D "$DATADIR" >/dev/null 2>&1
pg_ctl -D "$DATADIR" -l /tmp/pgprobe-${PORT}/server.log -o "-k $SOCK -p $PORT" -w start >/dev/null 2>&1
createdb -h "$SOCK" -p "$PORT" regression >/dev/null 2>&1

psql -h "$SOCK" -p "$PORT" -d regression -f "$SQL_FILE" > /tmp/pgprobe-${PORT}/psql.log 2>&1 || true
ERRS=$(grep -c "ERROR:" /tmp/pgprobe-${PORT}/psql.log || true)

pg_ctl -D "$DATADIR" -m fast -w stop >/dev/null 2>&1
sleep 1

# gcov 目标源文件
SRC_DIR="$(dirname "$PG_SRC/$SRC_REL")"
SRC_BASE="$(basename "$SRC_REL")"
cd "$SRC_DIR"
"${GCOV_TOOL:-gcov-13}" -o . "$SRC_BASE" >/dev/null 2>&1 || true
GCOV_OUT="$SRC_DIR/${SRC_BASE}.gcov"

echo "=== probe: $SRC_REL  (SQL errors: ${ERRS:-0}) ==="
if [ ! -f "$GCOV_OUT" ]; then echo "no gcov output (file not exercised at all)"; exit 0; fi
IFS=',' read -ra LARR <<< "$LINES"
for ln in "${LARR[@]}"; do
    # gcov 行格式: "   <count>:  <lineno>:<code>"。用 awk 取第二个冒号字段==行号,不改字段避免重建丢冒号。
    row=$(awk -F: -v L="$ln" 'function trim(s){gsub(/^[ \t]+|[ \t]+$/,"",s);return s} trim($2)==L {print; exit}' "$GCOV_OUT")
    cnt=$(printf "%s" "$row" | awk -F: '{gsub(/^[ \t]+|[ \t]+$/,"",$1); print $1}')
    code=$(printf "%s" "$row" | cut -d: -f3-)
    case "$cnt" in
        "#####") status="NOT covered (0)";;
        "-")     status="non-exec line";;
        "")      status="line not found";;
        *)       status="COVERED (${cnt})";;
    esac
    printf "  L%-6s %-22s | %s\n" "$ln" "$status" "$(printf '%s' "$code" | sed 's/^[[:space:]]*//' | cut -c1-60)"
done
# 清理
rm -rf /tmp/pgprobe-${PORT} "$SOCK" 2>/dev/null || true
find "$PG_SRC" -name '*.gcda' -delete 2>/dev/null || true
