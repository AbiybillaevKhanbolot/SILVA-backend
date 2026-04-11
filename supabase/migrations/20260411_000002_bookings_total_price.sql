-- createBooking передаёт total_price (руб.). Если колонки нет в проде — добавить.
alter table public.bookings
  add column if not exists total_price numeric(12,2) not null default 0;
