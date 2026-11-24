---
name: commit
description: Split the working tree's pending changes into one atomic commit per feature and push them. Use only when the user explicitly asks to commit, commit and push, or ship the current changes - never on your own initiative.
argument-hint: "[what to include or leave out]"
---


1. runs make rebuild and verifies rebuild works
2. reads the test cases defined in @./tests/* and checks everything
3. git add and commit changes atomically using git conventional commits and then pushes
