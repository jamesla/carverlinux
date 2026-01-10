# GitHub Actions Branch Protection Setup

To enable the required PR checks, configure branch protection for your main branch:

## GitHub Web UI Setup

1. Go to your repository on GitHub
2. Click **Settings** → **Branches**
3. Click **Add branch protection rule**
4. Under "Branch name pattern", enter: `main`
5. Enable the following settings:

### Required Settings
- ✅ **Require status checks to pass before merging**
- ✅ **Require branches to be up to date before merging**
- ✅ **Require status checks to pass before merging** (again - this enables individual checks)

### Required Status Checks
Select all of these workflows:
- `flake-check` (from Nix Configuration Validation)
- `syntax-validation` (from Nix Configuration Validation)
- `package-validation` (from Nix Configuration Validation)
- `nix-formatting` (from Code Quality & Formatting)
- `style-consistency` (from Code Quality & Formatting)
- `file-organization` (from Code Quality & Formatting)
- `secret-detection` (from Security & Sensitive Data)
- `security-best-practices` (from Security & Sensitive Data)
- `email-validation` (from Security & Sensitive Data)
- `cross-file-validation` (from Configuration Integrity)
- `makefile-validation` (from Configuration Integrity)
- `patch-integrity` (from Configuration Integrity)
- `readme-validation` (from Documentation & Metadata)
- `agents-compliance` (from Documentation & Metadata)
- `metadata-validation` (from Documentation & Metadata)

### Additional Recommended Settings
- ✅ **Include administrators** (ensures maintainers also follow the rules)
- ✅ **Restrict pushes that create matching branches** (prevents force pushes)
- ✅ **Allow force pushes** for administrators only (if needed)

## Alternative: GitHub CLI Setup

You can also set this up using the GitHub CLI:

```bash
gh api repos/:owner/:repo/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["flake-check","syntax-validation","package-validation","nix-formatting","style-consistency","file-organization","secret-detection","security-best-practices","email-validation","cross-file-validation","makefile-validation","patch-integrity","readme-validation","agents-compliance","metadata-validation"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":0}' \
  --field restrictions=null
```

## What This Achieves

✅ **All PRs must pass validation checks before merging**
✅ **Syntax and formatting are consistently applied**
✅ **Security issues are caught early**
✅ **Configuration integrity is maintained**
✅ **Documentation stays accurate**
✅ **No force pushes to main branch**
✅ **Maintainers follow the same rules as contributors**

## Testing the Setup

After configuring branch protection:

1. Create a test branch: `git checkout -b test-branch-protection`
2. Make a small change (e.g., add a comment to a .nix file)
3. Commit and push: `git push origin test-branch-protection`
4. Create a pull request
5. Verify all checks run and status is enforced

You should see all 15 required checks pass before the merge button becomes available.