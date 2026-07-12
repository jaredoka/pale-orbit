# Pale Orbit — GitFlow workflow

Every session works via GitFlow. Remote: https://github.com/jaredoka/pale-orbit

## Branches
- `main` — release-ready only. Each completed milestone (M0…M4) lands here via a release merge, tagged `m0`, `m1`, …
- `develop` — integration branch; always the base for new work.
- `feature/tXX-short-name` — one branch per task from `docs/TASKS.md`, branched off `develop`, merged back with `--no-ff` when the task's verification passes.
- `release/mX` — cut from `develop` when a milestone's tasks are done; final checks, then merge to `main` (tag `mX`) and back to `develop`.
- `hotfix/<name>` — from `main` for urgent fixes; merge to `main` and `develop`.

## Session rules
1. Start: `git fetch`, work from up-to-date `develop`.
2. One task = one feature branch. Commit per meaningful step; run `godot-verify` before merging.
3. Merge feature → develop with `git merge --no-ff`; push after each merge.
4. Milestone complete → `release/mX` → merge to `main`, tag, merge back to `develop`, push all + tags.
5. Never commit directly to `main`.
