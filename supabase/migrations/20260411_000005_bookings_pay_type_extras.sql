-- Поля, которые шлёт createBooking (совместимость с прод-схемами и приложением).
alter table public.bookings add column if not exists pay_type text not null default 'full';
alter table public.bookings add column if not exists adults int not null default 1;
alter table public.bookings add column if not exists nights int not null default 1;
alter table public.bookings add column if not exists yookassa_payment_id text;

-- Уже существующие колонки без DEFAULT: вставка из PostgREST без поля даёт NULL → ошибка.
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

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'bookings' and column_name = 'adults'
  ) then
    execute 'alter table public.bookings alter column adults set default 1';
  end if;
exception when others then null;
end $$;

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'bookings' and column_name = 'nights'
  ) then
    execute 'alter table public.bookings alter column nights set default 1';
  end if;
exception when others then null;
end $$;

-- Подтянуть ночи и взрослых для старых строк (если колонки только что добавились со значением по умолчанию).
update public.bookings
set nights = greatest(1, (check_out::date - check_in::date)::int)
where check_in is not null and check_out is not null;

update public.bookings
set adults = greatest(1, coalesce(guests, 1) - coalesce(children, 0))
where guests is not null;
