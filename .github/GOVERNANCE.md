# Repository governance

Adopted baseline: **2026-09-16, Markpad labels** from [PathGao/governance](https://github.com/PathGao/PathGao/tree/main/governance).
Adopted [source snapshot](https://github.com/PathGao/PathGao/tree/46466b51863fdab52d9b1d4d16f1d7d145ebcfb9/governance).
Updates are reviewed and copied manually; there is no automatic inheritance.

## Workflow

Use the short PR template. `Closes #123` or `Fixes #123` closes a completed issue
on merge. For partial work, use `Related to #123` and state what remains. There
is no release-confirmation or inactivity-close automation.

The ten shared labels use Markpad's names, colors and descriptions.
`question` is a usage question; `needs info` waits for reporter input;
`awaiting decision` waits for a maintainer decision; `planned` means accepted.
`Final_Check_Request` is a manual marker for confirmation or incomplete work.
Keep those issues open with normal references until complete; no bot acts on it.
The full set, including project extensions, is defined in [labels.json](labels.json).

## Maintenance

[settings.json](settings.json) and [rulesets/](rulesets/) are desired GitHub
configuration, applied through the API as described in the baseline guide.
Committing these files alone does not change repository settings. Main requires
PRs and blocks deletion/force pushes; administrators retain a recovery bypass.
Release tags matching `v*` cannot be updated/deleted, except `v*-test*` tags.

Preview label changes from the repository root:

```sh
./Tools/sync-labels.sh PathGao/kururu
```

Add `--apply` to create/update the declared labels. Labels outside the manifest
are preserved. Adoption explicitly removes the unused defaults `wontfix`,
`good first issue`, `help wanted`, `invalid` and `duplicate` after checking usage.
A zero-change preview alone does not verify that cleanup.

## Project differences

kururu retains feature-area bug reports and its project-specific build workflow.
The inherited upstream issue status workflow is retired. No sponsor account is
configured for this independent project.

CI was manually disabled when this baseline was adopted. Main currently has no
required status checks. Before adding `Swift 6.0.3 compatibility` and
`Build & selftest`, enable CI and verify a successful current run.
