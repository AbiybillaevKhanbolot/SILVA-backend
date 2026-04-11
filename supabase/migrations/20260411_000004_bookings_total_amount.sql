-- Дубль суммы к total_price (клиент при createBooking шлёт оба поля).
alter table public.bookings
  add column if not exists total_amount numeric(12,2) not null default 0;

update public.bookings
set total_amount = coalesce(total_price, total_amount, 0)
where total_price is not null;
