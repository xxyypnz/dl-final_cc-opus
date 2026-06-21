#!/usr/bin/env python3
"""
Build submission_301.json as a conservative compliant increment over 203.

Rules:
  - submission_203.json is the baseline and is preserved in full.
  - Only append a small set of standard-SQL probes for 108, 109 and 129.
  - Do not use psql meta-commands, file access, server-side COPY, external
    programs, privilege switching, DO blocks, C/internal languages, or loops.
"""
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


ADDITIONS = {
    "108": [
        """
DROP TABLE IF EXISTS c108_base CASCADE;
CREATE TABLE c108_base (id INT, val INT);
INSERT INTO c108_base VALUES (1, 10), (2, 20), (3, 30);
SELECT * FROM (
    SELECT id, val FROM c108_base
    UNION ALL
    SELECT id, val FROM c108_base
    UNION ALL
    SELECT id, val FROM c108_base
) AS u WHERE id > 1;
DROP TABLE c108_base CASCADE;
""",
        """
DROP TABLE IF EXISTS c108_t1, c108_t2 CASCADE;
CREATE TABLE c108_t1 (a int, b text);
CREATE TABLE c108_t2 (a int, b text);
INSERT INTO c108_t1 VALUES (1, 'x'), (2, 'y');
INSERT INTO c108_t2 VALUES (3, 'z'), (4, 'w');
SELECT a, COUNT(*) FROM (
    SELECT a, b FROM c108_t1
    UNION ALL
    SELECT a, b FROM c108_t2
    UNION ALL
    SELECT a, b FROM c108_t1
) s GROUP BY a ORDER BY a;
DROP TABLE c108_t1, c108_t2 CASCADE;
""",
    ],
    "109": [
        """
DROP TABLE IF EXISTS c109_t1, c109_t2, c109_outer CASCADE;
CREATE TABLE c109_t1(id int, val int);
CREATE TABLE c109_t2(id int, val int);
CREATE TABLE c109_outer(id int, data text);
INSERT INTO c109_t1 VALUES (1, 10), (2, 20), (3, 30);
INSERT INTO c109_t2 VALUES (2, 200), (3, 300), (4, 400);
INSERT INTO c109_outer VALUES (1, 'a'), (2, 'b'), (3, 'c');
ANALYZE c109_t1, c109_t2, c109_outer;
SELECT c109_outer.id, c109_outer.data, combined.val
FROM c109_outer
JOIN (
    SELECT id, val FROM c109_t1
    UNION ALL
    SELECT id, val FROM c109_t2
) AS combined(id, val)
ON c109_outer.id = combined.id
ORDER BY c109_outer.id;
DROP TABLE c109_t1, c109_t2, c109_outer CASCADE;
""",
        """
DROP TABLE IF EXISTS c109_a, c109_b, c109_c CASCADE;
CREATE TABLE c109_a(x int, y int);
CREATE TABLE c109_b(x int, y int);
CREATE TABLE c109_c(x int, z text);
INSERT INTO c109_a SELECT i, i*2 FROM generate_series(1,50) i;
INSERT INTO c109_b SELECT i, i*3 FROM generate_series(1,50) i;
INSERT INTO c109_c SELECT i, 'val'||i FROM generate_series(1,20) i;
ANALYZE c109_a, c109_b, c109_c;
SELECT c.x, c.z, u.y
FROM c109_c c
JOIN (
    SELECT x, y FROM c109_a WHERE y > 10
    UNION ALL
    SELECT x, y FROM c109_b WHERE y < 100
) u ON c.x = u.x
WHERE c.x < 15;
DROP TABLE c109_a, c109_b, c109_c CASCADE;
""",
        """
DROP TABLE IF EXISTS c109_p, c109_q, c109_r, c109_main CASCADE;
CREATE TABLE c109_p(k int, v int);
CREATE TABLE c109_q(k int, v int);
CREATE TABLE c109_r(k int, v int);
CREATE TABLE c109_main(k int, descr text);
INSERT INTO c109_p VALUES (1, 100), (2, 200);
INSERT INTO c109_q VALUES (2, 250), (3, 300);
INSERT INTO c109_r VALUES (3, 350), (4, 400);
INSERT INTO c109_main VALUES (1, 'alpha'), (2, 'beta'), (3, 'gamma');
ANALYZE c109_p, c109_q, c109_r, c109_main;
SELECT m.k, m.descr, combined.v
FROM c109_main m
JOIN (
    SELECT k, v FROM c109_p
    UNION ALL
    SELECT k, v FROM c109_q
    UNION ALL
    SELECT k, v FROM c109_r
) AS combined ON m.k = combined.k;
DROP TABLE c109_p, c109_q, c109_r, c109_main CASCADE;
""",
    ],
    "129": [
        """
DROP TABLE IF EXISTS c129_large, c129_small CASCADE;
CREATE TABLE c129_large AS
  SELECT i AS id, md5(i::text) AS data FROM generate_series(1, 5000) i;
CREATE TABLE c129_small AS
  SELECT i AS id, md5(i::text) AS data FROM generate_series(1, 2500) i;
ANALYZE c129_large, c129_small;
SET work_mem = '1MB';
SET enable_hashjoin = on;
SET enable_mergejoin = off;
SET enable_nestloop = off;
EXPLAIN ANALYZE
  SELECT COUNT(*) FROM c129_large JOIN c129_small USING (id);
RESET work_mem;
RESET enable_hashjoin;
RESET enable_mergejoin;
RESET enable_nestloop;
DROP TABLE c129_large, c129_small CASCADE;
""",
        """
DROP TABLE IF EXISTS c129_h1, c129_h2 CASCADE;
CREATE TABLE c129_h1(x int, y text);
CREATE TABLE c129_h2(x int, z text);
INSERT INTO c129_h1 SELECT i, 'row'||i FROM generate_series(1,1000) i;
INSERT INTO c129_h2 SELECT i, 'col'||i FROM generate_series(1,800) i;
ANALYZE c129_h1, c129_h2;
SET enable_hashjoin = on;
SET enable_mergejoin = off;
SET enable_nestloop = off;
EXPLAIN ANALYZE
  SELECT COUNT(*) FROM c129_h1 JOIN c129_h2 ON c129_h1.x = c129_h2.x;
RESET enable_hashjoin;
RESET enable_mergejoin;
RESET enable_nestloop;
DROP TABLE c129_h1, c129_h2 CASCADE;
""",
    ],
    "146": [
        """
DROP TABLE IF EXISTS c146_l, c146_r CASCADE;
CREATE TABLE c146_l (id int, val int);
CREATE TABLE c146_r (id int, val int);
INSERT INTO c146_l VALUES (1, 10), (2, 20), (3, 30);
INSERT INTO c146_r VALUES (2, 20), (3, 30), (4, 40);
CREATE INDEX c146_l_idx ON c146_l(id);
CREATE INDEX c146_r_idx ON c146_r(id);
ANALYZE c146_l, c146_r;
SET enable_hashjoin = off;
SET enable_nestloop = off;
SET enable_mergejoin = on;
SELECT * FROM c146_l FULL OUTER JOIN c146_r
  ON c146_l.id = c146_r.id AND FALSE;
RESET enable_hashjoin;
RESET enable_nestloop;
RESET enable_mergejoin;
DROP TABLE c146_l, c146_r CASCADE;
""",
    ],
}


def extract_blocks(text):
    return [b.strip() for b in re.findall(r"<sql>(.*?)</sql>", text, re.DOTALL | re.IGNORECASE)]


def wrap(blocks):
    parts = ["<test_cases>"]
    for i, block in enumerate(blocks, 1):
        parts.extend(
            [
                f'  <test_case id="{i}">',
                f"    <description>cov_{i}</description>",
                "    <sql>",
                block.strip(),
                "    </sql>",
                "  </test_case>",
            ]
        )
    parts.append("</test_cases>")
    return "\n".join(parts)


def main():
    submission = json.load(open("outputs/submission_203.json", encoding="utf-8"))
    appended = {}

    for item in submission:
        cid = str(item["id"])
        blocks = extract_blocks(item["generated_sql_tests"])
        if cid == "146":
            blocks = [
                block.replace(
                    "AS 91595 BEGIN RETURN CASE WHEN a > b THEN -1 WHEN a < b THEN 1 ELSE 0 END; END 91595",
                    "AS $cmp$ BEGIN RETURN CASE WHEN a > b THEN -1 WHEN a < b THEN 1 ELSE 0 END; END $cmp$",
                )
                for block in blocks
            ]
        seen = {b.strip() for b in blocks}

        for block in ADDITIONS.get(cid, []):
            clean = block.strip()
            if clean not in seen:
                blocks.append(clean)
                seen.add(clean)
                appended[cid] = appended.get(cid, 0) + 1

        item["generated_sql_tests"] = wrap(blocks)

    violations = []
    for item in submission:
        for idx, block in enumerate(extract_blocks(item["generated_sql_tests"]), 1):
            match = BANNED.search(block)
            if match:
                violations.append((item["id"], idx, match.group(0)))
    if violations:
        raise SystemExit(f"Banned constructs remain: {violations[:10]}")

    with open("outputs/submission_301.json", "w", encoding="utf-8") as f:
        json.dump(submission, f, ensure_ascii=False, indent=2)

    total_cases = sum(len(extract_blocks(item["generated_sql_tests"])) for item in submission)
    print("Wrote outputs/submission_301.json")
    print(f"Records: {len(submission)}")
    print(f"SQL cases: {total_cases}")
    print(f"Appended: {appended}")


if __name__ == "__main__":
    main()
