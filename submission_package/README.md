# PostgreSQL Coverage Test Case Generation (合规版)

## 核心文件说明

### 最终提交（合规版本）
- **outputs/submission_203.json**: 最终提交文件，零违规，本地（gcc-11）PrecNF=0.6566 (130/198)，平台实测 0.6313
  - 仅使用标准 SQL，不含 \!、\i、base64、COPY PROGRAM、LANGUAGE C/internal、文件读取、DO 块、SET ROLE 等

### 生成逻辑
- **scripts/_build_v203.py**: 从 SQL 模板生成合规 submission（含完整违规模式过滤 + 101/112 等效替换）
- **outputs/_improved_sql_v21.json**: 每个 commit 的 SQL 测试用例库（核心贡献）

### 评测脚本
- **scripts/evaluate.py**: 主评测逻辑（extract/check/计算覆盖率）
- **scripts/evaluate_coverage.sh**: 覆盖率收集（PG + gcov + lcov）
- **scripts/probe_coverage.sh**: 单 commit 隔离探针（复用编译产物，快速验证指定行覆盖）
- **run_local_eval.sh**: 本地测试入口

### 方法论数据
- **outputs/_cold_gaps.json**: 未覆盖行结构化分析
- **outputs/_workflow_analyses.json**: 对抗性可达性验证结果

### 项目总结
- **sum.txt**: 全盘总结（方法/合规处理/指标）

## 运行方式

> 重要：平台用 gcc-11.5.0 / gcov-11。本地须以 `CC=gcc-11` 重新编译 PG 才能对齐口径
> （默认 gcc-13 构建的 .gcno 为 B33 格式，gcov-11 无法读取）。

```bash
# 0. （首次）以 gcc-11 编译 coverage build
cd postgresql-13.23 && make clean && \
    ./configure --enable-coverage CC=gcc-11 --prefix=$PWD/install_coverage && \
    make -j$(nproc) && make install && cd ..

# 1. 检查 submission 格式与合规性
python3 scripts/evaluate.py check outputs/submission_203.json --dataset data/test_v3.json

# 2. 本地完整评测（需 gcov-11）
GCOV_TOOL=gcov-11 bash run_local_eval.sh \
    --submission outputs/submission_203.json --name v203

# 3. 查看结果
cat outputs/local_eval/v203/summary.txt
```

## 合规性保证

submission_203.json 已通过完整违规扫描，确认不含以下任何构造：
\!  \i  base64  COPY PROGRAM  server-file COPY  LANGUAGE C/internal
lo_export/lo_import  pg_read_file  gcc/pg_config/.so  pg_ls_dir/adminpack
\gset  \setenv  shell echo  DO 代码块  LOOP/WHILE  SET ROLE / SET SESSION AUTHORIZATION

## 最终指标

- 本地 PrecNF (gcc-11/gcov-11): 0.6566 (130/198 covered)
- 平台实测 PrecNF: 0.6313
- SQL cases: 216
