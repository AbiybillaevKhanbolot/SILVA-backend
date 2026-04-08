-- Align required columns for legacy frontend compatibility.
-- Safe to run multiple times.

begin;

alter table if exists public.properties
  add column if not exists reviews_count int not null default 0;

alter table if exists public.property_images
  add column if not exists position int not null default 0;

commit;
