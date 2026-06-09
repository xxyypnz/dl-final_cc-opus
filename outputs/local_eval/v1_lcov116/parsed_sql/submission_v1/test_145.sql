-- ===== Commit 145 =====
-- Source:  - 

-- --- Test Case 1 ---
DROP TABLE IF EXISTS c145_poly CASCADE;
DROP TABLE IF EXISTS c145_outer CASCADE;
CREATE TABLE c145_poly (id int, p polygon);
INSERT INTO c145_poly
  SELECT g,
         ('((' || g || ',' || g || '),('
               || (g+50) || ',' || (g+50) || '),('
               || (g+1)  || ',' || g || '))')::polygon
  FROM generate_series(1,1000) AS g;
CREATE INDEX c145_poly_gist ON c145_poly USING gist (p);
CREATE TABLE c145_outer (qx int);
INSERT INTO c145_outer VALUES (10),(50),(200),(400);
SET enable_seqscan = off;
SET enable_material = off;
SELECT o.qx, count(l.id)
FROM c145_outer o
CROSS JOIN LATERAL (
  SELECT id
  FROM c145_poly
  ORDER BY p <-> point(o.qx + 50, o.qx)
  LIMIT 3
) l
GROUP BY o.qx
ORDER BY o.qx;
RESET enable_seqscan;
RESET enable_material;
DROP TABLE c145_outer;
DROP TABLE c145_poly;

