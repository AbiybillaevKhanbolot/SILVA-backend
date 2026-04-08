-- SILVA backend: storage buckets and policies

begin;

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('property-images', 'property-images', true)
on conflict (id) do nothing;

-- AVATARS: authenticated users can upload/update/delete only own folder.
-- Path convention: <user_id>/avatar.<ext>
drop policy if exists "avatars_public_read" on storage.objects;
create policy "avatars_public_read"
on storage.objects for select
using (bucket_id = 'avatars');

drop policy if exists "avatars_owner_insert" on storage.objects;
create policy "avatars_owner_insert"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'avatars'
  and split_part(name, '/', 1) = auth.uid()::text
);

drop policy if exists "avatars_owner_update" on storage.objects;
create policy "avatars_owner_update"
on storage.objects for update to authenticated
using (
  bucket_id = 'avatars'
  and split_part(name, '/', 1) = auth.uid()::text
)
with check (
  bucket_id = 'avatars'
  and split_part(name, '/', 1) = auth.uid()::text
);

drop policy if exists "avatars_owner_delete" on storage.objects;
create policy "avatars_owner_delete"
on storage.objects for delete to authenticated
using (
  bucket_id = 'avatars'
  and split_part(name, '/', 1) = auth.uid()::text
);

-- PROPERTY IMAGES: owners/admin can manage files in their own folder.
-- Path convention: <owner_id>/<property_id>/<filename>
drop policy if exists "property_images_public_read" on storage.objects;
create policy "property_images_public_read"
on storage.objects for select
using (bucket_id = 'property-images');

drop policy if exists "property_images_owner_insert" on storage.objects;
create policy "property_images_owner_insert"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'property-images'
  and (
    split_part(name, '/', 1) = auth.uid()::text
    or public.is_admin()
  )
);

drop policy if exists "property_images_owner_update" on storage.objects;
create policy "property_images_owner_update"
on storage.objects for update to authenticated
using (
  bucket_id = 'property-images'
  and (
    split_part(name, '/', 1) = auth.uid()::text
    or public.is_admin()
  )
)
with check (
  bucket_id = 'property-images'
  and (
    split_part(name, '/', 1) = auth.uid()::text
    or public.is_admin()
  )
);

drop policy if exists "property_images_owner_delete" on storage.objects;
create policy "property_images_owner_delete"
on storage.objects for delete to authenticated
using (
  bucket_id = 'property-images'
  and (
    split_part(name, '/', 1) = auth.uid()::text
    or public.is_admin()
  )
);

commit;
