-- ===== Commit 101 =====
-- Source:  - 

-- --- Test Case 1 ---
DROP VIEW IF EXISTS c101_ins_v CASCADE;
DROP TABLE IF EXISTS c101_ins_t CASCADE;
CREATE TABLE c101_ins_t (id int, val text);
CREATE VIEW c101_ins_v AS SELECT * FROM c101_ins_t;
CREATE RULE c101_ins_r AS ON INSERT TO c101_ins_v DO INSTEAD
  INSERT INTO c101_ins_t AS target_alias SELECT NEW.id, NEW.val;
SELECT pg_get_ruledef(oid, true) FROM pg_rewrite WHERE ev_class='c101_ins_v'::regclass AND rulename='c101_ins_r';
DROP VIEW IF EXISTS c101_ins_v CASCADE;
DROP TABLE IF EXISTS c101_ins_t CASCADE;

-- --- Test Case 2 ---
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

-- --- Test Case 3 ---
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

