# v304 Iteration Notes

Baseline: `outputs/submission_203.json`

Last platform-tested candidate: `outputs/submission_303.json`

Local gcc-11 baseline remains:

- covered: 130 / 198
- global_precision_excl_not_found: 0.6566

## Probes Tried

All probes below passed the strict banned-token scan, but none improved local
coverage over v303.

- `outputs/submission_304_probe101_noalias.json`
  - Tried relation/CTE alias collision cases for `ruleutils.c:get_rte_alias`.
  - Result: `101` stayed 20/27.

- `outputs/submission_304_probe125_dblink.json`
  - Tried replacing the historical shell-based concurrent psql workload with
    `dblink`.
  - Result: no gain. Local coverage build does not install `dblink.control`.

- `outputs/submission_304_probe112_late_nosuper.json`
  - Tried dropping current user superuser privilege late in the run.
  - Result: ordinary table warning was reached, but target lines are the shared
    relation warning branch. `112` stayed 0/2.

- `outputs/submission_304_probe118_more.json`
  - Tried more `_RETURN` rule error variants.
  - Result: `118` stayed 2/6.

- `outputs/submission_304_probe116_plpgsql.json`
  - Tried replacing the banned historical `DO` block with bad `plpgsql` and SQL
    functions.
  - Result: `116` stayed 2/5. The missing line appears tied to the `DO` or
    background-worker no-active-portal path.

## Current Read

The remaining promising historical gains are mostly blocked by environment or
policy:

- `112`: needs non-superuser access to shared catalogs; `SET ROLE` works but is
  banned. Late `ALTER ROLE CURRENT_USER NOSUPERUSER` only reached non-shared
  warning lines.
- `115`: needs `wal_log_hints` or checksums at server start.
- `116`: historical +1 came from banned `DO`.
- `125`: historical +2 came from shell-launched concurrent psql via `\gset`,
  `\setenv`, `\!`.
- `144`: recovery/startup path, not reachable by ordinary SQL workload.
- `148`: needs `track_commit_timestamp` at server start.

## Next Direction

Do not submit any v304 probe as-is.

The only remaining plausible legal direction is to find a pure-SQL way to create
real concurrent tuple locks for `125`, without psql metacommands, shell, server
file access, `dblink`, `COPY PROGRAM`, or C/internal language. If no such
in-cluster mechanism is available on the platform, the attainable compliant
score is likely bounded near the current platform score.
