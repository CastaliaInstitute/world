# Authorization Policy

Family worldschool pages require authorization.

## Rules

1. A family key, such as `mcshan`, identifies a workspace but does not grant access.
2. Private family repositories remain private.
3. The site must authenticate users before returning family content.
4. The site must verify the authenticated user is authorized for the requested family.
5. Unauthorized users receive a sign-in or access-request state.
6. Public Pages output contains only approved public-safe artifacts.

## Initial Family Mapping

```json
{
  "mcshan": {
    "repository": "CastaliaInstitute/castalia-family-mcshan",
    "access": "authorized-family-members-only"
  }
}
```
