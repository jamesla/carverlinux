---
name: worktree-merge
description: Squash the current worktree's branch into a single commit on top of the target branch and fast-forward the target to it, without pushing. Use only when the user explicitly asks to merge a worktree or land it in master - never on your own initiative.
argument-hint: "[target branch, defaults to master]"
---


1. git add and commit any pending changes in the worktree
2. squashes every commit the worktree branch has on top of the local target branch (master unless one is given) into a single commit, with one git conventional commit message covering the whole change
3. rebases that single commit onto the local target branch, resolving conflicts so the changes from both sides are kept
4. fast-forwards the target branch to the worktree branch, from the checkout that has the target branch checked out - never a merge commit, so the worktree lands as exactly one new commit on the target
5. does not push and does not run make rebuild or the tests - that happens in master with the commit skill
6. closes the associated hedr workspace if it is in one and delete the worktree directory
