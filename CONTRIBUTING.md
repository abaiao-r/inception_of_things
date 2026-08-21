# Contributing / Working agreement

Rules the team agreed on for this repository. Everyone must follow them.

## Branch protection (enforced on GitHub for `master`)

- **No direct pushes to `master`** — including for maintainers/admins. All
  changes go through a Pull Request.
- **PRs required** before merging, targeting `master`.
- **At least 1 approving review** required before merge.
- **CI must pass** (the `ci` status check) before a PR can be merged.
- **Branch must be up to date** with `master` before merging.
- **No force-pushes and no deletions** of `master`.
- **Squash merge only** — a PR is merged as a single commit onto `master`
  (keeps history linear and enforces the "one commit per PR" rule below).

## Pull request rules

- **One commit per PR.** Rebase/squash your local branch before opening (or
  updating) the PR: `git rebase -i` or `git commit --amend`. Force-push to
  your own feature branch is fine (never to `master`).
- One feature/fix per PR — keep them small and focused.
- Branch naming: `p1/xxx`, `p2/xxx`, `p3/xxx`, `bonus/xxx`, `fix/xxx`,
  `docs/xxx`.
- Fill in the PR template, link related issues.
- Do not merge your own PR without a review, and do not approve your own PR.

## Commit messages

- Short, imperative summary (e.g. `p1: add controller Vagrantfile`).
- Reference the part folder when relevant (`p1`, `p2`, `p3`, `bonus`).

## CI

- CI runs on every PR (lint/validate scripts and manifests). A red CI blocks
  merging.

## Secrets

- Never commit kubeconfigs, tokens, `.env` files or private keys — see
  `.gitignore`. If something is committed by mistake, rotate it and remove it
  from history.
