# Castalia Worldschool

Standalone GitHub Pages repository for `world.castalia.institute`.

## Purpose

Castalia Worldschool is the public shell for family worldschool workspaces.
Family routes such as `?f=mcshan` or `/families/mcshan/` identify a requested
workspace, but they do not grant access.

## Authorization

Family access requires authentication and explicit authorization. Private
household data, plans, generated files, manifests, and repository contents must
not be embedded in this public Pages repo unless they have been intentionally
exported as public-safe artifacts.

The McShan family source repository is private:

```text
CastaliaInstitute/castalia-family-mcshan
```

## Structure

```text
.
├── CNAME
├── index.html
├── auth-policy.md
├── families/
│   └── mcshan/
│       └── index.html
└── .github/
    └── workflows/
        └── pages.yml
```

## Deployment

This repo is configured for GitHub Pages via GitHub Actions. In GitHub:

1. Create `CastaliaInstitute/world`.
2. Push this directory as the repo root.
3. Enable Pages with source set to `GitHub Actions`.
4. Set the Pages custom domain to `world.castalia.institute`.
5. Add DNS:

```text
world.castalia.institute CNAME castaliainstitute.github.io
```

## Family content publishing

Do not fetch private family repositories from browser JavaScript. Use a
server-side service or GitHub Actions workflow with scoped credentials, verify
authorization, and publish only approved output.
