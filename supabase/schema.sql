-- Run in Supabase SQL Editor. Review policies before production.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text,
 role text not null default 'user' check (role in ('user','admin')),
 created_at timestamptz not null default now()
);
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
 insert into public.profiles(id, display_name, role)
 values(new.id, coalesce(new.raw_user_meta_data->>'display_name',''), 'user')
 on conflict (id) do nothing;
 return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

create table if not exists public.movies (
 id uuid primary key default gen_random_uuid(),
 title text not null,
 release_year integer check (release_year is null or release_year between 1888 and 2100),
 genre text,
 poster_url text,
 synopsis text,
 video_url text,
 trailer_url text,
 cast_members text,
 duration_minutes integer check (duration_minutes is null or duration_minutes > 0),
 rating numeric(3,1) check (rating is null or rating between 0 and 10),
 featured boolean not null default false,
 published boolean not null default false,
 views_count bigint not null default 0,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists movies_published_created_idx on public.movies(published, created_at desc);
create index if not exists movies_views_idx on public.movies(views_count desc);
alter table public.profiles enable row level security;
alter table public.movies enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles for select to authenticated using (auth.uid() = id or exists(select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));
drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id and role = (select p.role from public.profiles p where p.id = auth.uid()));

drop policy if exists "movies_read_published" on public.movies;
create policy "movies_read_published" on public.movies for select to anon, authenticated using (published = true or exists(select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));
drop policy if exists "movies_admin_insert" on public.movies;
create policy "movies_admin_insert" on public.movies for insert to authenticated with check (exists(select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));
drop policy if exists "movies_admin_update" on public.movies;
create policy "movies_admin_update" on public.movies for update to authenticated using (exists(select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')) with check (exists(select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));
drop policy if exists "movies_admin_delete" on public.movies;
create policy "movies_admin_delete" on public.movies for delete to authenticated using (exists(select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));

create table if not exists public.watchlist (
 user_id uuid not null references auth.users(id) on delete cascade,
 movie_id uuid not null references public.movies(id) on delete cascade,
 created_at timestamptz not null default now(),
 primary key(user_id,movie_id)
);
alter table public.watchlist enable row level security;
drop policy if exists "watchlist_own_select" on public.watchlist;
create policy "watchlist_own_select" on public.watchlist for select to authenticated using (auth.uid() = user_id);
drop policy if exists "watchlist_own_insert" on public.watchlist;
create policy "watchlist_own_insert" on public.watchlist for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "watchlist_own_delete" on public.watchlist;
create policy "watchlist_own_delete" on public.watchlist for delete to authenticated using (auth.uid() = user_id);

create table if not exists public.watch_history (
 user_id uuid not null references auth.users(id) on delete cascade,
 movie_id uuid not null references public.movies(id) on delete cascade,
 watched_at timestamptz not null default now(),
 primary key(user_id,movie_id)
);
alter table public.watch_history enable row level security;
drop policy if exists "history_own_select" on public.watch_history;
create policy "history_own_select" on public.watch_history for select to authenticated using (auth.uid() = user_id);
drop policy if exists "history_own_insert" on public.watch_history;
create policy "history_own_insert" on public.watch_history for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "history_own_update" on public.watch_history;
create policy "history_own_update" on public.watch_history for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Admin setup: create your account using Supabase Auth, then run:
-- update public.profiles set role='admin' where id='YOUR_AUTH_USER_UUID';
-- Never expose service_role keys in browser/client code.
-- Video URLs should point only to content you own or are licensed to stream.
-- For serious production, use private storage/signed URLs or a video CDN with access controls.
