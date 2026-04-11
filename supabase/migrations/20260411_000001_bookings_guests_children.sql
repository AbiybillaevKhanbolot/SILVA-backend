-- Приложение (createBooking) пишет guests и children. Если прод-база старше init_schema, колонок может не быть.
alter table public.bookings
  add column if not exists guests int not null default 1;

alter table public.bookings
  add column if not exists children int not null default 0;
