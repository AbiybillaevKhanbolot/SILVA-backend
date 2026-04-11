# SILVA-backend

Backend-infrastructure for the SILVA project on Supabase.

This repository stores backend logic and security rules:
- PostgreSQL schema (tables, enums, constraints)
- Row Level Security (RLS) policies
- Storage policies
- SQL functions for safe role checks
- Edge Functions (e.g. ЮKassa payment proxy)

## Stack

- Supabase (PostgreSQL + Auth + Storage + Edge Functions)
- SQL migrations

## Repository Structure

- `supabase/migrations` - SQL migrations to apply in order
- `supabase/functions/yookassa-create-payment` — create payment (prod; secrets in Supabase only)
- `supabase/functions/yookassa-payment-status` — payment status by id
- `docs/supabase-yookassa-setup.md` — deploy secrets, CLI, `SILVA_PAYMENT_URLS` on the frontend
- `scripts/deploy-yookassa-functions.sh` — link + deploy ЮKassa Edge Functions (after `supabase login`)
- `.env.example` - required environment variables (template only)

## Security Principles

- Never commit secret keys (`service_role`, DB passwords, `.env.local`)
- Use RLS on all business tables
- Use helper function `public.is_admin()` for admin policies (prevents recursive policy checks)
- Keep write access minimal and role-based (`guest`, `owner`, `admin`)

## Initial Setup

1. Create a Supabase project.
2. Open SQL Editor in Supabase.
3. Apply migration files from `supabase/migrations` in chronological order.
4. Create Storage buckets:
   - `avatars` (public read)
   - `property-images` (public read)
5. Verify auth roles in `public.profiles` (`guest`, `owner`, `admin`).

## Frontend Integration

Frontend uses only:
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`

Do not expose any backend secrets to frontend runtime.

## Edge Functions (ЮKassa) — деплой с машины

CLI не может залогиниться без твоего участия. Один раз:

1. `npx supabase@latest login` (откроется браузер), **или** создай токен в [Account → Access Tokens](https://supabase.com/dashboard/account/tokens) и выполни `export SUPABASE_ACCESS_TOKEN=...`.
2. Из корня этого репозитория: `./scripts/deploy-yookassa-functions.sh`  
   (по умолчанию project ref `siqvswjrhmckufuaomhy`; переопределение: `SUPABASE_PROJECT_REF=...`).

В Dashboard проекта должны быть секреты `YOOKASSA_SHOP_ID` и `YOOKASSA_SECRET_KEY` (Edge Functions → Secrets).

## Deployment Notes

Use the same Supabase project for production frontend or a dedicated prod project.
Before production deploy:
- verify all RLS policies
- verify storage policies
- run smoke tests for guest/owner/admin flows
