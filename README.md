# Castalia Worldschool

Standalone GitHub Pages repository for `worldschool.castalia.institute`.

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

1. Create `CastaliaInstitute/worldschool`.
2. Push this directory as the repo root.
3. Enable Pages with source set to `GitHub Actions`.
4. Set the Pages custom domain to `worldschool.castalia.institute`.
5. Add DNS:

```text
worldschool.castalia.institute CNAME castaliainstitute.github.io
```

## Supabase Auth

Family routes use Supabase Auth in the browser and a Supabase authorization RPC.
Set the public project URL and anon key in `assets/supabase-config.js`:

```js
window.CASTALIA_SUPABASE = {
  url: "https://PROJECT_REF.supabase.co",
  anonKey: "PUBLIC_SUPABASE_ANON_KEY",
  familySlug: "mcshan",
  redirectTo: "https://worldschool.castalia.institute/families/mcshan/",
};
```

The page calls this RPC after sign-in:

```sql
select public.user_has_family_access('mcshan');
```

Expected RPC contract:

```sql
\i supabase/family-auth.sql
```

The deployed route must not also be covered by Cloudflare Access. If Cloudflare
Access is enabled for `/families/mcshan/*`, visitors will hit Cloudflare before
the Supabase sign-in page can load.

## Family content publishing

Do not fetch private family repositories from browser JavaScript. Use a
Supabase table/view with row-level security, a server-side service, or a GitHub
Actions workflow with scoped credentials. Verify authorization before returning
family content, and publish only approved output.

The intended document flow is:

1. The private family repository builds or selects approved documents.
2. A server-side job uploads those files to the private Supabase Storage bucket
   `family-documents`, using paths like `mcshan/document-name.pdf`.
3. The same job writes metadata to `family_document_files`.
4. The static family page lists rows visible through RLS and opens short-lived
   signed Storage URLs.

## Itinerary Curriculum

The core planning model is a dated set of family destinations woven into
curriculum units and activities:

```text
families
  -> family_destinations
      -> curriculum_units
          -> curriculum_activities
              -> optional family_document_files artifact
```

Use `family_destinations` for the travel spine: place, dates, and planning
notes. Link `curriculum_units` to destinations when the place anchors a theme,
question, or subject. Link `curriculum_activities` to units for dated learning
work, field notes, readings, assignments, or reflections. Activities can point
to published documents from the private family repo when an artifact belongs in
the authorized family workspace.

See `examples/mcshan-2027-itinerary.yml` for a public-safe starter itinerary.
Before publishing real plans, move the working copy into the private family repo
and let the private repo workflow sync it into Supabase.

## Operations direction

Samwise should eventually handle routine Castalian family and pupil operations:
creating pupil repositories, wiring generation workflows, publishing approved
Gazetteer outputs, and answering where family coordination versus pupil-owned
curriculum data should live. Until that exists, keep these operations scripted
and documented here or in the relevant private repositories.
