#!/usr/bin/env python3
"""分析本地评测结果，输出按优化优先级排序的 commit 清单。

用法:
  python3 scripts/analyze_result.py outputs/local_eval/baseline/eval_result.json

输出:
  - 全局 summary (PrecNF 等)
  - 每个 commit: matched / covered / not_found / precNF / 未覆盖目标行
  - 按"可提升空间" (matched-not_found-covered) 降序排，告诉你改哪个最值
"""
import json
import sys
from pathlib import Path


def main(result_path: str, show_lines: bool = True) -> None:
    data = json.loads(Path(result_path).read_text(encoding="utf-8"))
    summary = data["summary"]
    results = data["results"]

    print("=" * 80)
    print("GLOBAL SUMMARY")
    print("=" * 80)
    for k in (
        "n_items",
        "total_meaningful_added",
        "total_matched",
        "total_not_found",
        "total_covered",
        "global_recall",
        "global_precision",
        "global_precision_excl_not_found",
    ):
        marker = "  <== PrecNF (主指标)" if k == "global_precision_excl_not_found" else ""
        print(f"  {k:38} {summary.get(k)}{marker}")

    rows = []
    for iid, r in results.items():
        matched = r["total_matched"]
        nf = r["not_found"]
        covered = r["covered"]
        denom = matched - nf
        # 还能再覆盖多少行 (分母内未覆盖)
        headroom = denom - covered
        rows.append((iid, matched, nf, covered, denom, headroom, r))

    # 按可提升空间降序：改这些最划算
    rows.sort(key=lambda t: -t[5])

    print("\n" + "=" * 80)
    print("PER-COMMIT (按可提升空间 headroom 降序 = 优化性价比)")
    print("=" * 80)
    print(f"{'id':>4} {'matched':>7} {'notfnd':>6} {'cover':>5} {'denom':>5} {'head':>4} {'precNF':>6}  subject")
    print("-" * 80)
    for iid, matched, nf, covered, denom, headroom, r in rows:
        pnf = r.get("precision_excl_not_found", 0.0)
        subj = r.get("subject", "")[:40]
        flag = "***" if headroom >= 3 else "   "
        print(f"{iid:>4} {matched:>7} {nf:>6} {covered:>5} {denom:>5} {headroom:>4} {pnf:>6} {flag} {subj}")

    if show_lines:
        print("\n" + "=" * 80)
        print("未覆盖目标行清单 (covered=False 且在分母内) — 优化时直接对照")
        print("=" * 80)
        for iid, matched, nf, covered, denom, headroom, r in rows:
            if headroom <= 0:
                continue
            uncovered = [
                ld
                for ld in r.get("line_details", [])
                if not ld.get("covered")
                and ld.get("match_type") not in ("gcov_not_found", "not_found")
            ]
            if not uncovered:
                continue
            print(f"\n--- commit {iid} ({r.get('subject','')[:50]}) headroom={headroom} ---")
            for ld in uncovered:
                print(f"  {ld['file']}:{ld.get('gcov_line_no') or ld['line_no']}  {ld['code'].strip()[:80]}")


if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else "outputs/local_eval/baseline/eval_result.json"
    main(path)
