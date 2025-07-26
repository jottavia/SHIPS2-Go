# CI and Lint Workflows Disabled

All GitHub Actions workflows for CI and linting have been disabled as requested.

## Disabled Workflows

The following workflows have been renamed with `.disabled` extension to prevent them from running:

- `.github/workflows/ci.yml` → `.github/workflows/ci.yml.disabled`
- `.github/workflows/golangci-lint.yml` → `.github/workflows/golangci-lint.yml.disabled`
- `.github/workflows/golangci-lint-clean.yml` → `.github/workflows/golangci-lint-clean.yml.disabled`
- `.github/workflows/build-and-release.yml` → `.github/workflows/build-and-release.yml.disabled`

## What was disabled

1. **Continuous Integration (ci.yml)**: Main CI pipeline with linting, testing, and build verification
2. **GoLangCI Lint (golangci-lint.yml)**: Code linting workflow
3. **GoLangCI Lint Clean (golangci-lint-clean.yml)**: Alternative linting configuration
4. **Build and Release (build-and-release.yml)**: Automated build and release workflow for tags

## Re-enabling workflows

To re-enable any workflow in the future:
1. Remove the `.disabled` extension from the filename
2. Commit and push the change

For example, to re-enable CI:
```bash
git mv .github/workflows/ci.yml.disabled .github/workflows/ci.yml
git commit -m "Re-enable CI workflow"
git push
```

## Status

✅ All CI and lint workflows are now disabled and will not run on pushes or pull requests.
