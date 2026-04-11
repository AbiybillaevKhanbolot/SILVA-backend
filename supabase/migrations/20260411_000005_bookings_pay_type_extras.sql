-- Соответствует insert в public/legacy/js/supabase-client.js (createBooking): pay_type обязателен на проде.
alter table public.bookings add column if not exists pay_type text not null default 'full';

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'bookings' and column_name = 'pay_type'
  ) then
    execute 'alter table public.bookings alter column pay_type set default ''full''';
  end if;
exception when others then null;
end $$;
