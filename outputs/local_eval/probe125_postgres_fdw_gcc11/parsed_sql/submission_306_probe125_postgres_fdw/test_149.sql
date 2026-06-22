-- ===== Commit 149 =====
-- Source:  - 

-- --- Test Case 1 ---
DROP VIEW IF EXISTS insert_rule_view CASCADE;
DROP TABLE IF EXISTS insert_rule_base CASCADE;
CREATE TABLE insert_rule_base (a int, b int);
CREATE VIEW insert_rule_view AS SELECT * FROM insert_rule_base;
CREATE RULE insert_rule_ins AS ON INSERT TO insert_rule_view DO INSTEAD INSERT INTO insert_rule_base VALUES (NEW.a, NEW.b);
SELECT pg_get_ruledef(oid, true) FROM pg_rewrite WHERE ev_class = 'insert_rule_view'::regclass AND rulename = 'insert_rule_ins';
DROP VIEW IF EXISTS insert_rule_view CASCADE;
DROP TABLE IF EXISTS insert_rule_base CASCADE;

-- --- Test Case 2 ---
DROP VIEW IF EXISTS rowcompare_view CASCADE;
DROP TABLE IF EXISTS rowcompare_base CASCADE;
CREATE TABLE rowcompare_base (a int, b int);
CREATE VIEW rowcompare_view AS SELECT * FROM rowcompare_base t WHERE ROW(t.*) = ROW(t.*);
SELECT pg_get_viewdef('rowcompare_view'::regclass, true);
DROP VIEW IF EXISTS rowcompare_view CASCADE;
DROP TABLE IF EXISTS rowcompare_base CASCADE;

-- --- Test Case 3 ---
DROP VIEW IF EXISTS values_row_view CASCADE;
DROP TABLE IF EXISTS values_row_base CASCADE;
CREATE TABLE values_row_base (x int);
INSERT INTO values_row_base VALUES (1);
CREATE VIEW values_row_view AS SELECT * FROM (VALUES ((SELECT values_row_base FROM values_row_base))) AS v(r);
SELECT pg_get_viewdef('values_row_view'::regclass, true);
DROP VIEW IF EXISTS values_row_view CASCADE;
DROP TABLE IF EXISTS values_row_base CASCADE;

-- --- Test Case 4 ---
DROP VIEW IF EXISTS c149_rc_v CASCADE;
DROP TABLE IF EXISTS c149_rc_t CASCADE;
CREATE TABLE c149_rc_t (a int, b int);
CREATE VIEW c149_rc_v AS SELECT * FROM c149_rc_t t WHERE ROW(t.a,t.b) < ROW(t.b,t.a);
SELECT pg_get_viewdef('c149_rc_v'::regclass, true);
DROP VIEW IF EXISTS c149_rc_v CASCADE;
DROP TABLE IF EXISTS c149_rc_t CASCADE;

-- --- Test Case 5 ---
DROP VIEW IF EXISTS c149_ins_v CASCADE;
DROP TABLE IF EXISTS c149_ins_t CASCADE;
CREATE TABLE c149_ins_t (a int, b int);
CREATE VIEW c149_ins_v AS SELECT * FROM c149_ins_t;
CREATE RULE c149_ins_r AS ON INSERT TO c149_ins_v DO INSTEAD INSERT INTO c149_ins_t VALUES (NEW.a, NEW.b);
SELECT pg_get_ruledef(oid, true) FROM pg_rewrite WHERE ev_class='c149_ins_v'::regclass AND rulename='c149_ins_r';
DROP VIEW IF EXISTS c149_ins_v CASCADE;
DROP TABLE IF EXISTS c149_ins_t CASCADE;

-- --- Test Case 6 ---
DROP VIEW IF EXISTS c149_vw1 CASCADE;
CREATE VIEW c149_vw1 AS SELECT t.* FROM (SELECT 1 AS id, 'x'::text AS val) t;
SELECT pg_get_viewdef('c149_vw1'::regclass, true);
DROP VIEW IF EXISTS c149_vw1 CASCADE;

-- --- Test Case 7 ---
DROP TABLE IF EXISTS c149_t1 CASCADE;
DROP TABLE IF EXISTS c149_t2 CASCADE;
CREATE TABLE c149_t1 (id int, v text);
CREATE TABLE c149_t2 (id int, w int);
INSERT INTO c149_t1 VALUES (1,'a'),(2,'b');
INSERT INTO c149_t2 VALUES (1,10),(2,20);
DROP VIEW IF EXISTS c149_vw2 CASCADE;
CREATE VIEW c149_vw2 AS SELECT t1.*, t2.w FROM c149_t1 t1 JOIN c149_t2 t2 ON t1.id=t2.id;
SELECT pg_get_viewdef('c149_vw2'::regclass, true);
DROP VIEW IF EXISTS c149_vw2 CASCADE;
DROP TABLE IF EXISTS c149_t1 CASCADE;
DROP TABLE IF EXISTS c149_t2 CASCADE;

