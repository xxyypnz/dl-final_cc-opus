# 基于v203的优化策略 v304

## 执行摘要

**v301失败教训**: 平台0.4+（vs v203的0.6313），大规模替换SQL极其危险。

**新策略**: 保守微调，每次只改动1-2个commit的1个SQL case。

---

## v203 Baseline 分析

- **本地**: 0.6515 (129/198)
- **平台**: 0.6313 (125/198)
- **差距**: 4行（本地优于平台）

**关键洞察**:
1. v203已经是高质量基线（29个commit覆盖率≥70%）
2. 本地vs平台差异可能是编译器/环境因素，不可控
3. 任何改动都有破坏现有覆盖的风险

---

## 候选优化目标（按风险从低到高）

### 🟢 Tier 1: 低风险（推荐）

#### **Commit 135** - 修复UNION ALL → UNION
- **当前**: 4/5 covered, gap=1
- **目标行**: 5270 (get_setop_query的colNamesVisible参数续行)
- **问题**: v203 Case 4用的是`UNION ALL`，应该改为`UNION`（去重版本）
- **修复**: 将Case 4的`UNION ALL`改为`UNION`
- **风险**: **极低** - 仅改1个关键字，不添加/删除SQL
- **预期**: +1行 (本地130/198)

```sql
-- v203 Case 4 (当前)
CREATE VIEW qcol_setop_v AS SELECT 1+1 UNION ALL SELECT 2+2;

-- v304改进
CREATE VIEW qcol_setop_v AS SELECT 1+1 UNION SELECT 2+2;  -- 去掉ALL
```

**为什么有效**: 
- UNION (without ALL) 会触发去重逻辑，可能进入get_setop_query的不同分支
- 或者尝试 INTERSECT / EXCEPT (也调用get_setop_query)

---

### 🟡 Tier 2: 中风险（需验证）

#### **Commit 149** - 添加ROW()比较
- **当前**: 6/7 covered, gap=1
- **目标行**: 9231 (get_rule_list_toplevel函数签名)
- **问题**: 需要包含ROW()比较表达式的VIEW deparse
- **修复**: 添加1个新SQL case
- **风险**: **中等** - 添加新SQL，但不影响现有的6个case
- **预期**: +1行

```sql
DROP VIEW IF EXISTS c149_row_v CASCADE;
DROP TABLE IF EXISTS c149_row_t CASCADE;
CREATE TABLE c149_row_t (a int, b int);
CREATE VIEW c149_row_v AS 
  SELECT * FROM c149_row_t t WHERE ROW(t.a, t.b) < ROW(t.b, t.a);
SELECT pg_get_viewdef('c149_row_v'::regclass, true);
DROP VIEW c149_row_v CASCADE;
DROP TABLE c149_row_t CASCADE;
```

---

### 🔴 Tier 3: 高风险（不推荐）

#### **Commit 138** - Line 179
- **问题**: 这是函数参数续行，gcov-11可能结构性不计数
- **风险**: 即使添加SQL也可能无效
- **建议**: **跳过**

#### **Commit 109/108/129** - v301失败的commit
- **问题**: 无法可靠触发MemoizePath/UNION ALL pullup/特定hash join分支
- **风险**: 极高，v301已证明失败
- **建议**: **永久放弃**

---

## 推荐实施计划

### Phase 1: 单点修复（最保守）

**目标**: 仅修改Commit 135的1个关键字

```bash
# 生成 submission_304.json
# - 保留v203所有SQL
# - 仅修改Commit 135 Case 4: UNION ALL → UNION
```

**预期**:
- 本地: 129 → 130/198 (+1行, PrecNF=0.6566)
- 平台: 125 → 126/198 (预期, PrecNF=0.6364)

**风险评估**: ★☆☆☆☆ (极低)
- 仅改1个关键字
- 不删除任何SQL
- 不添加任何SQL
- 即使失败，最多持平v203

---

### Phase 2: 双点改进（如果Phase 1成功）

在Phase 1验证成功后，添加Commit 149的ROW()比较SQL。

**预期**:
- 本地: 130 → 131/198
- 平台: 126 → 127/198

**风险评估**: ★★☆☆☆ (低)

---

### Phase 3: 替代方向（如果Phase 1/2都失败）

如果135和149都失败，考虑：

1. **分析v203→平台的4行差异**
   - 找出本地覆盖但平台未覆盖的4个commit
   - 检查这些commit的SQL是否有随机性/环境依赖

2. **优化低效SQL**
   - Commit 101: 20个SQL → 20/27 covered (效率0.19)
   - Commit 138: 6个SQL → 3/4 covered (效率0.50)
   - 但风险高，因为"看起来无效"的SQL可能有隐藏作用

3. **接受现状**
   - v203的0.6313已经是高质量基线
   - 在合规约束下，可能接近理论上限

---

## 关键原则

1. ✅ **保留所有现有SQL** - 不删除任何v203的SQL case
2. ✅ **最小改动** - 每次只改1-2个commit
3. ✅ **优先修改而非添加** - 修改现有SQL比添加新SQL更安全
4. ✅ **避免复杂SQL** - 不用ANALYZE、复杂JOIN、多表关联
5. ✅ **立即验证** - 每次改动后立即本地测评

---

## 实施检查清单

### 提交前
- [ ] 仅修改了1-2个commit
- [ ] 未删除任何v203的SQL
- [ ] 新增SQL（如有）≤2个
- [ ] 通过 `evaluate.py check` 验证
- [ ] 通过本地评测（skip-build）

### 提交后
- [ ] 平台分数 ≥ v203的0.6313
- [ ] 如果失败，立即回滚到v203

---

## 决策树

```
开始
 ↓
实施Phase 1 (改Commit 135: UNION ALL → UNION)
 ↓
本地测评
 ↓
+1行? ────No───→ 尝试INTERSECT或EXCEPT
 ↓Yes            ↓
提交平台         +1行? ───No──→ 放弃135，尝试149
 ↓               ↓Yes
≥0.6313? ───No──→ 回滚v203，分析失败原因
 ↓Yes            ↓
成功！考虑Phase 2 提交平台
                 ↓
                ≥0.6313? ───Yes──→ 成功！
                 ↓No
                回滚v203
```

---

**生成时间**: 2026-06-22
**基于**: v203 baseline, v301失败分析
**下一步**: 实施Phase 1 - 修改Commit 135
