#!/usr/bin/env python3
"""Build submission_v23.json: v22 base + v21 improved SQL (append mode)."""
import json, re
from pathlib import Path

ROOT = Path('/workspaces/dl-final_cc-opus/outputs')

base = json.loads((ROOT / 'submission_v22.json').read_text())
improved = json.loads((ROOT / '_improved_sql_v21.json').read_text())
improved = {str(k): v for k, v in improved.items()}

# REPLACE-mode commits: completely overwrite with improved blocks
REPLACE = set()

def extract(text):
    return [b.strip() for b in re.findall(r'<sql>(.*?)</sql>', text or '', re.DOTALL | re.IGNORECASE)]

def wrap(blocks):
    parts = ['<test_cases>']
    for i, sql in enumerate(blocks, 1):
        parts += [f'  <test_case id="{i}">', f'    <description>cov_{i}</description>',
                  '    <sql>', sql, '    </sql>', '  </test_case>']
    parts.append('</test_cases>')
    return '\n'.join(parts)

changed = []
for item in base:
    cid = str(item['id'])
    if cid not in improved:
        continue
    existing = extract(item.get('generated_sql_tests', ''))
    existing_set = {e.strip() for e in existing}
    new_blocks = [b.strip() for b in improved[cid] if b.strip() not in existing_set]
    if cid in REPLACE:
        merged = improved[cid]
    else:
        merged = existing + new_blocks
    item['generated_sql_tests'] = wrap(merged)
    changed.append(cid)

(ROOT / 'submission_v23.json').write_text(json.dumps(base, ensure_ascii=False, indent=2))
print(f'v23 written — updated {len(changed)} commits: {sorted(changed, key=int)}')

# Count stats
total_blocks = sum(
    len(extract(item['generated_sql_tests']))
    for item in base
)
print(f'Total SQL blocks across all commits: {total_blocks}')
