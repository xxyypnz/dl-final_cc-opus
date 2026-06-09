-- ===== Commit 149 =====
-- Source:  - 

-- --- Test Case 1 ---
DROP VIEW IF EXISTS c149_rc_v CASCADE;
DROP TABLE IF EXISTS c149_rc_t CASCADE;
CREATE TABLE c149_rc_t (a int, b int);
CREATE VIEW c149_rc_v AS SELECT * FROM c149_rc_t t WHERE ROW(t.a,t.b) < ROW(t.b,t.a);
SELECT pg_get_viewdef('c149_rc_v'::regclass, true);
DROP VIEW IF EXISTS c149_rc_v CASCADE;
DROP TABLE IF EXISTS c149_rc_t CASCADE;

-- --- Test Case 2 ---
DROP VIEW IF EXISTS c149_ins_v CASCADE;
DROP TABLE IF EXISTS c149_ins_t CASCADE;
CREATE TABLE c149_ins_t (a int, b int);
CREATE VIEW c149_ins_v AS SELECT * FROM c149_ins_t;
CREATE RULE c149_ins_r AS ON INSERT TO c149_ins_v DO INSTEAD INSERT INTO c149_ins_t VALUES (NEW.a, NEW.b);
SELECT pg_get_ruledef(oid, true) FROM pg_rewrite WHERE ev_class='c149_ins_v'::regclass AND rulename='c149_ins_r';
DROP VIEW IF EXISTS c149_ins_v CASCADE;
DROP TABLE IF EXISTS c149_ins_t CASCADE;

