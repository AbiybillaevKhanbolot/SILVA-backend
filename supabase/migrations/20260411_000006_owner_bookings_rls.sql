-- Владелец видит профиль гостя, если есть бронь на его объект.
drop policy if exists "profiles_owner_sees_booking_guests" on public.profiles;
create policy "profiles_owner_sees_booking_guests"
on public.profiles for select to authenticated
using (
  exists (
    select 1
    from public.bookings b
    inner join public.properties p on p.id = b.property_id
    where p.owner_id = auth.uid()
      and b.user_id = profiles.id
  )
);

-- Владелец может менять статус брони по своим объектам.
drop policy if exists "bookings_owner_update" on public.bookings;
create policy "bookings_owner_update"
on public.bookings for update to authenticated
using (
  exists (
    select 1 from public.properties p
    where p.id = property_id and p.owner_id = auth.uid()
  )
  or public.is_admin()
)
with check (
  exists (
    select 1 from public.properties p
    where p.id = property_id and p.owner_id = auth.uid()
  )
  or public.is_admin()
);
