-- ===== Commit 146 =====
-- Source:  - 

-- --- Test Case 1 ---
SET enable_hashjoin=off; SET enable_nestloop=off; SET enable_mergejoin=on; SET enable_sort=off; SET enable_seqscan=off;
DROP FUNCTION IF EXISTS c146cmp(int,int) CASCADE;
CREATE FUNCTION c146cmp(a int, b int) RETURNS int LANGUAGE plpgsql IMMUTABLE AS $$ BEGIN RETURN CASE WHEN a<b THEN -1 WHEN a>b THEN 1 ELSE 0 END; END $$;
CREATE OPERATOR CLASS c146oc FOR TYPE int4 USING btree AS OPERATOR 1 <, OPERATOR 2 <=, OPERATOR 3 =, OPERATOR 4 >=, OPERATOR 5 >, FUNCTION 1 c146cmp(int,int);
DROP TABLE IF EXISTS c146a CASCADE; DROP TABLE IF EXISTS c146b CASCADE;
CREATE TABLE c146a(v int); CREATE TABLE c146b(v int);
INSERT INTO c146a SELECT generate_series(1,100);
INSERT INTO c146b SELECT generate_series(1,100);
CREATE INDEX c146ai ON c146a USING btree(v c146oc);
CREATE INDEX c146bi ON c146b USING btree(v c146oc);
ANALYZE c146a; ANALYZE c146b;
CREATE OR REPLACE FUNCTION c146cmp(a int, b int) RETURNS int LANGUAGE plpgsql IMMUTABLE AS $$ BEGIN RETURN CASE WHEN a<b THEN 1 WHEN a>b THEN -1 ELSE 0 END; END $$;
SELECT count(*) FROM c146a JOIN c146b ON c146a.v = c146b.v;
DROP TABLE IF EXISTS c146a CASCADE; DROP TABLE IF EXISTS c146b CASCADE;
DROP OPERATOR CLASS IF EXISTS c146oc USING btree CASCADE;
DROP FUNCTION IF EXISTS c146cmp(int,int) CASCADE;

-- --- Test Case 2 ---
SET enable_hashjoin=off; SET enable_nestloop=off; SET enable_mergejoin=on; SET enable_sort=off; SET enable_seqscan=off;
DROP FUNCTION IF EXISTS c146cmp2(int,int) CASCADE;
CREATE FUNCTION c146cmp2(a int, b int) RETURNS int LANGUAGE plpgsql IMMUTABLE AS $cmp$ BEGIN RETURN CASE WHEN a > b THEN -1 WHEN a < b THEN 1 ELSE 0 END; END $cmp$;
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

-- --- Test Case 3 ---
DROP TABLE IF EXISTS c146_l, c146_r CASCADE;
CREATE TABLE c146_l (id int, val int);
CREATE TABLE c146_r (id int, val int);
INSERT INTO c146_l VALUES (1, 10), (2, 20), (3, 30);
INSERT INTO c146_r VALUES (2, 20), (3, 30), (4, 40);
CREATE INDEX c146_l_idx ON c146_l(id);
CREATE INDEX c146_r_idx ON c146_r(id);
ANALYZE c146_l, c146_r;
SET enable_hashjoin = off;
SET enable_nestloop = off;
SET enable_mergejoin = on;
SELECT * FROM c146_l FULL OUTER JOIN c146_r
  ON c146_l.id = c146_r.id AND FALSE;
RESET enable_hashjoin;
RESET enable_nestloop;
RESET enable_mergejoin;
DROP TABLE c146_l, c146_r CASCADE;

