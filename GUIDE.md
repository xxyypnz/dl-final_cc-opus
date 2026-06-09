# 项目理解与完成路径指南 (GUIDE.md)

> 本文件由代码梳理生成，帮助你快速理解整个项目并规划完成路径。
> 权威说明仍以 `README.md` 为准；本文是“地图 + 路线”。

---

## 1. 一句话目标

针对 50 个 PostgreSQL 内核 commit（`data/test_v3.json`），**为每个 commit 生成一组 SQL 测试用例**，使这些 SQL 在执行时尽可能**覆盖该 commit 新增/修改的 C 代码行**，最终产出 `outputs/submission.json` 上传到打榜平台。

这本质上是一个 **Prompt Engineering / 测试用例生成** 任务，核心难点是“读懂 C diff → 反推出能触发该代码路径的 SQL”。

---

## 2. 评分机制（最重要，决定一切策略）

平台用两个指标排序：

| 指标 | 方向 | 含义 |
|---|---|---|
| `PrecNF` (= `global_precision_excl_not_found`) | 越大越好（主排序） | 被覆盖的目标行 / (能定位到的目标行 - 找不到的行) |
| `efficiency` | 越小越好（同分时的 tie-break） | `(sql_count ^ 0.35) / (PrecNF * 100)` |

关键推论（来自 `scripts/evaluate.py`）：

1. **核心指标是 Precision，不是 Recall。**
   `PrecNF = total_covered / (total_matched - total_not_found)`。
   分母是“能在 gcov 报告里定位到的目标行数”。也就是说：**只要你的 SQL 命中了目标代码行，就加分；没命中就拉低分母外的覆盖率。**

2. **目标行是怎么算的？** 见 `count_meaningful_added()` 和 `collect_matched_lines()`：
   - 从 commit 的 `patches[].diff_blocks[].added` 取新增行；
   - 排除注释 (`is_comment`)、变量声明 (`is_declaration`)、平凡行 (`TRIVIAL`：`{}`、`}`、`return`)；
   - 再用 `match_info` 把这些行对齐到源码行号；
   - 评测时去 `coverage_workspace/report/<file>.gcov.html` 查这些行的执行次数 > 0 即“covered”。

3. **`efficiency` 惩罚 SQL 数量，但很弱（0.35 次方）。**
   SQL 数从 10 → 100，惩罚只增加约 `100^0.35 / 10^0.35 ≈ 2.24` 倍。
   → 策略上：**优先把 PrecNF 拉高**（它在分母且 ×100），SQL 数量适度控制即可，不要为省几条 SQL 牺牲覆盖。但也别无脑灌一堆无效 SQL。

4. **报错的 SQL（`ERROR:`）不贡献覆盖，但不直接扣分**，只是浪费 case 配额和时间。语法必须正确、对象必须自包含。

> `sql_count` 的计数规则很讲究（`count_sql_statements`）：按**顶层分号**拆，忽略注释/字符串/`$$ dollar-quote $$`里的分号。写 PL/pgSQL 函数体不会被算成多条。

---

## 3. 数据结构速查

### `data/test_v3.json` — 50 条，你要为它们生成 SQL
每条记录：
```
id              唯一标识（提交时必须用同一个 id）
subject         commit 标题
email_body      commit 描述
patches[]       代码 diff
  ├ file        改动文件，如 src/backend/optimizer/...
  ├ raw_diff    原始 diff 文本（喂给模型的主要材料）
  └ diff_blocks[] { added:[...], removed:[...] }  ← 评分目标行来自 added
match_info      行级匹配信息（评测用，把 diff 行对齐到源码行号；你生成时一般不用动）
```

### `data/train.json` — 100 条，比测试集**多一个 `generated_sql_tests` 字段**
这是金矿：
- 可作为 **few-shot 示例**（“这种 diff → 这种 SQL”）；
- 可作为 **SFT 微调样本**；
- 可用来**校准 prompt 风格**（看官方示例 SQL 长什么样、覆盖哪些路径）。

### 提交格式 `outputs/submission.json`
顶层数组，每项 `{ "id": ..., "generated_sql_tests": "<test_cases>...<sql>...</sql>...</test_cases>" }`。
平台只提取 `<sql>...</sql>` 里的内容执行。SQL 必须自包含：建表 → 插数据 → 执行目标语句 → 清理。

---

## 4. 代码地图（每个文件干什么）

| 文件 | 作用 | 你会怎么用 |
|---|---|---|
| `scripts/generate_submission.py` | 调 ChatECNU API，按 prompt 模板逐 commit 生成 SQL，**带断点续跑**（`load_progress`） | 主力生成入口；改 prompt / 参数都在这 |
| `scripts/evaluate.py` | 统一评测器：`check`(格式校验) / `extract`(抽 SQL) / `metrics`(算分) / `platform`(端到端) | `check` 高频用；`metrics` 看本地分 |
| `scripts/evaluate_coverage.sh` | 编译 PG → 跑 SQL → gcov/lcov/genhtml 收覆盖率 → 调 evaluate.py 算分 | 完整本地评测才用，依赖重 |
| `run_local_eval.sh` | 一键本地评测封装（submission → 提取 → 覆盖率 → summary） | 本地有完整工具链时的入口 |
| `sample.ipynb` | 平台给的模板 notebook | 参考 |
| `postgresql-13.23.tar.bz2` | PG 13.23 源码（首次评测自动解压到 `postgresql-13.23/`） | 本地编译用；也可解压**读源码**辅助理解 diff |

### Prompt 模板现状（`build_prompt`）
当前 system/user prompt 已经要求：分析 diff、覆盖正常/边界(NULL/空/重复)/错误路径、自包含、严格 XML 格式。默认 `--cases 5`，`temperature 0.2`，`model ecnu-plus`。**这是你优化的起点，不是终点。**

---

## 5. 本机环境现状（已实测）

```
gcc 13.3 ✓   make ✓   gcov 13.3 ✓   bison ✓   awk ✓
lcov ✗   genhtml ✗   flex ✗   psql(客户端) ✗   bc ✗
postgresql-13.23/ 未解压（仅有 tarball）
outputs/ 尚不存在
```

含义：
- ✅ **格式检查 (`evaluate.py check`) 现在就能跑**（纯标准库）。
- ❌ **完整本地覆盖率评测跑不了**：缺 `lcov / genhtml / flex / bc`，且 PG 未编译。
  要本地评测需先：`sudo apt-get install lcov flex bc libreadline-dev`（gcc/make/bison 已有），再 `./run_local_eval.sh`（首次会自动解压+编译 PG，耗时较长）。
- ⚠️ 生成 submission 需要 `CHAT_ECNU_API_KEY` 和 `pip install -r requirements.txt`（`openai` 包）。

> 即使本机不装完整工具链也能完成作业：本地评测只是“参考分”，最终以平台为准。但**至少跑通格式检查**，并尽量在某处（本机装齐 / 平台 / 其他 Linux）验证一次覆盖率。

---

## 6. 完成路径（推荐分阶段推进）

### 阶段 0 — 环境就绪（~10 min）
```bash
python3 -m pip install -r requirements.txt        # 装 openai, beautifulsoup4
export CHAT_ECNU_API_KEY="你的Key"                # 生成必需
python3 scripts/evaluate.py check examples/example_submission.json  # 验证评测器可用
```

### 阶段 1 — 跑通最小闭环（~15 min）
先只生成 1 条，确认 API、格式、提取链路通：
```bash
python3 scripts/generate_submission.py -i data/test_v3.json -o outputs/sample_submission.json --limit 1
python3 scripts/evaluate.py check outputs/sample_submission.json
```
看 `check` 输出的 `sql_cases / empty_records / warnings`，确认无 error。

### 阶段 2 — 生成 baseline 全量（~30–60 min，取决于 API 速度）
```bash
python3 scripts/generate_submission.py -i data/test_v3.json -o outputs/submission.json
python3 scripts/evaluate.py check outputs/submission.json
```
（支持断点续跑，中断了再跑会跳过已成功的。）

### 阶段 3 — 本地覆盖率评测（可选但强烈建议，环境允许时）
装齐工具链后：
```bash
sudo apt-get update && sudo apt-get install -y lcov flex bc libreadline-dev
./run_local_eval.sh --submission outputs/submission.json --name baseline
cat outputs/local_eval/baseline/summary.txt
grep -n "ERROR:" outputs/local_eval/baseline/coverage_workspace/psql_output.log | head -50
```
首次会解压并编译 PG（慢）；之后加 `--skip-build` 复用。
重点看 `global_precision_excl_not_found` 和报错 SQL。

### 阶段 4 — 迭代优化（这里决定排名，反复做）
按 commit 级别定位低覆盖项（`eval_result.json` 里每个 id 有 `precision_excl_not_found`），针对性改进：

**优化杠杆（按性价比排序）：**
1. **修报错 SQL** — `psql_output.log` 里每条 `ERROR:` 都是浪费的 case。先清零报错。
2. **读懂 diff 改 prompt** — 对覆盖差的 commit，去 `postgresql-13.23/<file>` 读源码上下文，理解“要触发这行需要什么 SQL 条件”（哪个函数、什么参数、什么数据形态）。
3. **Few-shot 注入** — 从 `train.json` 挑结构相似的 diff+SQL 作为示例放进 prompt。
4. **覆盖多路径** — diff 里常有 `if/else`、错误分支、边界处理，针对性造 NULL/空表/重复/超长/特殊类型/触发报错的输入。
5. **控制 efficiency** — 在不掉覆盖的前提下合并冗余 SQL；但优先级低于 PrecNF。

**混合策略**：模型生成初版 → 看本地覆盖/报错 → 对低分 commit 手工补 SQL 或调 prompt → 重测。

### 阶段 5 — 定稿提交
```bash
python3 scripts/evaluate.py check outputs/submission.json   # 最终格式检查，确保 0 error
```
上传 `outputs/submission.json` 到平台：
https://pg-leaderboard-deeplearning.loca.lt/leaderboard

---

## 7. 提升 PrecNF 的具体抓手（结合评分代码）

- **目标行 = added 中“有意义的非声明非注释行”。** 写 SQL 前先在脑子里（或脚本里）过一遍 diff，挑出真正的逻辑行（`if`、函数调用、赋值），那才是要命中的。
- **`is_declaration` 会排除变量声明行**，所以别为了覆盖 `int x;` 费劲，它根本不计分。
- **控制流行 (`is_control_only`：`}`、`break`、`continue`、`else`)** 在 `precision_excl_ctrl` 里被单列；主指标 PrecNF 仍含它们，但它们通常“顺带就覆盖了”，不用单独造。
- **一个 commit 往往只改一两个函数**：找到那个函数的入口 SQL（哪个 `CREATE`/`SELECT`/`EXPLAIN`/系统函数调用会进到它），比堆数量更有效。`EXPLAIN (COSTS OFF)`、`pg_get_*` 系列、特定 `SET`、特定类型转换是常见触发点（参考 train 示例）。
- **自包含 + 幂等**：开头 `DROP ... IF EXISTS ... CASCADE`，结尾清理。合并执行时所有 SQL 在同一个 `regression` 库里顺序跑，命名冲突会引发 `ERROR`。

---

## 8. 常见坑

- `<sql>` 标签必须存在且大小写不敏感能被 `re.findall` 抓到；模型偶尔会输出 markdown 代码块包裹 → 触发 `empty_records` 警告。检查 `check` 输出。
- `id` 必须与 `test_v3.json` 对应，否则 `warning: id=X is not in dataset`，该项不计入。
- 本地分 ≠ 平台分（gcc/lcov 版本、locale、路径差异），本地只做趋势参考。
- 生成脚本默认 `temperature=0.2`：想要多样性可调高再筛选，想稳定就保持低温。

---

## 9. 下一步建议

如果你要我接着做，按优先级我可以：
1. 装依赖 + 跑通阶段 1 最小闭环（需要你提供 `CHAT_ECNU_API_KEY`）；
2. 写一个**diff 分析脚本**：解析 test_v3.json，对每个 commit 抽出“有意义目标行 + 改动函数 + 文件”，输出一张速查表，辅助人工/模型定位；
3. 改进 `build_prompt`：加入 train.json few-shot 检索、强化“按函数定位触发条件”的指令；
4. 环境允许时装 lcov/flex/bc 并跑一次完整本地评测，建立 baseline 分数。

告诉我从哪一步开始。

---

## 优化进展记录 (2026-06-09)

### 评分机制的关键发现

1. **唯一可控杠杆 = `covered`**(执行次数>0的目标行数)。分母 `matched - not_found` 由数据集 `match_info` + lcov 版本决定,SQL 改不了。最大化 covered 即最大化 PrecNF。
2. **lcov 版本严重影响分数**:
   - 本地 apt 装的是 **lcov 2.0**;平台用 **lcov 1.16**(已装在 `/tmp/lcov116`)。
   - 同一份 submission,lcov 2.0 下 PrecNF 远低于 lcov 1.16,因为 1.16 把很多"续行/裸 else/函数签名行"判为 `not_found`(从分母剔除),而 2.0 留在分母里算未覆盖。
   - **平台用 1.16,所以 lcov 1.16 的本地分才是平台预测值。** `evaluate_coverage.sh` 已支持 `LCOV_BIN`/`GENHTML_BIN` 环境变量切换(1.16 的 genhtml 只认 `--ignore-errors source`)。
3. **gcov 原始计数 ≠ 评分**:评分走 `lcov capture → genhtml HTML → evaluate.py 解析 HTML`。有些行 gcov 显示已执行,但 genhtml HTML 不给计数 → 仍判未覆盖。`scripts/probe_coverage.sh`(直接 gcov)只能确认"是否执行到",不能确认"是否计分"。

### 三类目标行

- **可覆盖的真实语句**:精心构造 SQL 能命中,加分。
- **续行/裸 else/函数签名行**(`static void`、`def->collation));`、`else`):lcov 2.0 genhtml 不赋计数,1.16 多判 not_found。无法靠 SQL 提升。
- **infeasible commit**(并发竞态/崩溃恢复/特殊配置):`144,123,125,140,111,146,114,115,133,148`。需要崩溃恢复、多 session 并发、`wal_level=logical`、`track_commit_timestamp=on` 或 checksum,单 session 顺序 SQL + 默认 initdb 配置无法触发。占据分母拉低上限。

### 成绩演进 (本地)

| 版本 | 策略 | covered | lcov2.0 PrecNF | lcov1.16 PrecNF(平台预测) |
|---|---|---|---|---|
| submission_sample (baseline) | 原始 | 123 | 0.6212 | — |
| submission_v1 | replace(替换) | 121 | 0.6111 | 0.7908 |
| submission_v2 | append(追加) | 126 | 0.6364 | **0.8235** |
| submission_v3 | v2 + 101冲突视图 | 126 | 0.6364 | (评测中) |

**结论**:append 策略 + 针对 13 个可行 commit 的精准 SQL,把平台预测 PrecNF 从基线推到 **0.82+**,超过 0.74 目标。`submission_v2`/`v3` 为推荐提交。

### 工具

- `scripts/build_submission.py --mode append` — 在 base 上叠加改进 SQL(去重),输出 versioned submission
- `scripts/analyze_result.py <eval_result.json>` — 按 headroom 排序列出每个 commit 未覆盖行
- `scripts/probe_coverage.sh <sql> <src> <lines>` — 1分钟快速探针,单文件 gcov 行计数(确认执行,非计分)
- `outputs/_improved_sql_v3.json` — 18 个 commit 的改进 SQL 数据
- 平台版评测: `LCOV_BIN=/tmp/lcov116/bin/lcov GENHTML_BIN=/tmp/lcov116/bin/genhtml bash run_local_eval.sh --submission <sub> --name <n> --skip-build`
