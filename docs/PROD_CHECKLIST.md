# Production Checklist

## Security

- [ ] No secrets in repository
- [ ] `.env.example` contains placeholders only
- [ ] RLS enabled for all business tables
- [ ] Storage policies restrict write access by owner/admin

## Functional

- [ ] Guest sees only own bookings/favorites/profile
- [ ] Owner sees only own properties + related bookings/reviews
- [ ] Admin can open dashboard and read feedback
- [ ] New guest loyalty points start at 0

## Release

- [ ] Backend migrations applied to production project
- [ ] Frontend env points to production Supabase
- [ ] Smoke tests passed on deployed frontend
