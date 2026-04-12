-- Характеристики объекта для каталога и страницы property (форма владельца).
-- После применения фронт читает/пишет bedrooms, bathrooms, area через Supabase.

begin;

alter table if exists public.properties
  add column if not exists bedrooms int not null default 1;

alter table if exists public.properties
  add column if not exists bathrooms int not null default 1;

alter table if exists public.properties
  add column if not exists area int not null default 50;

commit;
