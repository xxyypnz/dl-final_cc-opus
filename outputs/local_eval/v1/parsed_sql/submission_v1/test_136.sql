-- ===== Commit 136 =====
-- Source:  - 

-- --- Test Case 1 ---
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

