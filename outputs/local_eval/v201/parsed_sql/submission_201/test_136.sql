-- ===== Commit 136 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP OPERATOR FAMILY IF EXISTS test_opfamily1 USING btree CASCADE;
DROP OPERATOR CLASS IF EXISTS test_opclass1 USING btree CASCADE;

-- Execution: Create an operator class without an existing operator family, triggering implicit family creation
CREATE OPERATOR CLASS test_opclass1 FOR TYPE int4 USING btree AS
    OPERATOR 1 =,
    FUNCTION 1 btint4cmp(int4, int4);

-- Teardown
DROP OPERATOR CLASS test_opclass1 USING btree CASCADE;
DROP OPERATOR FAMILY IF EXISTS test_opfamily1 USING btree CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP OPERATOR FAMILY IF EXISTS test_opfamily2 USING btree CASCADE;

-- Execution: Create an operator family directly
CREATE OPERATOR FAMILY test_opfamily2 USING btree;

-- Teardown
DROP OPERATOR FAMILY test_opfamily2 USING btree CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP OPERATOR FAMILY IF EXISTS test_opfamily3 USING btree CASCADE;
CREATE OPERATOR FAMILY test_opfamily3 USING btree;

-- Execution: Try to create an operator class that would implicitly create a duplicate operator family
CREATE OPERATOR CLASS test_opclass3 FOR TYPE int4 USING btree FAMILY test_opfamily3 AS
    OPERATOR 1 =,
    FUNCTION 1 btint4cmp(int4, int4);

-- Teardown
DROP OPERATOR CLASS test_opclass3 USING btree CASCADE;
DROP OPERATOR FAMILY test_opfamily3 USING btree CASCADE;

-- --- Test Case 4 ---
DROP EVENT TRIGGER IF EXISTS c136_end_trg;
DROP FUNCTION IF EXISTS c136_end_fn() CASCADE;
DROP OPERATOR CLASS IF EXISTS c136_opclass USING btree CASCADE;
DROP OPERATOR FAMILY IF EXISTS c136_opclass USING btree CASCADE;
CREATE FUNCTION c136_end_fn() RETURNS event_trigger LANGUAGE plpgsql AS $$
DECLARE r record;
BEGIN
  FOR r IN SELECT * FROM pg_event_trigger_ddl_commands() LOOP
    RAISE NOTICE 'c136 ddl_end: % %', r.command_tag, r.object_type;
  END LOOP;
END;
$$;
CREATE EVENT TRIGGER c136_end_trg ON ddl_command_end EXECUTE PROCEDURE c136_end_fn();
CREATE OPERATOR CLASS c136_opclass FOR TYPE int4 USING btree AS
    OPERATOR 1 < ,
    OPERATOR 3 = ,
    OPERATOR 5 > ,
    FUNCTION 1 btint4cmp(int4, int4);
DROP EVENT TRIGGER IF EXISTS c136_end_trg;
DROP OPERATOR CLASS IF EXISTS c136_opclass USING btree CASCADE;
DROP OPERATOR FAMILY IF EXISTS c136_opclass USING btree CASCADE;
DROP FUNCTION IF EXISTS c136_end_fn() CASCADE;

-- --- Test Case 5 ---
DROP OPERATOR CLASS IF EXISTS c136_oc2 USING btree CASCADE;
CREATE OPERATOR CLASS c136_oc2 FOR TYPE int4 USING btree AS
  OPERATOR 1 < ,
  OPERATOR 2 <= ,
  OPERATOR 3 = ,
  OPERATOR 4 >= ,
  OPERATOR 5 > ;
SELECT opcname, opcintype::regtype FROM pg_opclass WHERE opcname='c136_oc2';
DROP OPERATOR CLASS IF EXISTS c136_oc2 USING btree CASCADE;

-- --- Test Case 6 ---
DROP OPERATOR CLASS IF EXISTS c136_oc3 USING hash CASCADE;
CREATE OPERATOR CLASS c136_oc3 FOR TYPE int4 USING hash AS
  FUNCTION 1 hashint4(int4);
SELECT opcname FROM pg_opclass WHERE opcname='c136_oc3';
DROP OPERATOR CLASS IF EXISTS c136_oc3 USING hash CASCADE;

