\pset pager off
SET statement_timeout = 5000;
SET lock_timeout = 1000;
SET idle_in_transaction_session_timeout = 5000;

-- ===== Test Case 1 (commit 101) =====
DROP TABLE IF EXISTS c101_ins2_t CASCADE;
CREATE TABLE c101_ins2_t (id int, val text);
INSERT INTO c101_ins2_t AS tgt VALUES (1,'a') RETURNING tgt.*;
INSERT INTO c101_ins2_t AS tgt VALUES (2,'b') RETURNING tgt.id;
SELECT pg_get_viewdef(oid) FROM pg_class WHERE relname='c101_ins2_t' LIMIT 1;
DROP TABLE IF EXISTS c101_ins2_t CASCADE;

-- ===== Test Case 2 (commit 101) =====
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

-- ===== Test Case 3 (commit 101) =====
DROP TABLE IF EXISTS c101_upd2 CASCADE;
CREATE TABLE c101_upd2 (id int, v text);
INSERT INTO c101_upd2 VALUES (1,'a'),(2,'b');
UPDATE c101_upd2 AS u SET v='x' WHERE u.id=1 RETURNING u.*;
SELECT * FROM c101_upd2 ORDER BY id;
DROP TABLE IF EXISTS c101_upd2 CASCADE;

-- ===== Test Case 4 (commit 101) =====
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

-- ===== Test Case 5 (commit 101) =====
DROP TABLE IF EXISTS c101_del2_t CASCADE;
CREATE TABLE c101_del2_t (id int PRIMARY KEY, v text);
INSERT INTO c101_del2_t VALUES (1,'a'),(2,'b'),(3,'c');
DELETE FROM c101_del2_t AS d WHERE d.id > 1 RETURNING d.id;
SELECT * FROM c101_del2_t;
DROP TABLE IF EXISTS c101_del2_t CASCADE;

-- ===== Test Case 6 (commit 101) =====
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

-- ===== Test Case 7 (commit 101) =====
DROP VIEW IF EXISTS c101_cte_conflict_v CASCADE;
CREATE VIEW c101_cte_conflict_v AS
  WITH cte AS (SELECT 1 AS id), cte2 AS (SELECT 2 AS id)
  SELECT cte.id AS a, cte2.id AS b FROM cte, cte2;
SELECT pg_get_viewdef('c101_cte_conflict_v'::regclass, true);
DROP VIEW IF EXISTS c101_cte_conflict_v CASCADE;

-- ===== Test Case 8 (commit 102) =====
SELECT 1;

-- ===== Test Case 9 (commit 103) =====
SELECT 1;

-- ===== Test Case 10 (commit 104) =====
SELECT 1;

-- ===== Test Case 11 (commit 105) =====
SELECT 1;

-- ===== Test Case 12 (commit 106) =====
SELECT 1;

-- ===== Test Case 13 (commit 107) =====
SELECT 1;

-- ===== Test Case 14 (commit 108) =====
DROP TABLE IF EXISTS c108_base CASCADE;
CREATE TABLE c108_base (id INT, val INT);
INSERT INTO c108_base VALUES (1, 10), (2, 20), (3, 30);
SELECT * FROM (
  SELECT id, val FROM c108_base
  UNION ALL
  SELECT id, val FROM c108_base
  UNION ALL
  SELECT id, val FROM c108_base
) AS u WHERE id > 1;
DROP TABLE c108_base CASCADE;

-- ===== Test Case 15 (commit 108) =====
DROP TABLE IF EXISTS c108_t1, c108_t2 CASCADE;
CREATE TABLE c108_t1 (a int, b text);
CREATE TABLE c108_t2 (a int, b text);
INSERT INTO c108_t1 VALUES (1, 'x'), (2, 'y');
INSERT INTO c108_t2 VALUES (3, 'z'), (4, 'w');
SELECT a, COUNT(*) FROM (
  SELECT a, b FROM c108_t1
  UNION ALL
  SELECT a, b FROM c108_t2
) sub GROUP BY a ORDER BY a;
DROP TABLE c108_t1, c108_t2 CASCADE;

-- ===== Test Case 16 (commit 109) =====
DROP TABLE IF EXISTS c109_t1, c109_t2, c109_outer CASCADE;
CREATE TABLE c109_t1(id int, val int);
CREATE TABLE c109_t2(id int, val int);
CREATE TABLE c109_outer(id int, data text);
INSERT INTO c109_t1 VALUES (1, 10), (2, 20), (3, 30);
INSERT INTO c109_t2 VALUES (2, 200), (3, 300), (4, 400);
INSERT INTO c109_outer VALUES (1, 'a'), (2, 'b'), (3, 'c');
ANALYZE c109_t1, c109_t2, c109_outer;
SELECT c109_outer.id, c109_outer.data, combined.val
FROM c109_outer
JOIN (
    SELECT id, val FROM c109_t1
    UNION ALL
    SELECT id, val FROM c109_t2
) AS combined(id, val)
ON c109_outer.id = combined.id
ORDER BY c109_outer.id;
DROP TABLE c109_t1, c109_t2, c109_outer CASCADE;

-- ===== Test Case 17 (commit 109) =====
DROP TABLE IF EXISTS c109_a, c109_b, c109_c CASCADE;
CREATE TABLE c109_a(x int, y int);
CREATE TABLE c109_b(x int, y int);
CREATE TABLE c109_c(x int, z text);
INSERT INTO c109_a SELECT i, i*2 FROM generate_series(1,50) i;
INSERT INTO c109_b SELECT i, i*3 FROM generate_series(1,50) i;
INSERT INTO c109_c SELECT i, 'val'||i FROM generate_series(1,20) i;
ANALYZE c109_a, c109_b, c109_c;
SELECT c.x, c.z, u.y
FROM c109_c c
JOIN (
    SELECT x, y FROM c109_a WHERE y > 10
    UNION ALL
    SELECT x, y FROM c109_b WHERE y < 100
) u ON c.x = u.x
WHERE c.x < 15;
DROP TABLE c109_a, c109_b, c109_c CASCADE;

-- ===== Test Case 18 (commit 109) =====
DROP TABLE IF EXISTS c109_p, c109_q, c109_r, c109_main CASCADE;
CREATE TABLE c109_p(k int, v int);
CREATE TABLE c109_q(k int, v int);
CREATE TABLE c109_r(k int, v int);
CREATE TABLE c109_main(k int, descr text);
INSERT INTO c109_p VALUES (1, 100), (2, 200);
INSERT INTO c109_q VALUES (2, 250), (3, 300);
INSERT INTO c109_r VALUES (3, 350), (4, 400);
INSERT INTO c109_main VALUES (1, 'alpha'), (2, 'beta'), (3, 'gamma');
ANALYZE c109_p, c109_q, c109_r, c109_main;
SELECT m.k, m.descr, combined.v
FROM c109_main m
JOIN (
    SELECT k, v FROM c109_p
    UNION ALL
    SELECT k, v FROM c109_q
    UNION ALL
    SELECT k, v FROM c109_r
) AS combined ON m.k = combined.k;
DROP TABLE c109_p, c109_q, c109_r, c109_main CASCADE;

-- ===== Test Case 19 (commit 110) =====
SELECT 1;

-- ===== Test Case 20 (commit 111) =====
SELECT 1;

-- ===== Test Case 21 (commit 112) =====
SELECT 1;

-- ===== Test Case 22 (commit 113) =====
SELECT 1;

-- ===== Test Case 23 (commit 114) =====
SELECT 1;

-- ===== Test Case 24 (commit 115) =====
SELECT 1;

-- ===== Test Case 25 (commit 116) =====
DROP FUNCTION IF EXISTS c116_bad3() CASCADE;
CREATE FUNCTION c116_bad3() RETURNS int LANGUAGE sql AS $$ SELECT 1 +++ $$;
SELECT 1;

-- ===== Test Case 26 (commit 116) =====
DROP FUNCTION IF EXISTS c116_bad_plpg2() CASCADE;
CREATE FUNCTION c116_bad_plpg2() RETURNS void LANGUAGE plpgsql AS $$ BEGIN IF THEN END IF; END $$;
SELECT 1;

-- ===== Test Case 27 (commit 116) =====
DROP FUNCTION IF EXISTS c116_bad_body() CASCADE;
CREATE FUNCTION c116_bad_body() RETURNS int LANGUAGE sql AS $$ SELECT ; $$;
SELECT 1;

-- ===== Test Case 28 (commit 117) =====
DROP TABLE IF EXISTS c117_refD CASCADE;
DROP TABLE IF EXISTS c117_parD CASCADE;
CREATE TABLE c117_refD (id int PRIMARY KEY);
CREATE TABLE c117_parD (id int NOT NULL REFERENCES c117_refD(id)) PARTITION BY RANGE (id);
CREATE TABLE c117_parD_a PARTITION OF c117_parD FOR VALUES FROM (1) TO (50);
CREATE TABLE c117_parD_b PARTITION OF c117_parD FOR VALUES FROM (50) TO (100);
INSERT INTO c117_refD SELECT generate_series(1,30);
INSERT INTO c117_parD SELECT generate_series(1,30);
ALTER TABLE c117_parD DETACH PARTITION c117_parD_a;
SELECT conname FROM pg_constraint WHERE conrelid='c117_parD_a'::regclass AND contype='f';
DROP TABLE IF EXISTS c117_parD_a CASCADE;
DROP TABLE IF EXISTS c117_parD CASCADE;
DROP TABLE IF EXISTS c117_refD CASCADE;

-- ===== Test Case 29 (commit 117) =====
DROP TABLE IF EXISTS c117_refD2 CASCADE;
DROP TABLE IF EXISTS c117_parD2 CASCADE;
CREATE TABLE c117_refD2 (k int PRIMARY KEY);
CREATE TABLE c117_parD2 (k int NOT NULL REFERENCES c117_refD2(k)) PARTITION BY LIST (k);
CREATE TABLE c117_parD2_x PARTITION OF c117_parD2 FOR VALUES IN (1,2,3);
CREATE TABLE c117_parD2_y PARTITION OF c117_parD2 FOR VALUES IN (4,5,6);
INSERT INTO c117_refD2 VALUES (1),(2),(4),(5);
INSERT INTO c117_parD2 VALUES (1),(4);
ALTER TABLE c117_parD2 DETACH PARTITION c117_parD2_x;
ALTER TABLE c117_parD2 DETACH PARTITION c117_parD2_y;
SELECT conname, contype FROM pg_constraint WHERE conrelid='c117_parD2_x'::regclass;
DROP TABLE IF EXISTS c117_parD2_x CASCADE;
DROP TABLE IF EXISTS c117_parD2_y CASCADE;
DROP TABLE IF EXISTS c117_parD2 CASCADE;
DROP TABLE IF EXISTS c117_refD2 CASCADE;

-- ===== Test Case 30 (commit 118) =====
DROP TABLE IF EXISTS c118_t3 CASCADE;
CREATE TABLE c118_t3 (id int);
CREATE RULE "_RETURN" AS ON UPDATE TO c118_t3 DO INSTEAD NOTHING;
DROP TABLE IF EXISTS c118_t3 CASCADE;

-- ===== Test Case 31 (commit 118) =====
DROP TABLE IF EXISTS c118_t4 CASCADE;
CREATE TABLE c118_t4 (id int);
CREATE RULE "_RETURN" AS ON DELETE TO c118_t4 DO ALSO SELECT 1;
DROP TABLE IF EXISTS c118_t4 CASCADE;

-- ===== Test Case 32 (commit 118) =====
DROP TABLE IF EXISTS c118_t5 CASCADE;
CREATE TABLE c118_t5 (id int, val text);
CREATE RULE "_RETURN" AS ON INSERT TO c118_t5 WHERE (NEW.id > 0) DO INSTEAD NOTHING;
DROP TABLE IF EXISTS c118_t5 CASCADE;

-- ===== Test Case 33 (commit 119) =====
SELECT 1;

-- ===== Test Case 34 (commit 120) =====
DROP VIEW IF EXISTS c120_v3 CASCADE;
DROP TABLE IF EXISTS c120_base3 CASCADE;
CREATE TABLE c120_base3 (a int DEFAULT 1, b text DEFAULT 'hello', c float DEFAULT 9.9);
CREATE VIEW c120_v3 AS SELECT a,b,c FROM c120_base3;
CREATE RULE c120_r3 AS ON INSERT TO c120_v3 DO ALSO
  INSERT INTO c120_base3(a,b,c) VALUES (1, 'hello', 9.9);
INSERT INTO c120_v3 VALUES (2, 'x', 1.5), (3, 'y', 2.5);
SELECT * FROM c120_base3 ORDER BY a;
DROP VIEW IF EXISTS c120_v3 CASCADE;
DROP TABLE IF EXISTS c120_base3 CASCADE;

-- ===== Test Case 35 (commit 120) =====
DROP VIEW IF EXISTS c120_v4 CASCADE;
DROP TABLE IF EXISTS c120_base4 CASCADE;
CREATE TABLE c120_base4 (x int DEFAULT 42, y int DEFAULT 0);
CREATE VIEW c120_v4 AS SELECT x,y FROM c120_base4;
CREATE RULE c120_r4a AS ON INSERT TO c120_v4 DO ALSO UPDATE c120_base4 SET y = y+1 WHERE x = 42;
CREATE RULE c120_r4b AS ON INSERT TO c120_v4 DO ALSO INSERT INTO c120_base4(x,y) VALUES (42, 0);
INSERT INTO c120_v4 VALUES (1,1),(2,2),(3,3);
SELECT COUNT(*) FROM c120_base4;
DROP VIEW IF EXISTS c120_v4 CASCADE;
DROP TABLE IF EXISTS c120_base4 CASCADE;

-- ===== Test Case 36 (commit 120) =====
DROP VIEW IF EXISTS c120_v5 CASCADE;
DROP TABLE IF EXISTS c120_base5 CASCADE;
DROP TABLE IF EXISTS c120_log5 CASCADE;
CREATE TABLE c120_base5 (id serial, val text DEFAULT 'default_val');
CREATE TABLE c120_log5 (id int, val text, logged_at timestamp DEFAULT now());
CREATE VIEW c120_v5 AS SELECT id, val FROM c120_base5;
CREATE RULE c120_r5 AS ON INSERT TO c120_v5 DO ALSO
  INSERT INTO c120_log5(id, val) VALUES (DEFAULT, DEFAULT);
INSERT INTO c120_v5(id, val) VALUES (DEFAULT, DEFAULT), (DEFAULT, 'x'), (DEFAULT, DEFAULT);
SELECT count(*) FROM c120_log5;
DROP VIEW IF EXISTS c120_v5 CASCADE;
DROP TABLE IF EXISTS c120_base5 CASCADE;
DROP TABLE IF EXISTS c120_log5 CASCADE;

-- ===== Test Case 37 (commit 121) =====
SELECT 1;

-- ===== Test Case 38 (commit 122) =====
DROP TABLE IF EXISTS c122_agg1 CASCADE;
CREATE TABLE c122_agg1 (id int, arr int[]);
INSERT INTO c122_agg1 SELECT i, ARRAY[i, i+1, i+2] FROM generate_series(1,20) i;
SELECT id, array_agg(arr) FROM c122_agg1 GROUP BY id ORDER BY id LIMIT 5;
DROP TABLE IF EXISTS c122_agg1 CASCADE;

-- ===== Test Case 39 (commit 122) =====
DROP TABLE IF EXISTS c122_agg2 CASCADE;
CREATE TABLE c122_agg2 (grp int, val jsonb);
INSERT INTO c122_agg2 SELECT i%5, jsonb_build_object('k', i) FROM generate_series(1,50) i;
SELECT grp, jsonb_agg(val ORDER BY (val->>'k')::int) FROM c122_agg2 GROUP BY grp ORDER BY grp;
DROP TABLE IF EXISTS c122_agg2 CASCADE;

-- ===== Test Case 40 (commit 122) =====
DROP TYPE IF EXISTS c122_comp CASCADE;
CREATE TYPE c122_comp AS (x int, y text);
DROP TABLE IF EXISTS c122_agg3 CASCADE;
CREATE TABLE c122_agg3 (grp int, v c122_comp);
INSERT INTO c122_agg3 SELECT i%3, ROW(i, i::text)::c122_comp FROM generate_series(1,30) i;
SELECT grp, count(*), array_agg(v) FROM c122_agg3 GROUP BY grp ORDER BY grp;
DROP TABLE IF EXISTS c122_agg3 CASCADE;
DROP TYPE IF EXISTS c122_comp CASCADE;

-- ===== Test Case 41 (commit 123) =====
SELECT 1;

-- ===== Test Case 42 (commit 124) =====
SELECT 1;

-- ===== Test Case 43 (commit 125) =====
DROP TABLE IF EXISTS c125_heap CASCADE;
CREATE TABLE c125_heap (id int, val text);
INSERT INTO c125_heap SELECT i, repeat('x', 50) FROM generate_series(1, 500) i;
VACUUM c125_heap;
UPDATE c125_heap SET val = repeat('y', 50) WHERE id BETWEEN 1 AND 100;
UPDATE c125_heap SET val = repeat('z', 50) WHERE id BETWEEN 101 AND 200;
SELECT COUNT(*) FROM c125_heap WHERE val LIKE 'y%';
DROP TABLE IF EXISTS c125_heap CASCADE;

-- ===== Test Case 44 (commit 125) =====
DROP TABLE IF EXISTS c125_del CASCADE;
CREATE TABLE c125_del (id int PRIMARY KEY, v text);
INSERT INTO c125_del SELECT i, 'v'||i FROM generate_series(1,200) i;
VACUUM c125_del;
DELETE FROM c125_del WHERE id % 3 = 0;
SELECT COUNT(*) FROM c125_del;
DROP TABLE IF EXISTS c125_del CASCADE;

-- ===== Test Case 45 (commit 125) =====
DROP TABLE IF EXISTS c125_upd CASCADE;
CREATE TABLE c125_upd (id int, val text);
INSERT INTO c125_upd SELECT i, 'v'||i FROM generate_series(1,300) i;
VACUUM ANALYZE c125_upd;
UPDATE c125_upd SET val = 'updated_'||id WHERE id BETWEEN 1 AND 100;
UPDATE c125_upd SET val = 'pass2_'||id WHERE id BETWEEN 50 AND 150;
DELETE FROM c125_upd WHERE id BETWEEN 200 AND 300;
VACUUM c125_upd;
SELECT COUNT(*) FROM c125_upd;
DROP TABLE IF EXISTS c125_upd CASCADE;

-- ===== Test Case 46 (commit 126) =====
SELECT 1;

-- ===== Test Case 47 (commit 127) =====
DROP TABLE IF EXISTS c127_ref2 CASCADE;
DROP TABLE IF EXISTS c127_part2 CASCADE;
CREATE TABLE c127_ref2 (id int PRIMARY KEY);
CREATE TABLE c127_part2 (id int NOT NULL REFERENCES c127_ref2(id)) PARTITION BY LIST (id);
CREATE TABLE c127_new_part (LIKE c127_part2);
INSERT INTO c127_ref2 VALUES (1),(2),(4);
ALTER TABLE c127_part2 ATTACH PARTITION c127_new_part FOR VALUES IN (1,2,3,4);
INSERT INTO c127_part2 VALUES (1),(2),(4);
DROP TABLE IF EXISTS c127_part2 CASCADE;
DROP TABLE IF EXISTS c127_ref2 CASCADE;

-- ===== Test Case 48 (commit 127) =====
DROP TABLE IF EXISTS c127_ref3 CASCADE;
DROP TABLE IF EXISTS c127_par3 CASCADE;
CREATE TABLE c127_ref3 (k int PRIMARY KEY);
CREATE TABLE c127_par3 (k int NOT NULL REFERENCES c127_ref3(k)) PARTITION BY RANGE (k);
CREATE TABLE c127_par3_p1 (LIKE c127_par3);
CREATE TABLE c127_par3_p2 (LIKE c127_par3);
INSERT INTO c127_ref3 SELECT generate_series(1,10);
ALTER TABLE c127_par3 ATTACH PARTITION c127_par3_p1 FOR VALUES FROM (1) TO (5);
ALTER TABLE c127_par3 ATTACH PARTITION c127_par3_p2 FOR VALUES FROM (5) TO (100);
INSERT INTO c127_par3 SELECT generate_series(1,8);
DROP TABLE IF EXISTS c127_par3 CASCADE;
DROP TABLE IF EXISTS c127_ref3 CASCADE;

-- ===== Test Case 49 (commit 127) =====
DROP TABLE IF EXISTS c127_ref4 CASCADE;
DROP TABLE IF EXISTS c127_par4 CASCADE;
DROP TABLE IF EXISTS c127_par4_p1 CASCADE;
CREATE TABLE c127_ref4 (id int PRIMARY KEY);
CREATE TABLE c127_par4 (id int NOT NULL REFERENCES c127_ref4(id)) PARTITION BY RANGE (id);
CREATE TABLE c127_par4_p1 (LIKE c127_par4);
INSERT INTO c127_ref4 VALUES (1),(5),(10);
ALTER TABLE c127_par4 ATTACH PARTITION c127_par4_p1 FOR VALUES FROM (1) TO (20);
INSERT INTO c127_par4 VALUES (1),(5),(10);
SELECT COUNT(*) FROM c127_par4;
DROP TABLE IF EXISTS c127_par4 CASCADE;
DROP TABLE IF EXISTS c127_ref4 CASCADE;

-- ===== Test Case 50 (commit 128) =====
SELECT 1;

-- ===== Test Case 51 (commit 129) =====
DROP TABLE IF EXISTS c129_large, c129_small CASCADE;
CREATE TABLE c129_large AS SELECT i AS id, md5(i::text) AS data FROM generate_series(1, 5000) i;
CREATE TABLE c129_small AS SELECT i AS id, md5(i::text) AS data FROM generate_series(1, 2500) i;
ANALYZE c129_large, c129_small;
SET work_mem = '1MB';
SET enable_hashjoin = on;
SET enable_mergejoin = off;
SET enable_nestloop = off;
SELECT COUNT(*) FROM c129_large JOIN c129_small ON c129_large.id = c129_small.id;
RESET work_mem;
RESET enable_hashjoin;
RESET enable_mergejoin;
RESET enable_nestloop;
DROP TABLE c129_large, c129_small CASCADE;

-- ===== Test Case 52 (commit 129) =====
DROP TABLE IF EXISTS c129_h1, c129_h2 CASCADE;
CREATE TABLE c129_h1(x int, y text);
CREATE TABLE c129_h2(x int, z text);
INSERT INTO c129_h1 SELECT i, 'row'||i FROM generate_series(1,1000) i;
INSERT INTO c129_h2 SELECT i, 'col'||i FROM generate_series(1,800) i;
ANALYZE c129_h1, c129_h2;
SET enable_hashjoin = on;
SELECT COUNT(*) FROM c129_h1 JOIN c129_h2 ON c129_h1.x = c129_h2.x;
RESET enable_hashjoin;
DROP TABLE c129_h1, c129_h2 CASCADE;

-- ===== Test Case 53 (commit 130) =====
SELECT 1;

-- ===== Test Case 54 (commit 131) =====
SELECT 1;

-- ===== Test Case 55 (commit 132) =====
SELECT 1;

-- ===== Test Case 56 (commit 133) =====
SELECT COUNT(*) FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='pg_catalog';
SELECT COUNT(*) FROM pg_proc WHERE pronamespace='pg_catalog'::regnamespace;
SELECT COUNT(*) FROM pg_type WHERE typnamespace='pg_catalog'::regnamespace;

-- ===== Test Case 57 (commit 133) =====
DROP TABLE IF EXISTS c133_t1 CASCADE;
CREATE TABLE c133_t1 (id oid, val text);
INSERT INTO c133_t1 SELECT oid, relname FROM pg_class WHERE relkind='r' LIMIT 20;
SELECT COUNT(DISTINCT id) FROM c133_t1;
SELECT * FROM c133_t1 WHERE id = (SELECT min(oid) FROM pg_class WHERE relkind='r');
DROP TABLE IF EXISTS c133_t1 CASCADE;

-- ===== Test Case 58 (commit 134) =====
SELECT 1;

-- ===== Test Case 59 (commit 135) =====
DROP TABLE IF EXISTS c135_noname CASCADE;
CREATE TABLE c135_noname (id int, val text);
INSERT INTO c135_noname VALUES (1,'a'),(2,'b');
SELECT id+0, val||'' FROM c135_noname ORDER BY 1;
SELECT 1+1, 'hello'||' '||'world';
SELECT CASE WHEN id > 1 THEN 'big' ELSE 'small' END FROM c135_noname;
DROP TABLE IF EXISTS c135_noname CASCADE;

-- ===== Test Case 60 (commit 135) =====
DROP VIEW IF EXISTS c135_v1 CASCADE;
CREATE VIEW c135_v1 AS SELECT 1+1 AS result, now() AS ts, 'str'||'cat' AS s;
SELECT pg_get_viewdef('c135_v1'::regclass, true);
DROP VIEW IF EXISTS c135_v1 CASCADE;

-- ===== Test Case 61 (commit 135) =====
SELECT 1+2, 'a'||'b', length('test'), upper('hello');
SELECT COALESCE(NULL, 1), NULLIF(1,1), GREATEST(1,2,3);
SELECT array_length(ARRAY[1,2,3], 1), cardinality(ARRAY[1,2,3]);

-- ===== Test Case 62 (commit 136) =====
DROP OPERATOR CLASS IF EXISTS c136_oc2 USING btree CASCADE;
CREATE OPERATOR CLASS c136_oc2 FOR TYPE int4 USING btree AS
  OPERATOR 1 < ,
  OPERATOR 2 <= ,
  OPERATOR 3 = ,
  OPERATOR 4 >= ,
  OPERATOR 5 > ;
SELECT opcname, opcintype::regtype FROM pg_opclass WHERE opcname='c136_oc2';
DROP OPERATOR CLASS IF EXISTS c136_oc2 USING btree CASCADE;

-- ===== Test Case 63 (commit 136) =====
DROP OPERATOR CLASS IF EXISTS c136_oc3 USING hash CASCADE;
CREATE OPERATOR CLASS c136_oc3 FOR TYPE int4 USING hash AS
  FUNCTION 1 hashint4(int4);
SELECT opcname FROM pg_opclass WHERE opcname='c136_oc3';
DROP OPERATOR CLASS IF EXISTS c136_oc3 USING hash CASCADE;

-- ===== Test Case 64 (commit 137) =====
SELECT 1;

-- ===== Test Case 65 (commit 138) =====
DROP TABLE IF EXISTS c138_mv_t CASCADE;
CREATE TABLE c138_mv_t (id int, val text);
INSERT INTO c138_mv_t SELECT i, 'v'||i FROM generate_series(1,50) i;
DROP MATERIALIZED VIEW IF EXISTS c138_mv1;
CREATE MATERIALIZED VIEW c138_mv1 AS SELECT id, upper(val) AS uval FROM c138_mv_t;
REFRESH MATERIALIZED VIEW c138_mv1;
SELECT COUNT(*) FROM c138_mv1;
CREATE UNIQUE INDEX ON c138_mv1(id);
REFRESH MATERIALIZED VIEW CONCURRENTLY c138_mv1;
SELECT COUNT(*) FROM c138_mv1 WHERE id > 25;
DROP MATERIALIZED VIEW IF EXISTS c138_mv1;
DROP TABLE IF EXISTS c138_mv_t CASCADE;

-- ===== Test Case 66 (commit 139) =====
SELECT 1;

-- ===== Test Case 67 (commit 140) =====
DROP TABLE IF EXISTS c140_t1 CASCADE;
CREATE TABLE c140_t1 (id int PRIMARY KEY, val text);
INSERT INTO c140_t1 SELECT i, 'val'||i FROM generate_series(1,100) i;
VACUUM c140_t1;
SELECT * FROM c140_t1 WHERE id = 1;
SELECT * FROM c140_t1 WHERE id = 50;
SELECT COUNT(*) FROM c140_t1;
DROP TABLE IF EXISTS c140_t1 CASCADE;

-- ===== Test Case 68 (commit 140) =====
DROP TABLE IF EXISTS c140_t2 CASCADE;
CREATE TABLE c140_t2 (id int, v text);
INSERT INTO c140_t2 VALUES (1,'a'),(2,'b'),(3,'c');
BEGIN;
DELETE FROM c140_t2 WHERE id=2;
SELECT * FROM c140_t2;
ROLLBACK;
SELECT COUNT(*) FROM c140_t2;
DROP TABLE IF EXISTS c140_t2 CASCADE;

-- ===== Test Case 69 (commit 141) =====
SELECT 1;

-- ===== Test Case 70 (commit 142) =====
SELECT 1;

-- ===== Test Case 71 (commit 143) =====
DROP TABLE IF EXISTS c143_idx_t CASCADE;
CREATE TABLE c143_idx_t (id int, val text) PARTITION BY RANGE (id);
CREATE TABLE c143_idx_child1 PARTITION OF c143_idx_t FOR VALUES FROM (1) TO (100);
CREATE TABLE c143_idx_child2 PARTITION OF c143_idx_t FOR VALUES FROM (100) TO (200);
CREATE INDEX c143_pidx ON c143_idx_t (id);
INSERT INTO c143_idx_t SELECT i, 'v'||i FROM generate_series(1,150) i;
DROP INDEX IF EXISTS c143_pidx;
DROP TABLE IF EXISTS c143_idx_t CASCADE;

-- ===== Test Case 72 (commit 143) =====
DROP TABLE IF EXISTS c143_t2 CASCADE;
CREATE TABLE c143_t2 (x int, y int) PARTITION BY HASH (x);
CREATE TABLE c143_t2_p0 PARTITION OF c143_t2 FOR VALUES WITH (MODULUS 3, REMAINDER 0);
CREATE TABLE c143_t2_p1 PARTITION OF c143_t2 FOR VALUES WITH (MODULUS 3, REMAINDER 1);
CREATE TABLE c143_t2_p2 PARTITION OF c143_t2 FOR VALUES WITH (MODULUS 3, REMAINDER 2);
CREATE INDEX ON c143_t2 (x);
INSERT INTO c143_t2 SELECT i, i*2 FROM generate_series(1,30) i;
DROP TABLE IF EXISTS c143_t2 CASCADE;

-- ===== Test Case 73 (commit 143) =====
DROP TABLE IF EXISTS c143_t3 CASCADE;
CREATE TABLE c143_t3 (a int) PARTITION BY LIST (a);
CREATE TABLE c143_t3_odd PARTITION OF c143_t3 FOR VALUES IN (1,3,5,7,9);
CREATE TABLE c143_t3_even PARTITION OF c143_t3 FOR VALUES IN (2,4,6,8,10);
CREATE INDEX c143_idx3 ON c143_t3 (a);
INSERT INTO c143_t3 SELECT (i%10)+1 FROM generate_series(1,50) i;
DROP INDEX IF EXISTS c143_idx3;
DROP TABLE IF EXISTS c143_t3 CASCADE;

-- ===== Test Case 74 (commit 144) =====
DROP TABLE IF EXISTS c144_base CASCADE;
CREATE TABLE c144_base (id int, v text);
INSERT INTO c144_base SELECT i, 'val'||i FROM generate_series(1,100) i;
CHECKPOINT;
SELECT pg_current_wal_lsn();
SELECT * FROM c144_base WHERE id = 42;
CHECKPOINT;
DROP TABLE IF EXISTS c144_base CASCADE;

-- ===== Test Case 75 (commit 145) =====
SELECT 1;

-- ===== Test Case 76 (commit 146) =====
SET enable_hashjoin=off; SET enable_nestloop=off; SET enable_mergejoin=on; SET enable_sort=off; SET enable_seqscan=off;
DROP FUNCTION IF EXISTS c146cmp2(int,int) CASCADE;
CREATE FUNCTION c146cmp2(a int, b int) RETURNS int LANGUAGE plpgsql IMMUTABLE AS 91595 BEGIN RETURN CASE WHEN a > b THEN -1 WHEN a < b THEN 1 ELSE 0 END; END 91595;
CREATE OPERATOR CLASS c146oc2 FOR TYPE int4 USING btree AS
  OPERATOR 1 < (int4,int4), OPERATOR 2 <= (int4,int4),
  OPERATOR 3 = (int4,int4), OPERATOR 4 >= (int4,int4),
  OPERATOR 5 > (int4,int4), FUNCTION 1 c146cmp2(int,int);
DROP TABLE IF EXISTS c146_t3 CASCADE;
DROP TABLE IF EXISTS c146_t4 CASCADE;
CREATE TABLE c146_t3 (id int);
CREATE TABLE c146_t4 (id int);
INSERT INTO c146_t3 VALUES (3),(1),(2);
INSERT INTO c146_t4 VALUES (1),(2),(3);
CREATE INDEX c146_idx3 ON c146_t3 USING btree (id c146oc2);
CREATE INDEX c146_idx4 ON c146_t4 USING btree (id c146oc2);
SELECT * FROM c146_t3, c146_t4 WHERE c146_t3.id = c146_t4.id;
DROP TABLE IF EXISTS c146_t3 CASCADE; DROP TABLE IF EXISTS c146_t4 CASCADE;
DROP OPERATOR CLASS IF EXISTS c146oc2 USING btree CASCADE;
DROP FUNCTION IF EXISTS c146cmp2(int,int) CASCADE;
RESET enable_hashjoin; RESET enable_nestloop; RESET enable_mergejoin; RESET enable_sort; RESET enable_seqscan;

-- ===== Test Case 77 (commit 147) =====
SELECT 1;

-- ===== Test Case 78 (commit 148) =====
SET track_commit_timestamp = off;
DROP TABLE IF EXISTS c148_t CASCADE;
CREATE TABLE c148_t (id int);
INSERT INTO c148_t SELECT generate_series(1, 10);
BEGIN;
SAVEPOINT sp1;
INSERT INTO c148_t VALUES (100);
SAVEPOINT sp2;
INSERT INTO c148_t VALUES (200);
RELEASE SAVEPOINT sp2;
COMMIT;
SELECT COUNT(*) FROM c148_t;
DROP TABLE IF EXISTS c148_t CASCADE;

-- ===== Test Case 79 (commit 149) =====
DROP VIEW IF EXISTS c149_vw1 CASCADE;
CREATE VIEW c149_vw1 AS SELECT t.* FROM (SELECT 1 AS id, 'x'::text AS val) t;
SELECT pg_get_viewdef('c149_vw1'::regclass, true);
DROP VIEW IF EXISTS c149_vw1 CASCADE;

-- ===== Test Case 80 (commit 149) =====
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

-- ===== Test Case 81 (commit 150) =====
SELECT 1;

