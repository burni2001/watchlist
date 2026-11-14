-- Einrichtung der Watchlist in Supabase (Listen + Einträge).
-- Im Supabase-Dashboard: SQL Editor → New query → alles einfügen → Run.
--
-- Vorher den gemeinsamen Benutzer anlegen: Authentication → Users → Add user
-- (E-Mail watchlist@example.com, eigenes Passwort, „Auto Confirm User“ an).
-- Dann unten die Benutzer-ID ersetzen:
--   select id from auth.users where email = 'watchlist@example.com';

create table if not exists public.lists (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(btrim(name)) between 1 and 80),
  emoji text not null default '🎬' check (char_length(emoji) between 1 and 16),
  position double precision not null default extract(epoch from now()),
  created_at timestamptz not null default now()
);

create table if not exists public.items (
  id uuid primary key default gen_random_uuid(),
  list_id uuid not null references public.lists(id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 200),
  year integer check (year between 1800 and 2200),
  note text check (char_length(note) <= 500),
  url text check (url ~ '^https?://' and char_length(url) <= 500),
  position double precision not null,
  seen boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists items_list_position_idx on public.items (list_id, position);

-- Zugriffsregeln: Nur der gemeinsame Benutzer darf lesen und schreiben.
-- Ohne Anmeldung (anon) gibt es keinen Zugriff.
alter table public.lists enable row level security;
alter table public.items enable row level security;

drop policy if exists "Bande darf Listen verwalten" on public.lists;
create policy "Bande darf Listen verwalten" on public.lists
  for all to authenticated
  using ((select auth.uid()) = '8749e434-6dd5-4324-a88a-a01b24f2eb64'::uuid)
  with check ((select auth.uid()) = '8749e434-6dd5-4324-a88a-a01b24f2eb64'::uuid);

drop policy if exists "Bande darf Eintraege verwalten" on public.items;
create policy "Bande darf Eintraege verwalten" on public.items
  for all to authenticated
  using ((select auth.uid()) = '8749e434-6dd5-4324-a88a-a01b24f2eb64'::uuid)
  with check ((select auth.uid()) = '8749e434-6dd5-4324-a88a-a01b24f2eb64'::uuid);

revoke all on public.lists, public.items from anon, authenticated;
grant select, insert, update, delete on public.lists, public.items to authenticated;

-- Live-Updates: Änderungen werden an alle offenen Seiten geschickt.
do $$
begin
  if not exists (select 1 from pg_publication_tables
                 where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'lists') then
    alter publication supabase_realtime add table public.lists;
  end if;
  if not exists (select 1 from pg_publication_tables
                 where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'items') then
    alter publication supabase_realtime add table public.items;
  end if;
end $$;
