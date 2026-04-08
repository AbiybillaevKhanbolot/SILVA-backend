-- SILVA backend: initial schema + core RLS

begin;

-- Enums
do $$
begin
  if not exists (select 1 from pg_type where typname = 'user_role') then
    create type public.user_role as enum ('guest', 'owner', 'admin');
  end if;
end $$;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'owner_verification_status') then
    create type public.owner_verification_status as enum ('pending', 'verified', 'rejected');
  end if;
end $$;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'booking_status') then
    create type public.booking_status as enum ('pending', 'confirmed', 'completed', 'cancelled');
  end if;
end $$;

-- Helper function for admin checks.
-- SECURITY DEFINER is required to avoid recursive profile policies.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.role = 'admin'
  );
$$;

grant execute on function public.is_admin() to authenticated;

-- Profiles
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  email text not null unique,
  phone text,
  avatar_url text,
  role public.user_role not null default 'guest',
  owner_verification_status public.owner_verification_status not null default 'pending',
  newsletter boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Properties
create table if not exists public.properties (
  id bigint generated always as identity primary key,
  owner_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  address text,
  region text,
  property_type text,
  description text,
  price_per_night numeric(12,2) not null default 0,
  max_guests int not null default 1,
  status text not null default 'draft', -- draft | published
  rating numeric(3,2) not null default 0,
  reviews_count int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_properties_owner_id on public.properties(owner_id);
create index if not exists idx_properties_region on public.properties(region);
create index if not exists idx_properties_status on public.properties(status);

-- Property images
create table if not exists public.property_images (
  id bigint generated always as identity primary key,
  property_id bigint not null references public.properties(id) on delete cascade,
  image_url text not null,
  position int not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists idx_property_images_property_id on public.property_images(property_id);

-- Favorites
create table if not exists public.favorites (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  property_id bigint not null references public.properties(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, property_id)
);

create index if not exists idx_favorites_user_id on public.favorites(user_id);

-- Bookings
create table if not exists public.bookings (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  property_id bigint not null references public.properties(id) on delete cascade,
  check_in date not null,
  check_out date not null,
  guests int not null default 1,
  children int not null default 0,
  total_price numeric(12,2) not null default 0,
  status public.booking_status not null default 'pending',
  created_at timestamptz not null default now(),
  constraint bookings_dates_chk check (check_out > check_in)
);

create index if not exists idx_bookings_user_id on public.bookings(user_id);
create index if not exists idx_bookings_property_id on public.bookings(property_id);

-- Reviews
create table if not exists public.reviews (
  id bigint generated always as identity primary key,
  property_id bigint not null references public.properties(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  rating int not null check (rating between 1 and 5),
  text text,
  avatar_url text,
  created_at timestamptz not null default now()
);

create index if not exists idx_reviews_property_id on public.reviews(property_id);

-- Owner responses
create table if not exists public.review_responses (
  id bigint generated always as identity primary key,
  review_id bigint not null unique references public.reviews(id) on delete cascade,
  owner_id uuid not null references public.profiles(id) on delete cascade,
  text text not null,
  owner_avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Loyalty
create table if not exists public.loyalty_accounts (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  points int not null default 0,
  updated_at timestamptz not null default now()
);

create table if not exists public.loyalty_transactions (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  booking_id bigint references public.bookings(id) on delete set null,
  amount int not null,
  reason text,
  created_at timestamptz not null default now()
);

create index if not exists idx_loyalty_transactions_user_id on public.loyalty_transactions(user_id);

-- Feedback
create table if not exists public.feedback_messages (
  id bigint generated always as identity primary key,
  user_id uuid references public.profiles(id) on delete set null,
  name text not null,
  email text not null,
  message text not null,
  source text,
  page_path text,
  created_at timestamptz not null default now()
);

-- Auto-profile creation after signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  meta jsonb;
  v_full_name text;
  v_newsletter boolean;
  v_role public.user_role;
begin
  meta := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  v_full_name := nullif(trim(coalesce(meta->>'full_name', '')), '');
  v_newsletter := coalesce((meta->>'newsletter')::boolean, false);
  v_role := case
    when lower(coalesce(meta->>'role', 'guest')) = 'owner' then 'owner'::public.user_role
    when lower(coalesce(meta->>'role', 'guest')) = 'admin' then 'admin'::public.user_role
    else 'guest'::public.user_role
  end;

  insert into public.profiles (id, full_name, email, role, newsletter)
  values (new.id, v_full_name, coalesce(new.email, ''), v_role, v_newsletter)
  on conflict (id) do nothing;

  insert into public.loyalty_accounts (user_id, points)
  values (new.id, 0)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- Enable RLS
alter table public.profiles enable row level security;
alter table public.properties enable row level security;
alter table public.property_images enable row level security;
alter table public.favorites enable row level security;
alter table public.bookings enable row level security;
alter table public.reviews enable row level security;
alter table public.review_responses enable row level security;
alter table public.loyalty_accounts enable row level security;
alter table public.loyalty_transactions enable row level security;
alter table public.feedback_messages enable row level security;

-- Profiles policies
drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles for select to authenticated
using (id = auth.uid());

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles for update to authenticated
using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists "profiles_admin_read_all" on public.profiles;
create policy "profiles_admin_read_all"
on public.profiles for select to authenticated
using (public.is_admin());

-- Properties policies
drop policy if exists "properties_read_published" on public.properties;
create policy "properties_read_published"
on public.properties for select to authenticated
using (
  status = 'published'
  or owner_id = auth.uid()
  or public.is_admin()
);

drop policy if exists "properties_owner_insert" on public.properties;
create policy "properties_owner_insert"
on public.properties for insert to authenticated
with check (owner_id = auth.uid());

drop policy if exists "properties_owner_update" on public.properties;
create policy "properties_owner_update"
on public.properties for update to authenticated
using (owner_id = auth.uid() or public.is_admin())
with check (owner_id = auth.uid() or public.is_admin());

-- Property images policies
drop policy if exists "property_images_read" on public.property_images;
create policy "property_images_read"
on public.property_images for select to authenticated
using (true);

drop policy if exists "property_images_owner_write" on public.property_images;
create policy "property_images_owner_write"
on public.property_images for all to authenticated
using (
  exists (
    select 1 from public.properties p
    where p.id = property_id
      and (p.owner_id = auth.uid() or public.is_admin())
  )
)
with check (
  exists (
    select 1 from public.properties p
    where p.id = property_id
      and (p.owner_id = auth.uid() or public.is_admin())
  )
);

-- Favorites policies
drop policy if exists "favorites_own_all" on public.favorites;
create policy "favorites_own_all"
on public.favorites for all to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- Bookings policies
drop policy if exists "bookings_guest_own" on public.bookings;
create policy "bookings_guest_own"
on public.bookings for all to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "bookings_owner_read" on public.bookings;
create policy "bookings_owner_read"
on public.bookings for select to authenticated
using (
  exists (
    select 1 from public.properties p
    where p.id = property_id and p.owner_id = auth.uid()
  )
  or public.is_admin()
);

-- Reviews policies
drop policy if exists "reviews_read_authenticated" on public.reviews;
create policy "reviews_read_authenticated"
on public.reviews for select to authenticated
using (true);

drop policy if exists "reviews_insert_own" on public.reviews;
create policy "reviews_insert_own"
on public.reviews for insert to authenticated
with check (user_id = auth.uid());

drop policy if exists "reviews_update_own" on public.reviews;
create policy "reviews_update_own"
on public.reviews for update to authenticated
using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());

-- Review responses policies
drop policy if exists "review_responses_read_authenticated" on public.review_responses;
create policy "review_responses_read_authenticated"
on public.review_responses for select to authenticated
using (true);

drop policy if exists "review_responses_owner_write" on public.review_responses;
create policy "review_responses_owner_write"
on public.review_responses for all to authenticated
using (
  owner_id = auth.uid()
  or public.is_admin()
)
with check (
  owner_id = auth.uid()
  or public.is_admin()
);

-- Loyalty policies
drop policy if exists "loyalty_accounts_own_read" on public.loyalty_accounts;
create policy "loyalty_accounts_own_read"
on public.loyalty_accounts for select to authenticated
using (user_id = auth.uid() or public.is_admin());

drop policy if exists "loyalty_transactions_own_read" on public.loyalty_transactions;
create policy "loyalty_transactions_own_read"
on public.loyalty_transactions for select to authenticated
using (user_id = auth.uid() or public.is_admin());

-- Feedback policies
drop policy if exists "feedback_insert_any_auth" on public.feedback_messages;
create policy "feedback_insert_any_auth"
on public.feedback_messages for insert to authenticated
with check (user_id is null or user_id = auth.uid());

drop policy if exists "feedback_read_admin" on public.feedback_messages;
create policy "feedback_read_admin"
on public.feedback_messages for select to authenticated
using (public.is_admin());

commit;
