#!/usr/bin/env python3
"""Build a versioned submission by overlaying improved SQL blocks onto a base submission.

Usage:
  python3 scripts/build_submission.py --base outputs/submission_sample.json \
      --improved outputs/_improved_sql_v1.json --out outputs/submission_v1.json

The improved file is {commit_id(str): [sql_block, ...]}. For each listed id we
REPLACE that commit's generated_sql_tests with freshly-wrapped <test_cases>.
Commits not listed are copied unchanged from the base.
"""
import argparse
import json
import re
from pathlib import Path
from xml.sax.saxutils import escape


def extract_sql_blocks(text):
    return [b.strip() for b in re.findall(r"<sql>(.*?)</sql>", text or "", re.DOTALL | re.IGNORECASE)]


def wrap_test_cases(sql_blocks):
    parts = ["<test_cases>"]
    for i, sql in enumerate(sql_blocks, start=1):
        parts.append(f'  <test_case id="{i}">')
        parts.append(f"    <description>Coverage test {i}</description>")
        parts.append("    <sql>")
        parts.append(sql)
        parts.append("    </sql>")
        parts.append("  </test_case>")
    parts.append("</test_cases>")
    return "\n".join(parts)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", required=True)
    ap.add_argument("--improved", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--mode", choices=["replace", "append"], default="append",
                    help="append: keep base SQL blocks and add improved ones; replace: overwrite")
    args = ap.parse_args()

    base = json.loads(Path(args.base).read_text(encoding="utf-8"))
    improved = json.loads(Path(args.improved).read_text(encoding="utf-8"))
    improved = {str(k): v for k, v in improved.items()}

    changed = []
    for item in base:
        cid = str(item.get("id"))
        if cid in improved:
            if args.mode == "append":
                existing = extract_sql_blocks(item.get("generated_sql_tests", ""))
                # de-dup: skip improved blocks identical to an existing one
                merged = existing + [b for b in improved[cid] if b.strip() not in {e.strip() for e in existing}]
            else:
                merged = improved[cid]
            item["generated_sql_tests"] = wrap_test_cases(merged)
            changed.append(cid)

    Path(args.out).write_text(json.dumps(base, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"wrote {args.out} (mode={args.mode})")
    print(f"updated {len(changed)} commits: {sorted(changed, key=int)}")


if __name__ == "__main__":
    main()
