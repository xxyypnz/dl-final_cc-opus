-- ===== Commit 101 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS test_t1 CASCADE;
CREATE TABLE test_t1 (id INT);
INSERT INTO test_t1 VALUES (1);

-- Execution
WITH test_t1 AS (SELECT 2 AS id)
INSERT INTO test_t1 (id) SELECT id FROM test_t1;

-- Teardown
DROP TABLE IF EXISTS test_t1 CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS test_t2 CASCADE;
CREATE TABLE test_t2 (id INT);
INSERT INTO test_t2 VALUES (1);

-- Execution
WITH test_t2 AS (SELECT 2 AS id)
UPDATE test_t2 SET id = (SELECT id FROM test_t2) WHERE id = 1;

-- Teardown
DROP TABLE IF EXISTS test_t2 CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS test_t3 CASCADE;
CREATE TABLE test_t3 (id INT);
INSERT INTO test_t3 VALUES (1);

-- Execution
WITH test_t3 AS (SELECT 2 AS id)
DELETE FROM test_t3 WHERE id = (SELECT id FROM test_t3);

-- Teardown
DROP TABLE IF EXISTS test_t3 CASCADE;

-- --- Test Case 4 ---
DROP VIEW IF EXISTS ruleutils_ins_v CASCADE;
DROP TABLE IF EXISTS ruleutils_ins_t CASCADE;
CREATE TABLE ruleutils_ins_t (id int, val text);
CREATE VIEW ruleutils_ins_v AS SELECT * FROM ruleutils_ins_t;
CREATE RULE ruleutils_ins_r AS ON INSERT TO ruleutils_ins_v DO INSTEAD
  WITH ruleutils_ins_t AS (SELECT 1 AS id, 'x'::text AS val)
  INSERT INTO ruleutils_ins_t AS target_alias SELECT id, val FROM ruleutils_ins_t;
SELECT pg_get_ruledef(oid, true) FROM pg_rewrite WHERE ev_class='ruleutils_ins_v'::regclass AND rulename='ruleutils_ins_r';
DROP VIEW IF EXISTS ruleutils_ins_v CASCADE;
DROP TABLE IF EXISTS ruleutils_ins_t CASCADE;

-- --- Test Case 5 ---
DROP VIEW IF EXISTS ruleutils_upd_v CASCADE;
DROP TABLE IF EXISTS ruleutils_upd_t CASCADE;
CREATE TABLE ruleutils_upd_t (id int, val text);
CREATE VIEW ruleutils_upd_v AS SELECT * FROM ruleutils_upd_t;
CREATE RULE ruleutils_upd_r AS ON UPDATE TO ruleutils_upd_v DO INSTEAD
  WITH ruleutils_upd_t AS (SELECT NEW.id AS id)
  UPDATE ruleutils_upd_t AS target_alias SET val = 'updated' WHERE target_alias.id IN (SELECT id FROM ruleutils_upd_t);
SELECT pg_get_ruledef(oid, true) FROM pg_rewrite WHERE ev_class='ruleutils_upd_v'::regclass AND rulename='ruleutils_upd_r';
DROP VIEW IF EXISTS ruleutils_upd_v CASCADE;
DROP TABLE IF EXISTS ruleutils_upd_t CASCADE;

-- --- Test Case 6 ---
DROP VIEW IF EXISTS ruleutils_del_v CASCADE;
DROP TABLE IF EXISTS ruleutils_del_t CASCADE;
DROP TABLE IF EXISTS ruleutils_aux CASCADE;
CREATE TABLE ruleutils_del_t (id int);
CREATE TABLE ruleutils_aux (id int);
CREATE VIEW ruleutils_del_v AS SELECT * FROM ruleutils_del_t;
CREATE RULE ruleutils_del_r AS ON DELETE TO ruleutils_del_v DO INSTEAD
  DELETE FROM ruleutils_del_t AS target_alias USING ruleutils_aux AS ruleutils_del_t WHERE target_alias.id = ruleutils_del_t.id;
SELECT pg_get_ruledef(oid, true) FROM pg_rewrite WHERE ev_class='ruleutils_del_v'::regclass AND rulename='ruleutils_del_r';
DROP VIEW IF EXISTS ruleutils_del_v CASCADE;
DROP TABLE IF EXISTS ruleutils_del_t CASCADE;
DROP TABLE IF EXISTS ruleutils_aux CASCADE;

-- --- Test Case 7 ---
DROP VIEW IF EXISTS ruleutils_alias_v CASCADE;
DROP FUNCTION IF EXISTS ruleutils_srf() CASCADE;
CREATE FUNCTION ruleutils_srf() RETURNS TABLE(a int, b text) LANGUAGE sql AS $$ SELECT 1, 'x'::text $$;
CREATE VIEW ruleutils_alias_v AS
WITH cte_alias AS (SELECT 1 AS c)
SELECT f.a, sq.x, vals.y, cte_alias.c
FROM ruleutils_srf() f,
     (SELECT 2 AS x) sq,
     (VALUES (3)) vals(y),
     cte_alias;
SELECT pg_get_viewdef('ruleutils_alias_v'::regclass, true);
DROP VIEW IF EXISTS ruleutils_alias_v CASCADE;
DROP FUNCTION IF EXISTS ruleutils_srf() CASCADE;

-- --- Test Case 8 ---
DROP TABLE IF EXISTS foo101 CASCADE;
CREATE TABLE foo101 (f1 text DEFAULT 'test', f2 int DEFAULT 42, f3 int DEFAULT 7);
INSERT INTO foo101 AS bar DEFAULT VALUES RETURNING *;
INSERT INTO foo101 AS bar DEFAULT VALUES RETURNING bar.*;
INSERT INTO foo101 AS bar DEFAULT VALUES RETURNING bar.f3;
DROP TABLE IF EXISTS foo101 CASCADE;

-- --- Test Case 9 ---
DROP VIEW IF EXISTS rte_func101_v CASCADE;
CREATE VIEW rte_func101_v AS SELECT * FROM generate_series(1, 3);
SELECT pg_get_viewdef('rte_func101_v'::regclass, true);
DROP VIEW IF EXISTS rte_func101_v CASCADE;

-- --- Test Case 10 ---
DROP VIEW IF EXISTS rte_cte101_v CASCADE;
CREATE VIEW rte_cte101_v AS
WITH cte101 AS (SELECT 1 AS a)
SELECT * FROM cte101
WHERE EXISTS (WITH cte101 AS (SELECT 2 AS a) SELECT 1 FROM cte101 WHERE cte101.a > 0);
SELECT pg_get_viewdef('rte_cte101_v'::regclass, true);
DROP VIEW IF EXISTS rte_cte101_v CASCADE;

-- --- Test Case 11 ---
DROP SCHEMA IF EXISTS s101a CASCADE;
DROP SCHEMA IF EXISTS s101b CASCADE;
CREATE SCHEMA s101a;
CREATE SCHEMA s101b;
CREATE TABLE s101a.same_name (a int);
CREATE TABLE s101b.same_name (a int);
CREATE VIEW rte_rel_conflict101_v AS
SELECT s101a.same_name.a AS a1, s101b.same_name.a AS a2
FROM s101a.same_name, s101b.same_name;
SELECT pg_get_viewdef('rte_rel_conflict101_v'::regclass, true);
DROP VIEW IF EXISTS rte_rel_conflict101_v CASCADE;
DROP SCHEMA IF EXISTS s101a CASCADE;
DROP SCHEMA IF EXISTS s101b CASCADE;

-- --- Test Case 12 ---
DROP VIEW IF EXISTS rte_func_no_cols101_v CASCADE;
CREATE VIEW rte_func_no_cols101_v AS SELECT 1 AS marker FROM generate_series(1, 3);
SELECT pg_get_viewdef('rte_func_no_cols101_v'::regclass, true);
DROP VIEW IF EXISTS rte_func_no_cols101_v CASCADE;

-- --- Test Case 13 ---
DROP VIEW IF EXISTS c101_ins_v CASCADE;
DROP TABLE IF EXISTS c101_ins_t CASCADE;
CREATE TABLE c101_ins_t (id int, val text);
CREATE VIEW c101_ins_v AS SELECT * FROM c101_ins_t;
CREATE RULE c101_ins_r AS ON INSERT TO c101_ins_v DO INSTEAD
  INSERT INTO c101_ins_t AS target_alias SELECT NEW.id, NEW.val;
SELECT pg_get_ruledef(oid, true) FROM pg_rewrite WHERE ev_class='c101_ins_v'::regclass AND rulename='c101_ins_r';
DROP VIEW IF EXISTS c101_ins_v CASCADE;
DROP TABLE IF EXISTS c101_ins_t CASCADE;

-- --- Test Case 14 ---
DROP VIEW IF EXISTS c101_ud_v CASCADE;
DROP TABLE IF EXISTS c101_ud_t CASCADE;
CREATE TABLE c101_ud_t (id int, val text);
CREATE VIEW c101_ud_v AS SELECT * FROM c101_ud_t;
CREATE RULE c101_upd_r AS ON UPDATE TO c101_ud_v DO INSTEAD
  UPDATE c101_ud_t AS tgt SET val = NEW.val WHERE tgt.id = OLD.id;
CREATE RULE c101_del_r AS ON DELETE TO c101_ud_v DO INSTEAD
  DELETE FROM c101_ud_t AS tgt WHERE tgt.id = OLD.id;
SELECT pg_get_ruledef(oid, true) FROM pg_rewrite WHERE ev_class='c101_ud_v'::regclass AND rulename IN ('c101_upd_r','c101_del_r') ORDER BY rulename;
DROP VIEW IF EXISTS c101_ud_v CASCADE;
DROP TABLE IF EXISTS c101_ud_t CASCADE;

-- --- Test Case 15 ---
DROP VIEW IF EXISTS c101_alias_v CASCADE;
DROP FUNCTION IF EXISTS c101_srf() CASCADE;
CREATE FUNCTION c101_srf() RETURNS TABLE(a int, b text) LANGUAGE sql AS $$ SELECT 1, 'x'::text $$;
CREATE VIEW c101_alias_v AS
WITH c101_cte AS (SELECT 1 AS c)
SELECT f.a, sq.x, vals.y, c101_cte.c
FROM c101_srf() f,
     (SELECT 2 AS x) sq,
     (VALUES (3)) vals(y),
     c101_cte;
SELECT pg_get_viewdef('c101_alias_v'::regclass, true);
DROP VIEW IF EXISTS c101_alias_v CASCADE;
DROP FUNCTION IF EXISTS c101_srf() CASCADE;

-- --- Test Case 16 ---
DROP SCHEMA IF EXISTS c101sa CASCADE;
DROP SCHEMA IF EXISTS c101sb CASCADE;
CREATE SCHEMA c101sa;
CREATE SCHEMA c101sb;
CREATE TABLE c101sa.t (a int);
CREATE TABLE c101sb.t (a int);
DROP VIEW IF EXISTS c101_conflict_v CASCADE;
CREATE VIEW c101_conflict_v AS SELECT x.a AS a1, y.a AS a2 FROM c101sa.t x, c101sb.t y;
SELECT pg_get_viewdef('c101_conflict_v'::regclass, true);
DROP VIEW IF EXISTS c101_conflict_v CASCADE;
DROP SCHEMA IF EXISTS c101sa CASCADE;
DROP SCHEMA IF EXISTS c101sb CASCADE;

-- --- Test Case 17 ---
DROP TABLE IF EXISTS c101_ins2_t CASCADE;
CREATE TABLE c101_ins2_t (id int, val text);
INSERT INTO c101_ins2_t AS tgt VALUES (1,'a') RETURNING tgt.*;
INSERT INTO c101_ins2_t AS tgt VALUES (2,'b') RETURNING tgt.id;
SELECT pg_get_viewdef(oid) FROM pg_class WHERE relname='c101_ins2_t' LIMIT 1;
DROP TABLE IF EXISTS c101_ins2_t CASCADE;

-- --- Test Case 18 ---
DROP VIEW IF EXISTS c101_rule_fn_v CASCADE;
DROP TABLE IF EXISTS c101_rule_fn_t CASCADE;
DROP FUNCTION IF EXISTS c101_rule_fn() CASCADE;
CREATE TABLE c101_rule_fn_t (id int, val text);
CREATE FUNCTION c101_rule_fn() RETURNS TABLE(id int, val text) LANGUAGE sql AS $$ SELECT 1::int, 'x'::text $$;
CREATE VIEW c101_rule_fn_v AS SELECT * FROM c101_rule_fn_t;
CREATE RULE c101_rule_fn_r AS ON INSERT TO c101_rule_fn_v DO INSTEAD
  INSERT INTO c101_rule_fn_t SELECT * FROM c101_rule_fn();
SELECT pg_get_ruledef(oid, true) FROM pg_rewrite WHERE ev_class='c101_rule_fn_v'::regclass AND rulename='c101_rule_fn_r';
DROP VIEW IF EXISTS c101_rule_fn_v CASCADE;
DROP TABLE IF EXISTS c101_rule_fn_t CASCADE;
DROP FUNCTION IF EXISTS c101_rule_fn() CASCADE;

-- --- Test Case 19 ---
DROP TABLE IF EXISTS c101_upd2 CASCADE;
CREATE TABLE c101_upd2 (id int, v text);
INSERT INTO c101_upd2 VALUES (1,'a'),(2,'b');
UPDATE c101_upd2 AS u SET v='x' WHERE u.id=1 RETURNING u.*;
SELECT * FROM c101_upd2 ORDER BY id;
DROP TABLE IF EXISTS c101_upd2 CASCADE;

-- --- Test Case 20 ---
DROP VIEW IF EXISTS c101_vals_v CASCADE;
DROP TABLE IF EXISTS c101_vals_t CASCADE;
CREATE TABLE c101_vals_t (a int, b text);
CREATE VIEW c101_vals_v AS SELECT a, b FROM c101_vals_t;
CREATE RULE c101_vals_r AS ON INSERT TO c101_vals_v DO INSTEAD
  INSERT INTO c101_vals_t AS t VALUES (NEW.a, NEW.b) RETURNING t.*;
INSERT INTO c101_vals_v VALUES (1,'x'),(2,'y');
SELECT pg_get_ruledef(oid, true) FROM pg_rewrite WHERE ev_class='c101_vals_v'::regclass AND rulename='c101_vals_r';
DROP VIEW IF EXISTS c101_vals_v CASCADE;
DROP TABLE IF EXISTS c101_vals_t CASCADE;

-- --- Test Case 21 ---
DROP TABLE IF EXISTS c101_del2_t CASCADE;
CREATE TABLE c101_del2_t (id int PRIMARY KEY, v text);
INSERT INTO c101_del2_t VALUES (1,'a'),(2,'b'),(3,'c');
DELETE FROM c101_del2_t AS d WHERE d.id > 1 RETURNING d.id;
SELECT * FROM c101_del2_t;
DROP TABLE IF EXISTS c101_del2_t CASCADE;

-- --- Test Case 22 ---
DROP SCHEMA IF EXISTS s101c CASCADE;
DROP SCHEMA IF EXISTS s101d CASCADE;
CREATE SCHEMA s101c;
CREATE SCHEMA s101d;
CREATE TABLE s101c.tbl (a int, b text);
CREATE TABLE s101d.tbl (x int, y float);
INSERT INTO s101c.tbl VALUES (1,'a'),(2,'b');
INSERT INTO s101d.tbl VALUES (1,1.5),(2,2.5);
DROP VIEW IF EXISTS c101_conflict2_v CASCADE;
CREATE VIEW c101_conflict2_v AS
  SELECT t1.a, t2.x FROM s101c.tbl t1, s101d.tbl t2 WHERE t1.a = t2.x;
SELECT pg_get_viewdef('c101_conflict2_v'::regclass, true);
DROP VIEW IF EXISTS c101_conflict2_v CASCADE;
DROP SCHEMA IF EXISTS s101c CASCADE;
DROP SCHEMA IF EXISTS s101d CASCADE;

-- --- Test Case 23 ---
DROP VIEW IF EXISTS c101_cte_conflict_v CASCADE;
CREATE VIEW c101_cte_conflict_v AS
  WITH cte AS (SELECT 1 AS id), cte2 AS (SELECT 2 AS id)
  SELECT cte.id AS a, cte2.id AS b FROM cte, cte2;
SELECT pg_get_viewdef('c101_cte_conflict_v'::regclass, true);
DROP VIEW IF EXISTS c101_cte_conflict_v CASCADE;

-- --- Test Case 24 ---
DROP VIEW IF EXISTS c101_303_v CASCADE;
DROP TABLE IF EXISTS c101_303_t CASCADE;
DROP TABLE IF EXISTS c101_303_aux CASCADE;
CREATE TABLE c101_303_t (id int, val text);
CREATE TABLE c101_303_aux (id int, val text);
CREATE VIEW c101_303_v AS SELECT * FROM c101_303_t;
CREATE RULE c101_303_upd AS ON UPDATE TO c101_303_v DO INSTEAD
  UPDATE c101_303_t AS c101_303_aux
     SET val = NEW.val
    FROM c101_303_aux AS src
   WHERE c101_303_aux.id = OLD.id AND src.id = OLD.id
   RETURNING c101_303_aux.*;
SELECT pg_get_ruledef(oid, true)
FROM pg_rewrite
WHERE ev_class = 'c101_303_v'::regclass AND rulename = 'c101_303_upd';
DROP VIEW IF EXISTS c101_303_v CASCADE;
DROP TABLE IF EXISTS c101_303_t CASCADE;
DROP TABLE IF EXISTS c101_303_aux CASCADE;

-- --- Test Case 25 ---
DROP VIEW IF EXISTS c101_303_ins_v CASCADE;
DROP TABLE IF EXISTS c101_303_ins_t CASCADE;
CREATE TABLE c101_303_ins_t (id int, val text);
CREATE VIEW c101_303_ins_v AS SELECT * FROM c101_303_ins_t;
CREATE RULE c101_303_ins_r AS ON INSERT TO c101_303_ins_v DO INSTEAD
  INSERT INTO c101_303_ins_t AS dst
  SELECT q.id, q.val
  FROM (VALUES (NEW.id, NEW.val)) AS q(id, val)
  RETURNING dst.*;
SELECT pg_get_ruledef(oid, true)
FROM pg_rewrite
WHERE ev_class = 'c101_303_ins_v'::regclass AND rulename = 'c101_303_ins_r';
DROP VIEW IF EXISTS c101_303_ins_v CASCADE;
DROP TABLE IF EXISTS c101_303_ins_t CASCADE;

