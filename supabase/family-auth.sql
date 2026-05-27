create table if not exists public.families (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.family_memberships (
  family_id uuid not null references public.families(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member',
  created_at timestamptz not null default now(),
  primary key (family_id, user_id)
);

create table if not exists public.family_document_files (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  title text not null,
  description text,
  storage_path text not null unique,
  source_repository text not null,
  source_commit text,
  updated_at timestamptz not null default now()
);

create table if not exists public.family_destinations (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  name text not null,
  location text,
  starts_on date not null,
  ends_on date,
  notes text,
  created_at timestamptz not null default now(),
  check (ends_on is null or ends_on >= starts_on)
);

create table if not exists public.curriculum_units (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  destination_id uuid references public.family_destinations(id) on delete set null,
  title text not null,
  subject text,
  essential_question text,
  starts_on date,
  ends_on date,
  created_at timestamptz not null default now(),
  check (ends_on is null or starts_on is null or ends_on >= starts_on)
);

create table if not exists public.curriculum_activities (
  id uuid primary key default gen_random_uuid(),
  unit_id uuid not null references public.curriculum_units(id) on delete cascade,
  title text not null,
  activity_date date,
  description text,
  artifact_document_id uuid references public.family_document_files(id) on delete set null,
  created_at timestamptz not null default now()
);

alter table public.families enable row level security;
alter table public.family_memberships enable row level security;
alter table public.family_document_files enable row level security;
alter table public.family_destinations enable row level security;
alter table public.curriculum_units enable row level security;
alter table public.curriculum_activities enable row level security;

create policy "Members can read their families"
on public.families
for select
to authenticated
using (
  exists (
    select 1
    from public.family_memberships fm
    where fm.family_id = families.id
      and fm.user_id = auth.uid()
  )
);

create policy "Members can read their own memberships"
on public.family_memberships
for select
to authenticated
using (user_id = auth.uid());

create policy "Members can read family documents"
on public.family_document_files
for select
to authenticated
using (
  exists (
    select 1
    from public.family_memberships fm
    where fm.family_id = family_document_files.family_id
      and fm.user_id = auth.uid()
  )
);

create policy "Members can read family destinations"
on public.family_destinations
for select
to authenticated
using (
  exists (
    select 1
    from public.family_memberships fm
    where fm.family_id = family_destinations.family_id
      and fm.user_id = auth.uid()
  )
);

create policy "Members can read curriculum units"
on public.curriculum_units
for select
to authenticated
using (
  exists (
    select 1
    from public.family_memberships fm
    where fm.family_id = curriculum_units.family_id
      and fm.user_id = auth.uid()
  )
);

create policy "Members can read curriculum activities"
on public.curriculum_activities
for select
to authenticated
using (
  exists (
    select 1
    from public.curriculum_units cu
    join public.family_memberships fm on fm.family_id = cu.family_id
    where cu.id = curriculum_activities.unit_id
      and fm.user_id = auth.uid()
  )
);

insert into storage.buckets (id, name, public)
values ('family-documents', 'family-documents', false)
on conflict (id) do nothing;

create policy "Members can read family document objects"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'family-documents'
  and exists (
    select 1
    from public.family_memberships fm
    join public.families f on f.id = fm.family_id
    where fm.user_id = auth.uid()
      and f.slug = (storage.foldername(name))[1]
  )
);

create or replace function public.user_has_family_access(requested_family_slug text)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.family_memberships fm
    join public.families f on f.id = fm.family_id
    where f.slug = requested_family_slug
      and fm.user_id = auth.uid()
  );
$$;

grant execute on function public.user_has_family_access(text) to authenticated;

insert into public.families (slug, name)
values ('mcshan', 'McShan')
on conflict (slug) do update
set name = excluded.name;

create or replace view public.family_documents
with (security_invoker = true)
as
select
  d.id,
  f.slug as family_slug,
  d.title,
  d.description,
  d.storage_path,
  d.source_repository,
  d.source_commit,
  d.updated_at
from public.family_document_files d
join public.families f on f.id = d.family_id;

grant select on public.family_documents to authenticated;
grant select on public.family_document_files to authenticated;

create or replace view public.family_itinerary_curriculum
with (security_invoker = true)
as
select
  d.id as destination_id,
  f.slug as family_slug,
  d.name as destination_name,
  d.location,
  d.starts_on,
  d.ends_on,
  cu.id as curriculum_unit_id,
  cu.title as curriculum_title,
  cu.subject,
  count(ca.id)::integer as activity_count
from public.family_destinations d
join public.families f on f.id = d.family_id
left join public.curriculum_units cu on cu.destination_id = d.id
left join public.curriculum_activities ca on ca.unit_id = cu.id
group by d.id, f.slug, cu.id
order by d.starts_on, cu.starts_on nulls last, cu.title;

grant select on public.family_itinerary_curriculum to authenticated;
grant select on public.family_destinations to authenticated;
grant select on public.curriculum_units to authenticated;
grant select on public.curriculum_activities to authenticated;
