-- ===== Commit 116 =====
-- Source:  - 

-- --- Test Case 1 ---
DROP FUNCTION IF EXISTS c116_bad3() CASCADE;
CREATE FUNCTION c116_bad3() RETURNS int LANGUAGE sql AS $$ SELECT 1 +++ $$;
SELECT 1;

-- --- Test Case 2 ---
DROP FUNCTION IF EXISTS c116_bad_plpg2() CASCADE;
CREATE FUNCTION c116_bad_plpg2() RETURNS void LANGUAGE plpgsql AS $$ BEGIN IF THEN END IF; END $$;
SELECT 1;

-- --- Test Case 3 ---
DROP FUNCTION IF EXISTS c116_bad_body() CASCADE;
CREATE FUNCTION c116_bad_body() RETURNS int LANGUAGE sql AS $$ SELECT ; $$;
SELECT 1;

