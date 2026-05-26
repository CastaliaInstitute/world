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

## Cloudflare Access

Protect the McShan family path with Cloudflare Access:

```sh
export CLOUDFLARE_ACCOUNT_ID='...'
export CLOUDFLARE_API_TOKEN='...'
export CLOUDFLARE_FAMILY_MEMBERS='your-google-account@gmail.com'
./scripts/setup-cloudflare-access.sh
```

Defaults:

```text
Hostname: world.castalia.institute
Path: /families/mcshan/*
Access group: Family - McShan
```

Families are Cloudflare Access groups. Add more family members as a
comma-separated list:

```sh
export CLOUDFLARE_FAMILY_MEMBERS='parent1@gmail.com,parent2@gmail.com'
./scripts/setup-cloudflare-access.sh
```

For a family managed as a Google Workspace domain instead of individual Gmail
accounts:

```sh
unset CLOUDFLARE_FAMILY_MEMBERS
export CLOUDFLARE_FAMILY_EMAIL_DOMAIN='example.org'
./scripts/setup-cloudflare-access.sh
```

If the Cloudflare Zero Trust account has multiple identity providers, set the
Google provider explicitly:

```sh
export CLOUDFLARE_ACCESS_IDP_ID='...'
./scripts/setup-cloudflare-access.sh
```

## Family content publishing

Do not fetch private family repositories from browser JavaScript. Use a
server-side service or GitHub Actions workflow with scoped credentials, verify
authorization, and publish only approved output.
