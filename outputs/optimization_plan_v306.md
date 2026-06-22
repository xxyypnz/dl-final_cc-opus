# v306 125 Investigation

Baseline: `outputs/submission_203.json`.

Current clean local best remains `130/198 = 0.6566` with platform score
reported as `0.6313`.

## Target

Commit `125`, `src/backend/access/heap/heapam.c`, lines 2598/2599:

```c
if ((vmbuffer == InvalidBuffer && PageIsAllVisible(page)) ||
    xmax_infomask_changed(tp.t_data->t_infomask, infomask) ||
```

These lines are inside `heap_delete()` after:

1. `HeapTupleSatisfiesUpdate()` returns `TM_BeingModified`.
2. The tuple xmax is a MultiXact.
3. `DoesMultiXactIdConflict(..., LockTupleExclusive, ...)` returns true.
4. `MultiXactIdWait()` returns and the buffer is reacquired.

## Historical Working Shape

The old v7/v9/v10/v23 gain came from psql meta-command concurrency:

- `SHOW port \gset`
- `\setenv`
- `\! psql ... FOR KEY SHARE ... pg_sleep ... &`
- `\! psql ... FOR SHARE ... pg_sleep ... &`
- main session then `DELETE`

That creates two real concurrent backends holding tuple locks and lets the
main backend wait on the MultiXact. This is now disallowed by the TA notice.

## Legal Probes Tried

`outputs/submission_306_probe125_postgres_fdw.json`

- Local result: no gain, still `130/198 = 0.6566`.
- Reason: local install has only `plpgsql.control`; `postgres_fdw` is not
  installed. The SQL fails with `foreign-data wrapper "postgres_fdw" does not
  exist`.

`outputs/submission_306_probe125_alt.json`

- Local result: no gain, still `130/198 = 0.6566`.
- 125 remains `6/9`; line 2598 count `0`, line 2599 count `0`.
- `PREPARE TRANSACTION` path fails locally because prepared transactions are
  disabled (`max_prepared_transactions = 0`).
- Savepoint / same-backend lock upgrade path does not produce the needed
  concurrent `TM_BeingModified` wait.
- Parallel-worker path fails with `cannot assign XIDs during a parallel
  operation`, so a SQL function running in a parallel worker cannot take tuple
  locks via `SELECT ... FOR SHARE`.

## Current Judgment

Under a single psql script and the current legal constraints, 125 appears to
need a real second backend. The known mechanisms to create one are either
explicitly banned (`\! psql`) or unavailable in the local install
(`dblink`/`postgres_fdw`/background-worker extensions).

The only remaining 125-specific possibility would be a platform-only gamble
that `postgres_fdw` or `dblink` is installed there. Local evidence argues
against recommending it as a formal iteration, and it adds extension
dependency risk without a local score increase.

Recommended next direction: stop making 125 the primary target unless we get
evidence that the platform has loopback-capable contrib extensions installed.
Move back to non-concurrency targets with one-line local gaps or platform/local
divergence.
