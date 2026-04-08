# Migrations Guide

## Apply Order

Run SQL files in `supabase/migrations` by filename order:

1. `20260408_000001_init_schema.sql`
2. `20260408_000002_storage_policies.sql`

## Notes

- Execute as project owner in Supabase SQL Editor.
- If you re-run migrations, use idempotent scripts only.
- Verify created tables, enums, and policies after each step.
