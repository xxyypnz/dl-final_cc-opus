import json, re
from pathlib import Path
base=json.loads(Path('outputs/submission_sample.json').read_text())
improved={str(k):v for k,v in json.loads(Path('outputs/_improved_sql_v18.json').read_text()).items()}
REPLACE={'125','113','148','150'}
def extract(t): return [b.strip() for b in re.findall(r"<sql>(.*?)</sql>",t or "",re.DOTALL|re.IGNORECASE)]
def wrap(bs):
    p=["<test_cases>"]
    for i,s in enumerate(bs,1): p+=[f'  <test_case id="{i}">',f"    <description>t{i}</description>","    <sql>",s,"    </sql>","  </test_case>"]
    p.append("</test_cases>"); return "\n".join(p)
for item in base:
    cid=str(item['id'])
    if cid in improved:
        merged=improved[cid] if cid in REPLACE else extract(item.get('generated_sql_tests',''))+[b for b in improved[cid] if b.strip() not in {e.strip() for e in extract(item.get('generated_sql_tests',''))}]
        item['generated_sql_tests']=wrap(merged)
Path('outputs/submission_v18.json').write_text(json.dumps(base,ensure_ascii=False,indent=2))
print('v18 written')
