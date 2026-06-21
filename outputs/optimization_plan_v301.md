# PostgreSQL Coverage Optimization Plan v301

## 执行摘要

**当前基线**: submission_203.json
- 平台分数: PrecNF = **0.6313** (125/198)
- 本地分数: PrecNF = **0.6515** (129/198, gcc-11)
- 目标分数: PrecNF = **0.6515**
- **差距**: 需额外覆盖约 **4条** 代码行

**核心发现**: 通过系统性可达性分析，识别出 **11个commit** 共 **12条已验证可达但未覆盖的代码行**，这些是快速提升分数的最优目标。

---

## 优化方向（按优先级排序）

### 🎯 优先级 1: 已验证可达但未覆盖 (最高优先)

共 **11个commit**，可提升 **12行** 覆盖，预期可达到或超过目标分数。

#### 1.1 Commit 109 (最高优先，2行可达)
**状态**: covered=0/4, gap=4, 已有SQL=3个但**未包含UNION ALL**  
**问题**: 当前SQL全是普通JOIN，未触发MemoizePath的核心路径  
**目标行**: 3858, 3859 (reparameterize_path递归调用参数)

**改进方案**:
```sql
-- 关键: UNION ALL + parameterized join 触发 Append path reparameterization
DROP TABLE IF EXISTS c109_t1, c109_t2, c109_t3 CASCADE;
CREATE TABLE c109_t1(id int, val int);
CREATE TABLE c109_t2(id int, val int);
CREATE TABLE c109_t3(id int, val int);
INSERT INTO c109_t1 VALUES (1, 10), (2, 20);
INSERT INTO c109_t2 VALUES (3, 30), (4, 40);
INSERT INTO c109_t3 VALUES (1, 100), (2, 200);
ANALYZE c109_t1, c109_t2, c109_t3;
-- 关键查询: UNION ALL subquery joined with outer table
SELECT c109_t3.id, combined.val
FROM c109_t3
JOIN (
    SELECT id, val FROM c109_t1
    UNION ALL
    SELECT id, val FROM c109_t2
) AS combined(id, val)
ON c109_t3.id = combined.id;
DROP TABLE c109_t1, c109_t2, c109_t3 CASCADE;
```

**为什么现有SQL失败**: 没有UNION ALL，MemoizePath只针对Append path（UNION ALL / 分区表），普通JOIN不会进入T_Append分支。

---

#### 1.2 Commit 108 (高优先，1行可达)
**状态**: covered=1/2, gap=1, **完全缺失SQL**  
**目标行**: 3543 (substitute_phv_relids续行，foreach append_rel_list)

**改进方案**:
```sql
-- 多层UNION ALL触发subquery pullup和append_rel_list处理
DROP TABLE IF EXISTS c108_t CASCADE;
CREATE TABLE c108_t (id INT, val INT);
INSERT INTO c108_t VALUES (1, 10), (2, 20), (3, 30);
SELECT * FROM (
  SELECT id, val FROM c108_t
  UNION ALL
  SELECT id, val FROM c108_t
  UNION ALL
  SELECT id, val FROM c108_t
) AS u WHERE id > 1;
DROP TABLE c108_t CASCADE;
```

---

#### 1.3 Commit 112 (高优先，1行可达)
**状态**: covered=0/2, gap=2, **完全缺失SQL**  
**目标行**: 571 (非超级用户VACUUM共享关系的WARNING消息)

**改进方案** (注意：需要SET ROLE，但被禁止):
```sql
-- 原始方案 (平台拒绝 - 含 SET ROLE):
-- CREATE USER c112_vacuser; SET ROLE c112_vacuser; VACUUM; RESET ROLE;

-- 合规替代方案 (放弃此行):
-- 由于 SET ROLE / SET SESSION AUTHORIZATION 均被禁止，
-- 而触发line 571必须以非超级用户身份执行VACUUM，
-- 此行在合规约束下**结构性不可达**，建议放弃。
```

**决策**: **跳过此commit**，line 571需要权限切换（SET ROLE），违反平台规则。

---

#### 1.4 Commit 120 (中优先，1行可达)
**状态**: covered=9/14, gap=5, 已有SQL=3个  
**目标行**: 1507 (else分支，非DEFAULT列的rewriteValuesRTEToNulls)

**改进方案**:
```sql
-- 关键: 混合DEFAULT和显式值，触发rewriteValuesRTEToNulls的else分支
DROP VIEW IF EXISTS c120_v6 CASCADE;
DROP TABLE IF EXISTS c120_base6 CASCADE;
CREATE TABLE c120_base6 (id int PRIMARY KEY, name text DEFAULT 'default_name');
CREATE VIEW c120_v6 AS SELECT id, name FROM c120_base6;
CREATE RULE c120_r6 AS ON INSERT TO c120_v6 DO ALSO 
  INSERT INTO c120_base6 (id, name) 
  SELECT NEW.id, NEW.name WHERE NEW.id IS NOT NULL;
-- 关键: 多行VALUES，混合DEFAULT和显式值
INSERT INTO c120_v6 (id, name) VALUES 
  (1, DEFAULT), 
  (2, 'explicit_val'), 
  (3, DEFAULT);
SELECT * FROM c120_base6 ORDER BY id;
DROP VIEW c120_v6 CASCADE;
DROP TABLE c120_base6 CASCADE;
```

**为什么现有SQL可能失败**: 现有3个case可能全是显式值或全是DEFAULT，未触发混合场景。

---

#### 1.5 Commit 135 (中优先，1行可达)
**状态**: covered=4/5, gap=1, 已有SQL=3个  
**目标行**: 5270 (get_setop_query续行，UNION view deparse)

**改进方案**:
```sql
-- 当前SQL有UNION，但可能未用pg_get_viewdef(regclass, true)的true参数
DROP VIEW IF EXISTS c135_union_v CASCADE;
CREATE VIEW c135_union_v AS 
  SELECT 1 AS col1, 'a' AS col2 
  UNION ALL 
  SELECT 2, 'b';
-- 关键: colNamesVisible=true (第二个参数)
SELECT pg_get_viewdef('c135_union_v'::regclass, true);
DROP VIEW c135_union_v CASCADE;
```

**检查点**: 确认现有Case 2是否用了`pg_get_viewdef(..., true)`，如果用的是false则需修正。

---

#### 1.6 Commit 138 (中优先，1行可达)
**状态**: covered=3/4, gap=1, 已有SQL=1个  
**目标行**: 179 (SetUserIdAndSecContext续行)

**改进方案**:
```sql
-- 简单但有效: 任何REFRESH MATERIALIZED VIEW都会执行line 179
DROP MATERIALIZED VIEW IF EXISTS c138_mv CASCADE;
CREATE MATERIALIZED VIEW c138_mv AS SELECT 1 AS id, 'data' AS val;
REFRESH MATERIALIZED VIEW c138_mv;
DROP MATERIALIZED VIEW c138_mv CASCADE;
```

**检查点**: 确认现有SQL是否真的执行了REFRESH（不是只创建）。

---

#### 1.7 Commit 129 (中优先，1行可达)
**状态**: covered=3/4, gap=1, **完全缺失SQL**  
**目标行**: 844 (else分支，hash_table_bytes > bucket_size)

**改进方案**:
```sql
-- 触发hash join时内存分配的正常分支
DROP TABLE IF EXISTS c129_h1, c129_h2 CASCADE;
CREATE TABLE c129_h1 AS SELECT i AS id, md5(i::text) AS data 
  FROM generate_series(1, 10000) i;
CREATE TABLE c129_h2 AS SELECT i AS id, md5(i::text) AS data 
  FROM generate_series(1, 5000) i;
ANALYZE c129_h1, c129_h2;
SET work_mem = '1MB';
SET enable_hashjoin = on;
SET enable_mergejoin = off;
SET enable_nestloop = off;
EXPLAIN ANALYZE SELECT COUNT(*) FROM c129_h1 JOIN c129_h2 ON c129_h1.id = c129_h2.id;
RESET work_mem;
RESET enable_hashjoin;
RESET enable_mergejoin;
RESET enable_nestloop;
DROP TABLE c129_h1, c129_h2 CASCADE;
```

---

#### 1.8 Commit 136 (低优先，1行可达)
**状态**: covered=4/5, gap=1, 已有SQL=2个  
**目标行**: 12298 (CREATE OPERATOR CLASS deparse续行)

**建议**: 检查现有SQL是否包含`CREATE OPERATOR CLASS`并调用`pg_get_indexopclassdef()`。

---

#### 1.9 Commit 146 (低优先，1行可达)
**状态**: covered=1/2, gap=1, 已有SQL=1个  
**目标行**: 898 (else分支，merge join order validation)

**改进方案**:
```sql
-- 触发else分支: FULL/RIGHT JOIN with constant-false ON clause
DROP TABLE IF EXISTS c146_l, c146_r CASCADE;
CREATE TABLE c146_l (id INT, val INT);
CREATE TABLE c146_r (id INT, val INT);
INSERT INTO c146_l VALUES (1, 10), (2, 20), (3, 30);
INSERT INTO c146_r VALUES (2, 20), (3, 30), (4, 40);
CREATE INDEX c146_l_idx ON c146_l(id);
CREATE INDEX c146_r_idx ON c146_r(id);
ANALYZE c146_l, c146_r;
SET enable_hashjoin = off;
SET enable_nestloop = off;
SET enable_mergejoin = on;
-- 关键: FULL JOIN with FALSE condition触发mj_ConstFalseJoin
SELECT * FROM c146_l FULL OUTER JOIN c146_r ON c146_l.id = c146_r.id AND FALSE;
RESET enable_hashjoin;
RESET enable_nestloop;
RESET enable_mergejoin;
DROP TABLE c146_l, c146_r CASCADE;
```

---

#### 1.10 Commit 149 (低优先，1行可达)
**状态**: covered=6/7, gap=1, 已有SQL=2个  
**目标行**: 9231 (get_rule_list_toplevel函数签名)

**改进方案**:
```sql
-- ROW()比较表达式触发get_rule_list_toplevel
DROP VIEW IF EXISTS c149_row_v CASCADE;
DROP TABLE IF EXISTS c149_row_t CASCADE;
CREATE TABLE c149_row_t (a int, b int, c text);
CREATE VIEW c149_row_v AS 
  SELECT * FROM c149_row_t t 
  WHERE ROW(t.a, t.b) < ROW(t.b, t.a);
SELECT pg_get_viewdef('c149_row_v'::regclass, true);
DROP VIEW c149_row_v CASCADE;
DROP TABLE c149_row_t CASCADE;
```

---

#### 1.11 Commit 126 (低优先，1行可达，但分析可能有误)
**状态**: covered=0/1, gap=1, **完全缺失SQL**  
**目标行**: 757 (ExecShutdownNode_walker函数签名)

**疑虑**: Line 757是`static bool`函数签名，gcov通常**不对函数签名行计数**。需要进一步验证该行是否真的可达，可能是误判。

**建议**: **低优先级**，先实现上述10个高置信度的改进。

---

### 🔍 优先级 2: 大gap但可达性未完全验证

这些commit有较大覆盖缺口，但_workflow_analyses.json中部分行标记为UNCERTAIN或UNREACHABLE_STRUCTURAL。建议在完成优先级1后再评估。

| Commit | Gap | Covered | Subject |
|--------|-----|---------|---------|
| 144 | 10 | 1/11 | StartupXLOG (崩溃恢复代码，**结构性不可达**) |
| 101 | 7 | 20/27 | DML aliases (部分行是函数签名/续行) |
| 118 | 4 | 2/6 | _RETURN rule rejection |
| 123 | 4 | 2/6 | heap_update race (需并发，**结构性不可达**) |
| 125 | 4 | 5/9 | heap_delete VM race (需并发，**结构性不可达**) |
| 116 | 3 | 2/5 | Function syntax error (需ActivePortal) |
| 127 | 3 | 6/9 | FK name on partition attach (部分续行) |
| 148 | 3 | 0/3 | commit_ts (需track_commit_timestamp=on启动参数) |

**决策**: 这些commit的剩余gap主要是：
1. **结构性不可达**: 崩溃恢复(144)、并发竞态(123/125)
2. **配置受限**: track_commit_timestamp需要服务器启动参数(148)
3. **gcov技术限制**: 函数签名、参数续行无计数器

建议**暂缓**这些commit，投入产出比低。

---

### 📊 优先级 3: 小gap commit (后续优化)

7个commit，每个gap=1-2行，边际收益递减，建议完成P1后再评估。

---

## 实施计划

### Phase 1: 快速收益 (目标: +4行，达到0.6515)

按以下顺序实施，每次增加覆盖立即验证：

1. **Commit 109** (预期+2行) - 添加UNION ALL + JOIN的SQL
2. **Commit 108** (预期+1行) - 添加多层UNION ALL的SQL
3. **Commit 129** (预期+1行) - 添加hash join内存分配SQL

**检查点**: 完成上述3个commit后，本地评测应达到131-132/198 (PrecNF≈0.66+)，平台分数预期达到或超过0.6515。

### Phase 2: 稳固提升 (目标: +3-4行，冲击0.67+)

如Phase 1未完全达标，补充以下：

4. **Commit 120** (预期+1行) - 修正VALUES混合DEFAULT的SQL
5. **Commit 135** (预期+1行) - 确保pg_get_viewdef用true参数
6. **Commit 138** (预期+1行) - 确认REFRESH MV的SQL
7. **Commit 146** (预期+1行) - 添加FULL JOIN FALSE的SQL

### Phase 3: 边际优化 (可选)

8. Commit 149, 136 等低gap commit

---

## 合规性检查清单

所有新增SQL必须通过以下验证：

- [ ] 不含 `\!`, `\i`, `\gset`, `\setenv`
- [ ] 不含 `DO` 块, `LOOP`, `WHILE`
- [ ] 不含 `SET ROLE`, `SET SESSION AUTHORIZATION`
- [ ] 不含 `COPY PROGRAM`, `COPY ... FROM/TO '/...'`
- [ ] 不含 `LANGUAGE C/internal`, `lo_export`, `pg_read_file`
- [ ] 不含 `base64`, `gcc`, `.so`, `pg_config`

**验证命令**:
```bash
python3 scripts/evaluate.py check outputs/submission_301.json --dataset data/test_v3.json
```

---

## 预期结果

**保守估计**: Phase 1完成后，覆盖增加3-4行  
- 本地 PrecNF: 0.6515 → **0.6667** (132/198)
- 平台 PrecNF: 0.6313 → **≥0.6515** (目标达成)

**乐观估计**: Phase 1+2完成后，覆盖增加6-8行  
- 本地 PrecNF: 0.6515 → **0.6869** (136/198)
- 平台 PrecNF: 0.6313 → **≥0.67** (超越目标)

---

## 风险与对策

### 风险1: 本地与平台覆盖不一致
**原因**: gcc-11版本细微差异、测试环境配置差异  
**对策**: 每次提交前用gcc-11本地评测，确保绝对零违规

### 风险2: 查询优化器路径选择不稳定
**原因**: ANALYZE统计信息、planner cost估算可能使查询走不同执行路径  
**对策**: 用`SET enable_*`强制特定join/scan方法，确保路径确定性

### 风险3: gcov计数器归属歧义
**原因**: 多行语句、函数参数续行的计数归属可能因编译器不同而异  
**对策**: 优先攻击单行完整语句（如line 844的else），续行作为bonus

---

## 附录: 关键技术点

### A. 为什么Commit 109需要UNION ALL？
MemoizePath是针对**Append path**的优化（用于UNION ALL/分区表的多子路径合并）。当Append path出现在parameterized join的inner侧时，需要reparameterize每个子路径，此时才会进入`case T_Append:`分支的foreach循环，执行line 3858-3859的递归调用。

### B. gcov-11对续行的计数规则
- **函数签名**: 不计数（如line 10510 `static void`）
- **参数续行**: 通常不计数（如line 10512），但部分表达式续行可能有计数器
- **多行函数调用**: 最后的`;`所在行可能有计数器（如line 5270）

### C. 合规SQL的覆盖上限
通过逐行可达性分析，确认以下类型的行在合规约束下**结构性不可达**:
- 崩溃恢复代码 (需server crash)
- 并发竞态代码 (需多session)
- 权限切换代码 (SET ROLE被禁)
- 启动参数相关代码 (SQL无法修改PGC_POSTMASTER参数)

当前基线0.6515已接近合规SQL的理论上限，进一步提升需要精准命中剩余可达行。

---

**生成时间**: 2026-06-21  
**基于数据**: submission_203.json, _workflow_analyses.json, _cold_gaps.json  
**下一步**: 开始实施Phase 1，创建submission_301.json
