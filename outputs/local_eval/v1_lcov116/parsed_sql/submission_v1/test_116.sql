-- ===== Commit 116 =====
-- Source:  - 

-- --- Test Case 1 ---
DROP FUNCTION IF EXISTS c116_bad_sql() CASCADE;
CREATE FUNCTION c116_bad_sql() RETURNS int LANGUAGE sql AS $$ SELECT + $$;

-- --- Test Case 2 ---
DROP FUNCTION IF EXISTS c116_bad_sql2() CASCADE;
CREATE FUNCTION c116_bad_sql2() RETURNS int LANGUAGE sql AS 'SELECT 1 +';

