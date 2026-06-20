#!/usr/bin/env python3
r"""
Build submission_203.json: the fully COMPLIANT final submission.

Removes EVERY banned construct the TA flagged across all rounds (each of which
got scores cleared / submissions rejected on the platform):
  \!, \i, base64, COPY PROGRAM, COPY server-file, LANGUAGE C/internal,
  lo_export/lo_import, pg_read_file, gcc/pg_config/.so, pg_ls_dir/adminpack,
  \gset, \setenv, shell echo,
  DO blocks (can build long-running loops), LOOP, WHILE,
  SET ROLE / SET SESSION AUTHORIZATION (privilege switching).

Pipeline of platform feedback this script encodes:
  v201 -> rejected: "id=101 第19个 <sql> 含禁止语句: 禁止 DO 代码块"
  v202 -> rejected: "id=112 第1个 <sql> 含禁止语句: 禁止 SET ROLE"
  v203 -> accepted, platform PrecNF = 0.6313 (local gcc-11 = 130/198 = 0.6566)

Logic:
  - Start from outputs/submission_v23.json (the 0.7525 non-compliant base)
  - Drop any <sql> block matching a banned pattern
  - For commit 101, replace the DO-block alias test with an equivalent plain
    UPDATE ... AS u ... RETURNING u.* (same coverage, no DO block)
  - For commit 112, replace the SET ROLE permission tests with plain
    VACUUM/ANALYZE as superuser (the non-owner WARNING line is unreachable
    without privilege switching, which is banned)
  - If all blocks of a commit were dropped, replace with a harmless 'SELECT 1;'

Note: commit 109 in the shipped submission_203.json carries one extra probe
block that was added incrementally on top of v202; rebuilding purely from v23
yields 6 blocks for 109 instead of 7. Both are compliant and cover the same
lines (109's gap lines stay uncovered either way) -- the shipped file is the
ground truth.
"""
import json, re

BANNED = re.compile(
    r'\\!|\\i\b|base64|COPY\s+.*PROGRAM|COPY\s+.*\s+(FROM|TO)\s+\'/'
    r"|LANGUAGE\s+'?c'?\b|LANGUAGE\s+internal|lo_(export|import)"
    r'|pg_read_file|pg_read_binary_file|\bgcc\b|pg_config|\.so\b'
    r'|pg_ls_dir|adminpack|\\gset|\\setenv|\\\s*echo'
    r'|\bDO\s*\$|\bLOOP\b|\bWHILE\b'
    r'|SET\s+ROLE|SET\s+SESSION\s+AUTHORIZATION',
    re.IGNORECASE,
)

# Compliant replacements for blocks that would otherwise be dropped entirely.
REPLACE_101 = (
    "DROP TABLE IF EXISTS c101_upd2 CASCADE;\n"
    "CREATE TABLE c101_upd2 (id int, v text);\n"
    "INSERT INTO c101_upd2 VALUES (1,'a'),(2,'b');\n"
    "UPDATE c101_upd2 AS u SET v='x' WHERE u.id=1 RETURNING u.*;\n"
    "SELECT * FROM c101_upd2 ORDER BY id;\n"
    "DROP TABLE IF EXISTS c101_upd2 CASCADE;"
)
REPLACE_112 = [
    ("DROP TABLE IF EXISTS c112_vac CASCADE;\n"
     "CREATE TABLE c112_vac (id int);\n"
     "INSERT INTO c112_vac SELECT generate_series(1,100);\n"
     "VACUUM c112_vac;\n"
     "ANALYZE c112_vac;\n"
     "VACUUM (ANALYZE) c112_vac;\n"
     "DROP TABLE IF EXISTS c112_vac CASCADE;"),
    ("VACUUM pg_catalog.pg_class;\n"
     "ANALYZE pg_catalog.pg_class;\n"
     "VACUUM (ANALYZE) pg_catalog.pg_class;"),
]


def wrap(blocks):
    parts = ['<test_cases>']
    for i, b in enumerate(blocks, 1):
        parts += [f'  <test_case id="{i}">',
                  f'    <description>cov_{i}</description>',
                  '    <sql>', b.strip(), '    </sql>',
                  '  </test_case>']
    parts.append('</test_cases>')
    return '\n'.join(parts)


def main():
    sub = json.load(open('outputs/submission_v23.json'))
    for item in sub:
        cid = str(item['id'])
        blocks = re.findall(r'<sql>(.*?)</sql>', item['generated_sql_tests'],
                            re.DOTALL | re.IGNORECASE)
        if cid == '112':
            clean = list(REPLACE_112)
        else:
            clean = []
            for b in blocks:
                if not BANNED.search(b):
                    clean.append(b)
                elif cid == '101' and 'c101_upd2' in b:
                    clean.append(REPLACE_101)  # swap DO block for plain UPDATE
                # else: drop the banned block
        item['generated_sql_tests'] = wrap(clean if clean else ['SELECT 1;'])

    # final assertion: zero violations
    viol = []
    for item in sub:
        for i, b in enumerate(re.findall(r'<sql>(.*?)</sql>',
                                         item['generated_sql_tests'], re.DOTALL), 1):
            m = BANNED.search(b)
            if m:
                viol.append((item['id'], i, m.group(0)))
    assert not viol, f'BANNED constructs remain: {viol}'

    json.dump(sub, open('outputs/submission_203.json', 'w'),
              ensure_ascii=False, indent=2)
    print(f'Wrote submission_203.json ({len(sub)} records, 0 violations)')


if __name__ == '__main__':
    main()
