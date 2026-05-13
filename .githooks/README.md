# Git hooks — single-main-branch policy

Shipped DORMANT. Activate when ready:

    git config core.hooksPath .githooks

If `git config --get extensions.worktreeConfig` returns `true`, use this
instead so every worktree picks it up:

    git config --file "$(git rev-parse --git-common-dir)/config" core.hooksPath .githooks

Verify:

    git branch __test__   # should print BLOCKED, exit non-zero

Deactivate:

    git config --unset core.hooksPath
    git config --worktree --unset core.hooksPath   # if any worktree has its own override

Hooks:
- reference-transaction: blocks new branch creation
- pre-commit: refuses commits on non-main
- post-checkout: warns when HEAD lands on non-main
