import json, re
from pathlib import Path

base = json.loads(Path('outputs/submission_sample.json').read_text())
improved = {str(k):v for k,v in json.loads(Path('outputs/_improved_sql_v7.json').read_text()).items()}
# 这些commit用replace(完全替换为improved,不保留sample旧块): 125(并发), 113(break)
REPLACE = {'125','113'}

def extract(t): return [b.strip() for b in re.findall(r"<sql>(.*?)</sql>", t or "", re.DOTALL|re.IGNORECASE)]
def wrap(bs):
    p=["<test_cases>"]
    for i,s in enumerate(bs,1): p+=[f'  <test_case id="{i}">',f"    <description>t{i}</description>","    <sql>",s,"    </sql>","  </test_case>"]
    p.append("</test_cases>"); return "\n".join(p)

for item in base:
    cid=str(item['id'])
    if cid in improved:
        if cid in REPLACE:
            merged=improved[cid]
        else:
            ex=extract(item.get('generated_sql_tests',''))
            merged=ex+[b for b in improved[cid] if b.strip() not in {e.strip() for e in ex}]
        item['generated_sql_tests']=wrap(merged)
Path('outputs/submission_v9.json').write_text(json.dumps(base,ensure_ascii=False,indent=2))
print('v9 written')
