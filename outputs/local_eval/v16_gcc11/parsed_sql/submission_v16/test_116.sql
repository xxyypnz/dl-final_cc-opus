-- ===== Commit 116 =====
-- Source:  - 

-- --- Test Case 1 ---
DROP FUNCTION IF EXISTS test_bad_sql_func();
CREATE FUNCTION test_bad_sql_func() RETURNS int LANGUAGE sql AS $$ SELECT + $$;
SELECT 1;

-- --- Test Case 2 ---
DROP FUNCTION IF EXISTS test_bad_plpgsql_func();
CREATE FUNCTION test_bad_plpgsql_func() RETURNS int LANGUAGE plpgsql AS $$ BEGIN RETURN ; END $$;
SELECT 1;

-- --- Test Case 3 ---
DO $$ BEGIN IF THEN RAISE NOTICE 'bad'; END IF; END $$;
SELECT 1;

-- --- Test Case 4 ---
DROP FUNCTION IF EXISTS c116_bad_sql() CASCADE;
CREATE FUNCTION c116_bad_sql() RETURNS int LANGUAGE sql AS $$ SELECT + $$;

-- --- Test Case 5 ---
DROP FUNCTION IF EXISTS c116_bad_sql2() CASCADE;
CREATE FUNCTION c116_bad_sql2() RETURNS int LANGUAGE sql AS 'SELECT 1 +';

