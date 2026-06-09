-- ===== Commit 127 =====
-- Source:  - 

-- --- Test Case 1 ---
DROP TABLE IF EXISTS c127_parent CASCADE;
DROP TABLE IF EXISTS c127_child CASCADE;
DROP TABLE IF EXISTS c127_ref CASCADE;
CREATE TABLE c127_ref (id int PRIMARY KEY);
CREATE TABLE c127_parent (id int NOT NULL, ref_id int REFERENCES c127_ref(id)) PARTITION BY LIST (id);
CREATE TABLE c127_child (id int NOT NULL, ref_id int);
ALTER TABLE c127_child ADD CONSTRAINT c127_parent_ref_id_fkey CHECK (ref_id IS NULL OR ref_id IS NOT NULL);
ALTER TABLE c127_parent ATTACH PARTITION c127_child FOR VALUES IN (1);
SELECT conname, contype FROM pg_constraint WHERE conrelid='c127_child'::regclass ORDER BY conname;
DROP TABLE IF EXISTS c127_parent CASCADE;
DROP TABLE IF EXISTS c127_child CASCADE;
DROP TABLE IF EXISTS c127_ref CASCADE;

