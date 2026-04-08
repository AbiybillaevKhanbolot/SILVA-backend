-- Add missing rating column expected by frontend.
-- Safe to run multiple times.

begin;

alter table if exists public.properties
  add column if not exists rating numeric(3,2) not null default 0;

commit;
