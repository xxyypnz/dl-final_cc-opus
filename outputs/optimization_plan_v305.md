# v305 Iteration Notes

Baseline for this round: `outputs/submission_303.json`

Local gcc-11 score remains:

- covered: 130 / 198
- global_precision_excl_not_found: 0.6566

## Probes Tried

- `outputs/submission_305_probe101_fixed_noalias.json`
  - Fixed the previous no-alias probe whose views failed due to duplicate output
    column names.
  - The relation conflict view did execute and deparsed as
    `same_name same_name_1`.
  - Result: `101` stayed 20/27. It only increased counts on already covered
    lines such as 10537 and 10563.

- `outputs/submission_305_probe101_rte_plain.json`
  - Added plain function, VALUES, and subquery RTE views with `pg_get_viewdef`.
  - Result: `101` stayed 20/27. Missing lines 10547 and 10553 appear to be
    gcov line-count artifacts around `printalias = true`, not reachable as
    separately counted lines in this build.

## Additional Read

- `133`: missing lines are function signature/check macro lines in
  `list_member_oid`; SQL already hits the loop/body.
- `140`: missing line is a bare `else`; the `ReleaseBuffer` body is already
  covered.
- `127`, `138`, `122`, `120`, `129`: remaining misses are continuation lines
  or bare `else`/assert lines where adjacent body lines are already covered.
- `115`, `144`, `148`: require postmaster/recovery-level environment.
- `116`: historical gain depends on banned `DO` or no-active-portal worker path.
- `125`: historical gain depends on real concurrent client sessions; `dblink`
  is unavailable in the local install and shell/psql meta commands are banned.

## Recommendation

Do not submit v305 probes. No formal `submission_305.json` was generated.

The only remaining practical path is still a compliant way to create true
concurrent tuple locks for commit 125 without psql meta-commands, shell,
server-file access, `dblink`, or C/internal code.
