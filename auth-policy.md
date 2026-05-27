# Authorization Policy

Family worldschool pages require authorization.

## Rules

1. A family key, such as `mcshan`, identifies a workspace but does not grant access.
2. Families are Supabase records with authorized member rows.
3. Private family repositories remain private.
4. The site must authenticate users before returning family content.
5. The site must verify the authenticated Supabase user is a member of the requested family.
6. Unauthorized users receive a sign-in or access-request state.
7. Public Pages output contains only approved public-safe artifacts.

## Initial Family Mapping

```json
{
  "mcshan": {
    "repository": "CastaliaInstitute/castalia-family-mcshan",
    "auth_provider": "Supabase",
    "members": "managed in Supabase"
  }
}
```
