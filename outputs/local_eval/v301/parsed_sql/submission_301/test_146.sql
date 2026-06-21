-- ===== Commit 146 =====
-- Source:  - 

-- --- Test Case 1 ---
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

