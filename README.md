# PostgreSQL Coverage Test Case Generation (合规版)

## 核心文件说明

### 最终提交（合规版本）
- **outputs/submission_201.json**: 最终提交文件，零违规，本地 PrecNF=0.6616 (131/198)
  - 仅使用标准 SQL，不含 \!、\i、base64、COPY PROGRAM、LANGUAGE C/internal、文件读取等

### 生成逻辑
- **scripts/_build_v201.py**: 从 SQL 模板生成合规 submission（含违规模式过滤）
- **outputs/_improved_sql_v21.json**: 每个 commit 的 SQL 测试用例库（核心贡献）

### 评测脚本
- **scripts/evaluate.py**: 主评测逻辑（extract/check/计算覆盖率）
- **scripts/evaluate_coverage.sh**: 覆盖率收集（PG + gcov + lcov）
- **run_local_eval.sh**: 本地测试入口

### 方法论数据
- **outputs/_cold_gaps.json**: 未覆盖行结构化分析
- **outputs/_workflow_analyses.json**: 对抗性可达性验证结果

### 项目总结
- **sum.txt**: 全盘总结（方法/合规处理/指标）

## 运行方式

```bash
# 1. 检查 submission 格式与合规性
python3 scripts/evaluate.py check outputs/submission_201.json --dataset data/test_v3.json

# 2. 本地完整评测（需 PostgreSQL 13.23 coverage build + gcov-11）
GCOV_TOOL=gcov-11 bash run_local_eval.sh \
    --submission outputs/submission_201.json --name v201

# 3. 查看结果
cat outputs/local_eval/v201/summary.txt
```

## 合规性保证

submission_201.json 已通过完整违规扫描，确认不含以下任何构造：
\!  \i  base64  COPY PROGRAM  server-file COPY  LANGUAGE C/internal
lo_export/lo_import  pg_read_file  gcc/pg_config/.so  pg_ls_dir/adminpack
\gset  \setenv  shell echo

## 最终指标

- 本地 PrecNF: 0.6616 (131/198 covered)
- SQL blocks: 222
- SQL statements: 1745
