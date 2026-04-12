-- Занятые ночи для календаря (anon + authenticated), без user_id и прочего PII.
-- Ночь d занята, если существует бронь с check_in <= d < check_out и статусом не cancelled.

create or replace function public.property_booked_date_ranges(p_property_id text)
returns table (check_in date, check_out date)
language sql
stable
security definer
set search_path = public
as $$
  select b.check_in, b.check_out
  from public.bookings b
  inner join public.properties p on p.id = b.property_id
  where p.status = 'published'
    and lower(trim(p_property_id)) <> ''
    and b.property_id::text = lower(trim(p_property_id))
    and b.status in ('pending', 'confirmed', 'completed');
$$;

revoke all on function public.property_booked_date_ranges(text) from public;
grant execute on function public.property_booked_date_ranges(text) to anon, authenticated;

-- Пересечение броней на одном объекте (RLS не мешает: триггер security definer).
create or replace function public.prevent_booking_overlap()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'cancelled'::public.booking_status then
    return new;
  end if;

  if exists (
    select 1
    from public.bookings o
    where o.property_id is not distinct from new.property_id
      and o.id is distinct from new.id
      and o.status in (
        'pending'::public.booking_status,
        'confirmed'::public.booking_status,
        'completed'::public.booking_status
      )
      and daterange(o.check_in, o.check_out, '[)') && daterange(new.check_in, new.check_out, '[)')
  ) then
    raise exception 'BOOKING_DATES_OVERLAP'
      using errcode = '23514',
        message = 'Эти даты уже заняты. Выберите другой период.';
  end if;

  return new;
end;
$$;

drop trigger if exists tr_bookings_overlap on public.bookings;
create trigger tr_bookings_overlap
before insert or update of check_in, check_out, status, property_id on public.bookings
for each row
execute function public.prevent_booking_overlap();
