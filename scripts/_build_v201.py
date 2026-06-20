#!/usr/bin/env python3
r"""
Build submission_201.json: a fully COMPLIANT version of the submission.

Removes all banned constructs that the TA flagged (and which got scores cleared):
  \!, \i, base64, COPY PROGRAM, COPY server-file, LANGUAGE C/internal,
  lo_export/lo_import, pg_read_file, gcc/pg_config/.so, pg_ls_dir/adminpack,
  \gset, \setenv, shell echo.

Logic:
  - Start from outputs/submission_v23.json
  - For each commit, drop any <sql> block matching a banned pattern
  - If all blocks of a commit were dropped, replace with a harmless 'SELECT 1;'
r"""
import json, re

BANNED = re.compile(
    r'\\!|\\i\b|base64|COPY\s+.*PROGRAM|COPY\s+.*\s+(FROM|TO)\s+\'/'
    r"|LANGUAGE\s+'?c'?\b|LANGUAGE\s+internal|lo_(export|import)"
    r'|pg_read_file|pg_read_binary_file|\bgcc\b|pg_config|\.so\b'
    r'|pg_ls_dir|adminpack|\\gset|\\setenv|\\\s*echo',
    re.IGNORECASE,
)

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
        blocks = re.findall(r'<sql>(.*?)</sql>', item['generated_sql_tests'],
                            re.DOTALL | re.IGNORECASE)
        clean = [b for b in blocks if not BANNED.search(b)]
        item['generated_sql_tests'] = wrap(clean if clean else ['SELECT 1;'])
    json.dump(sub, open('outputs/submission_201.json', 'w'),
              ensure_ascii=False, indent=2)
    print(f'Wrote submission_201.json ({len(sub)} records, fully compliant)')

if __name__ == '__main__':
    main()
