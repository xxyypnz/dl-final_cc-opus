-- ===== Commit 129 =====
-- Source:  - 

-- --- Test Case 1 ---
SET work_mem = '64kB'; SET enable_nestloop = off; SET enable_mergejoin = off; DROP TABLE IF EXISTS c129_wide CASCADE; CREATE TABLE c129_wide (id int, payload char(90000)); INSERT INTO c129_wide SELECT g, 'x' FROM generate_series(1, 3) g; SELECT count(a.payload), count(b.payload) FROM c129_wide a JOIN c129_wide b ON a.id = b.id; DROP TABLE IF EXISTS c129_wide CASCADE; RESET work_mem; RESET enable_nestloop; RESET enable_mergejoin;

