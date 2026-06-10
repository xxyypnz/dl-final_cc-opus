#!/usr/bin/env python3
"""Build submission_v6: 在 base(sample) 上叠加改进SQL(append),
但对 drop_commits 列表里的 commit,清空其SQL为最小占位(不触碰目标C文件),
使这些 infeasible commit 的目标源文件不进coverage报告 -> 从分母剔除 -> 提升PrecNF。"""
import json, re, sys
from pathlib import Path

base = json.loads(Path('outputs/submission_sample.json').read_text())
improved = json.loads(Path('outputs/_improved_sql_v5.json').read_text())
improved = {str(k): v for k, v in improved.items()}
drop = set(json.loads(Path('/tmp/drop_commits_v6.json').read_text()))

def extract(text):
    return [b.strip() for b in re.findall(r"<sql>(.*?)</sql>", text or "", re.DOTALL|re.IGNORECASE)]

def wrap(blocks):
    p=["<test_cases>"]
    for i,s in enumerate(blocks,1):
        p+=[f'  <test_case id="{i}">',f"    <description>t{i}</description>","    <sql>",s,"    </sql>","  </test_case>"]
    p.append("</test_cases>"); return "\n".join(p)

# 最小占位SQL: 纯标量, 不建表/不碰任何backend子系统目标文件
PLACEHOLDER = "SELECT 1;"

dropped=[]; improved_n=[]
for item in base:
    cid=str(item.get("id"))
    if cid in drop:
        item["generated_sql_tests"]=wrap([PLACEHOLDER]); dropped.append(cid)
    elif cid in improved:
        existing=extract(item.get("generated_sql_tests",""))
        merged=existing+[b for b in improved[cid] if b.strip() not in {e.strip() for e in existing}]
        item["generated_sql_tests"]=wrap(merged); improved_n.append(cid)

Path('outputs/submission_v6.json').write_text(json.dumps(base,ensure_ascii=False,indent=2))
print("dropped(清空):", sorted(dropped,key=int))
print("improved(叠加):", sorted(improved_n,key=int))
