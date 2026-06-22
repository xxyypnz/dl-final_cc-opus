#!/usr/bin/env python3
import json
import re


BANNED = re.compile(
    r"\\!|\\i\b|base64|COPY\s+.*PROGRAM|COPY\s+.*\s+(FROM|TO)\s+'/"
    r"|LANGUAGE\s+'?c'?\b|LANGUAGE\s+internal|lo_(export|import)"
    r"|pg_read_file|pg_read_binary_file|\bgcc\b|pg_config|\.so\b"
    r"|pg_ls_dir|adminpack|\\gset|\\setenv|\\\s*echo"
    r"|\bDO\s*\$|\bLOOP\b|\bWHILE\b"
    r"|SET\s+ROLE|SET\s+SESSION\s+AUTHORIZATION",
    re.IGNORECASE | re.DOTALL,
)


def extract_blocks(text):
    return [
        b.strip()
        for b in re.findall(r"<sql>(.*?)</sql>", text or "", re.DOTALL | re.IGNORECASE)
    ]


def wrap(blocks):
    parts = ["<test_cases>"]
    for i, block in enumerate(blocks, 1):
        parts += [
            f'  <test_case id="{i}">',
            f"    <description>cov_{i}</description>",
            "    <sql>",
            block.strip(),
            "    </sql>",
            "  </test_case>",
        ]
    parts.append("</test_cases>")
    return "\n".join(parts)


PROBES = [
    """
SET lock_timeout = '300ms';
SET statement_timeout = '1500ms';
DROP TABLE IF EXISTS c125_px CASCADE;
CREATE TABLE c125_px (id int primary key, v text) WITH (autovacuum_enabled = false);
INSERT INTO c125_px SELECT g, 'x' FROM generate_series(1, 20) g;
VACUUM c125_px;
BEGIN;
SELECT * FROM c125_px WHERE id = 1 FOR KEY SHARE;
PREPARE TRANSACTION 'c125_px_1';
BEGIN;
SELECT * FROM c125_px WHERE id = 1 FOR SHARE;
PREPARE TRANSACTION 'c125_px_2';
DELETE FROM c125_px WHERE id = 1;
ROLLBACK PREPARED 'c125_px_1';
ROLLBACK PREPARED 'c125_px_2';
DROP TABLE IF EXISTS c125_px CASCADE;
RESET lock_timeout;
RESET statement_timeout;
""",
    """
SET lock_timeout = 0;
SET statement_timeout = 0;
DROP TABLE IF EXISTS c125_sv CASCADE;
CREATE TABLE c125_sv (id int primary key, v text) WITH (autovacuum_enabled = false);
INSERT INTO c125_sv SELECT g, 'x' FROM generate_series(1, 20) g;
VACUUM c125_sv;
BEGIN;
SELECT * FROM c125_sv WHERE id = 1 FOR KEY SHARE;
SAVEPOINT c125_sv_s1;
SELECT * FROM c125_sv WHERE id = 1 FOR SHARE;
SAVEPOINT c125_sv_s2;
DELETE FROM c125_sv WHERE id = 1;
ROLLBACK TO c125_sv_s1;
COMMIT;
DROP TABLE IF EXISTS c125_sv CASCADE;
""",
    """
DROP FUNCTION IF EXISTS c125_lock_row(int) CASCADE;
DROP TABLE IF EXISTS c125_pw CASCADE;
CREATE TABLE c125_pw (id int primary key, v text) WITH (autovacuum_enabled = false);
INSERT INTO c125_pw SELECT g, 'x' FROM generate_series(1, 20000) g;
VACUUM c125_pw;
CREATE FUNCTION c125_lock_row(i int) RETURNS int
LANGUAGE SQL PARALLEL SAFE AS
$$
  SELECT id FROM c125_pw WHERE id = i FOR SHARE;
  SELECT i;
$$;
SET force_parallel_mode = on;
SET parallel_setup_cost = 0;
SET parallel_tuple_cost = 0;
SET min_parallel_table_scan_size = 0;
SET parallel_leader_participation = off;
SET max_parallel_workers_per_gather = 4;
BEGIN;
SELECT sum(c125_lock_row(1)) FROM generate_series(1, 20000) g;
DELETE FROM c125_pw WHERE id = 1;
COMMIT;
RESET force_parallel_mode;
RESET parallel_setup_cost;
RESET parallel_tuple_cost;
RESET min_parallel_table_scan_size;
RESET parallel_leader_participation;
RESET max_parallel_workers_per_gather;
DROP FUNCTION IF EXISTS c125_lock_row(int) CASCADE;
DROP TABLE IF EXISTS c125_pw CASCADE;
""",
]


def main():
    with open("outputs/submission_303.json", encoding="utf-8") as f:
        submission = json.load(f)

    for item in submission:
        if str(item["id"]) == "125":
            blocks = extract_blocks(item["generated_sql_tests"])
            item["generated_sql_tests"] = wrap(PROBES + blocks)
            break

    violations = []
    for item in submission:
        for idx, block in enumerate(extract_blocks(item["generated_sql_tests"]), 1):
            match = BANNED.search(block)
            if match:
                violations.append((item["id"], idx, match.group(0)))
    if violations:
        raise SystemExit(f"Banned constructs remain: {violations[:10]}")

    with open("outputs/submission_306_probe125_alt.json", "w", encoding="utf-8") as f:
        json.dump(submission, f, ensure_ascii=False, indent=2)
    print("Wrote outputs/submission_306_probe125_alt.json")


if __name__ == "__main__":
    main()
