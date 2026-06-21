-- ===== Commit 136 =====
-- Source:  - 

-- --- Test Case 1 ---
DROP OPERATOR CLASS IF EXISTS c136_oc2 USING btree CASCADE;
CREATE OPERATOR CLASS c136_oc2 FOR TYPE int4 USING btree AS
  OPERATOR 1 < ,
  OPERATOR 2 <= ,
  OPERATOR 3 = ,
  OPERATOR 4 >= ,
  OPERATOR 5 > ;
SELECT opcname, opcintype::regtype FROM pg_opclass WHERE opcname='c136_oc2';
DROP OPERATOR CLASS IF EXISTS c136_oc2 USING btree CASCADE;

-- --- Test Case 2 ---
DROP OPERATOR CLASS IF EXISTS c136_oc3 USING hash CASCADE;
CREATE OPERATOR CLASS c136_oc3 FOR TYPE int4 USING hash AS
  FUNCTION 1 hashint4(int4);
SELECT opcname FROM pg_opclass WHERE opcname='c136_oc3';
DROP OPERATOR CLASS IF EXISTS c136_oc3 USING hash CASCADE;

