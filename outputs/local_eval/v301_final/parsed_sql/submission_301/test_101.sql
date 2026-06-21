-- ===== Commit 101 =====
-- Source:  - 

-- --- Test Case 1 ---
DROP TABLE IF EXISTS c101_ins2_t CASCADE;
CREATE TABLE c101_ins2_t (id int, val text);
INSERT INTO c101_ins2_t AS tgt VALUES (1,'a') RETURNING tgt.*;
INSERT INTO c101_ins2_t AS tgt VALUES (2,'b') RETURNING tgt.id;
SELECT pg_get_viewdef(oid) FROM pg_class WHERE relname='c101_ins2_t' LIMIT 1;
DROP TABLE IF EXISTS c101_ins2_t CASCADE;

-- --- Test Case 2 ---
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

-- --- Test Case 3 ---
DROP TABLE IF EXISTS c101_upd2 CASCADE;
CREATE TABLE c101_upd2 (id int, v text);
INSERT INTO c101_upd2 VALUES (1,'a'),(2,'b');
UPDATE c101_upd2 AS u SET v='x' WHERE u.id=1 RETURNING u.*;
SELECT * FROM c101_upd2 ORDER BY id;
DROP TABLE IF EXISTS c101_upd2 CASCADE;

-- --- Test Case 4 ---
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

-- --- Test Case 5 ---
DROP TABLE IF EXISTS c101_del2_t CASCADE;
CREATE TABLE c101_del2_t (id int PRIMARY KEY, v text);
INSERT INTO c101_del2_t VALUES (1,'a'),(2,'b'),(3,'c');
DELETE FROM c101_del2_t AS d WHERE d.id > 1 RETURNING d.id;
SELECT * FROM c101_del2_t;
DROP TABLE IF EXISTS c101_del2_t CASCADE;

-- --- Test Case 6 ---
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

-- --- Test Case 7 ---
DROP VIEW IF EXISTS c101_cte_conflict_v CASCADE;
CREATE VIEW c101_cte_conflict_v AS
  WITH cte AS (SELECT 1 AS id), cte2 AS (SELECT 2 AS id)
  SELECT cte.id AS a, cte2.id AS b FROM cte, cte2;
SELECT pg_get_viewdef('c101_cte_conflict_v'::regclass, true);
DROP VIEW IF EXISTS c101_cte_conflict_v CASCADE;

