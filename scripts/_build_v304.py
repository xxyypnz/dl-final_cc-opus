#!/usr/bin/env python3
"""
Build submission_304.json: Conservative fix for Commit 135 only.

Changes from v203:
  - Commit 135 Case 4: Change "UNION ALL" to "UNION" (去重版本)
  - No other changes - preserve all v203 SQL

Expected: +1 line coverage (local 130/198, platform 126/198)
Risk: Minimal - only 1 keyword change
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


def extract_blocks(text):
    return [b.strip() for b in re.findall(r"<sql>(.*?)</sql>", text, re.DOTALL | re.IGNORECASE)]


def wrap(blocks):
    parts = ["<test_cases>"]
    for i, block in enumerate(blocks, 1):
        parts.extend([
            f'  <test_case id="{i}">',
            f"    <description>cov_{i}</description>",
            "    <sql>",
            block.strip(),
            "    </sql>",
            "  </test_case>",
        ])
    parts.append("</test_cases>")
    return "\n".join(parts)


def main():
    submission = json.load(open("outputs/submission_203.json", encoding="utf-8"))

    changes_made = 0

    for item in submission:
        cid = str(item["id"])
        blocks = extract_blocks(item["generated_sql_tests"])

        # 仅修改Commit 135的Case 4 (index 3)
        if cid == "135":
            if len(blocks) > 3:  # Case 4存在
                old_block = blocks[3]
                # 将 UNION ALL 改为 UNION (去重版本，可能触发不同的代码路径)
                new_block = re.sub(
                    r'\bUNION\s+ALL\b',
                    'UNION',
                    old_block,
                    flags=re.IGNORECASE
                )
                if new_block != old_block:
                    blocks[3] = new_block
                    changes_made += 1
                    print(f"✓ Modified Commit 135 Case 4: UNION ALL → UNION")

        item["generated_sql_tests"] = wrap(blocks)

    # 验证合规性
    violations = []
    for item in submission:
        for idx, block in enumerate(extract_blocks(item["generated_sql_tests"]), 1):
            match = BANNED.search(block)
            if match:
                violations.append((item["id"], idx, match.group(0)))

    if violations:
        print(f"\n❌ Found {len(violations)} violations:")
        for cid, idx, vio in violations[:5]:
            print(f"  Commit {cid} Case {idx}: {vio}")
        return 1

    # 保存
    with open("outputs/submission_304.json", "w", encoding="utf-8") as f:
        json.dump(submission, f, ensure_ascii=False, indent=2)

    print(f"\n✅ Created submission_304.json")
    print(f"   Changes: {changes_made} (Commit 135 only)")
    print(f"   Total records: {len(submission)}")
    print(f"   Zero violations")
    print()
    print("Next steps:")
    print("  1. python3 scripts/evaluate.py check outputs/submission_304.json --dataset data/test_v3.json")
    print("  2. GCOV_TOOL=gcov-11 bash run_local_eval.sh --submission outputs/submission_304.json --name v304 --skip-build")

    return 0


if __name__ == "__main__":
    exit(main())
