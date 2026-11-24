---
name: worktree-merge
description: Rebase the current worktree's branch onto the target branch and fast-forward the target to it, without pushing. Use only when the user explicitly asks to merge a worktree or land it in master - never on your own initiative.
argument-hint: "[target branch, defaults to master]"
---


1. git add and commit any pending changes in the worktree atomically using git conventional commits
2. rebases the worktree branch onto the local target branch (master unless one is given), resolving conflicts so the changes from both sides are kept
3. fast-forwards the target branch to the worktree branch, from the checkout that has the target branch checked out
4. does not push and does not run make rebuild or the tests - that happens in master with the commit skill
5. closes the associated hedr workspace if it is in one
