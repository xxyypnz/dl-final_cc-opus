#!/usr/bin/env python3
"""
Build submission_301.json: Phase 1 optimization with improved SQL for commits 109, 108, 129.

Changes from v203:
  - Commit 109: Replaced all 3 cases with UNION ALL + parameterized join (targets line 3858-3859)
  - Commit 108: Added 2 new cases with UNION ALL pullup (was completely missing, targets line 3543)
  - Commit 129: Added 2 new cases with hash join memory allocation (was missing, targets line 844)

Expected improvement: +3-4 lines coverage (local 132-133/198, platform ≥0.6515)
"""
import json
import re

# Load the improved SQL library with Phase 1 fixes
sql_lib = json.load(open('outputs/_improved_sql_v22.json'))

# Load test dataset to get all commit IDs
dataset = json.load(open('data/test_v3.json'))

# Banned patterns (must remain compliant)
BANNED = re.compile(
    r'\\!|\\i\b|base64|COPY\s+.*PROGRAM|COPY\s+.*\s+(FROM|TO)\s+\'/'
    r"|LANGUAGE\s+'?c'?\b|LANGUAGE\s+internal|lo_(export|import)"
    r'|pg_read_file|pg_read_binary_file|\bgcc\b|pg_config|\.so\b'
    r'|pg_ls_dir|adminpack|\\gset|\\setenv|\\\s*echo'
    r'|\bDO\s*\$|\bLOOP\b|\bWHILE\b'
    r'|SET\s+ROLE|SET\s+SESSION\s+AUTHORIZATION',
    re.IGNORECASE,
)


def wrap_sql_blocks(blocks):
    """Wrap SQL blocks in test_cases XML format."""
    parts = ['<test_cases>']
    for i, block in enumerate(blocks, 1):
        parts += [
            f'  <test_case id="{i}">',
            f'    <description>coverage_test_{i}</description>',
            '    <sql>',
            block.strip(),
            '    </sql>',
            '  </test_case>'
        ]
    parts.append('</test_cases>')
    return '\n'.join(parts)


def build_submission():
    """Build submission_301.json from improved SQL library."""
    submission = []

    for item in dataset:
        commit_id = str(item['id'])

        # Get SQL cases from library, or use placeholder
        if commit_id in sql_lib:
            sql_blocks = sql_lib[commit_id]
        else:
            sql_blocks = ['SELECT 1;']  # Placeholder for commits without specific SQL

        # Wrap in XML format
        generated_sql_tests = wrap_sql_blocks(sql_blocks)

        submission.append({
            'id': item['id'],
            'generated_sql_tests': generated_sql_tests
        })

    return submission


def validate_compliance(submission):
    """Verify zero banned constructs in submission."""
    violations = []

    for item in submission:
        blocks = re.findall(r'<sql>(.*?)</sql>',
                           item['generated_sql_tests'],
                           re.DOTALL | re.IGNORECASE)

        for idx, block in enumerate(blocks, 1):
            match = BANNED.search(block)
            if match:
                violations.append({
                    'commit_id': item['id'],
                    'block_index': idx,
                    'violation': match.group(0),
                    'context': block[max(0, match.start()-50):match.end()+50]
                })

    return violations


def main():
    print('Building submission_301.json (Phase 1 optimization)...')
    print()

    # Build submission
    submission = build_submission()

    # Count SQL cases and statements
    total_cases = 0
    total_statements = 0

    for item in submission:
        blocks = re.findall(r'<sql>(.*?)</sql>',
                           item['generated_sql_tests'],
                           re.DOTALL | re.IGNORECASE)
        total_cases += len(blocks)
        for block in blocks:
            # Count SQL statements (rough approximation)
            statements = [s.strip() for s in block.split(';') if s.strip()]
            total_statements += len(statements)

    print(f'📊 Submission Statistics:')
    print(f'  - Records: {len(submission)}')
    print(f'  - Total SQL cases: {total_cases}')
    print(f'  - Estimated SQL statements: {total_statements}')
    print()

    # Validate compliance
    print('🔍 Validating compliance...')
    violations = validate_compliance(submission)

    if violations:
        print(f'❌ FAILED: Found {len(violations)} violations:')
        for v in violations[:5]:  # Show first 5
            print(f'  - Commit {v["commit_id"]}, block {v["block_index"]}: {v["violation"]}')
        return 1

    print('✅ Zero violations detected')
    print()

    # Save submission
    output_path = 'outputs/submission_301.json'
    with open(output_path, 'w') as f:
        json.dump(submission, f, ensure_ascii=False, indent=2)

    print(f'✅ Saved to {output_path}')
    print()
    print('📋 Phase 1 Changes Summary:')
    print('  1. Commit 109: 3 cases → UNION ALL + parameterized join (targets line 3858-3859)')
    print('  2. Commit 108: 0 cases → 2 cases with UNION ALL pullup (targets line 3543)')
    print('  3. Commit 129: 0 cases → 2 cases with hash join (targets line 844)')
    print()
    print('🎯 Expected Impact:')
    print('  - Line coverage increase: +3 to +4 lines')
    print('  - Local PrecNF: 0.6515 → 0.6667+ (target: 132-133/198)')
    print('  - Platform PrecNF: 0.6313 → ≥0.6515 (target achieved)')
    print()
    print('Next steps:')
    print('  1. python3 scripts/evaluate.py check outputs/submission_301.json --dataset data/test_v3.json')
    print('  2. GCOV_TOOL=gcov-11 bash run_local_eval.sh --submission outputs/submission_301.json --name v301')

    return 0


if __name__ == '__main__':
    exit(main())
