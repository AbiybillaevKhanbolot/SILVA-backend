# Security Checklist

## Secrets

- Never commit real values of:
  - `SUPABASE_SERVICE_ROLE_KEY`
  - database passwords
  - personal access tokens
- Keep only template values in `.env.example`.

## Supabase

- Enable RLS on all business tables.
- Keep `is_admin()` as SECURITY DEFINER helper for admin policies.
- Validate that only expected roles are used (`guest`, `owner`, `admin`).

## Storage

- `avatars`: public read, write only to own folder `<uid>/...`.
- `property-images`: public read, owner/admin write limited by folder prefix `<owner_uid>/...`.

## Production Readiness

- Test flows:
  - guest: register/login, favorites, bookings, profile
  - owner: object create/edit, bookings visibility, review responses
  - admin: dashboard stats, feedback access
- Re-check policy behavior in SQL Editor with role simulation.
