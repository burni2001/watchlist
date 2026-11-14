-- Einrichtung der gemeinsamen Godzilla-Abhakliste in Supabase.
-- Im Supabase-Dashboard: SQL Editor → New query → alles einfügen → Run.

-- Eine Zeile pro abgehaktem Film. Nur die 20 Filme der Liste sind erlaubt,
-- damit niemand die Tabelle mit beliebigen Daten füllen kann.
create table if not exists public.seen_films (
  film_id text primary key check (film_id in (
    'tt0047034', 'tt23289160', 'tt4262980', 'tt0113187', 'tt0279112',
    'tt0058379', 'tt0097444', 'tt0058544', 'tt0067148', 'tt0831387',
    'tt0071565', 'tt0063172', 'tt3741700', 'tt34384661', 'tt9015178',
    'tt0101962', 'tt5034838', 'tt0399102', 'tt13364334', 'tt0188640'
  )),
  seen_at timestamptz not null default now()
);

-- Zugriffsregeln: Nur der gemeinsame Benutzer watchlist@example.com darf lesen,
-- abhaken und Häkchen entfernen. Ohne Anmeldung (anon) gibt es keinen Zugriff.
-- Vorher im Dashboard anlegen: Authentication → Users → Add user (Auto Confirm),
-- dann unten die ID ersetzen: select id from auth.users where email = 'watchlist@example.com';
alter table public.seen_films enable row level security;

drop policy if exists "Bande darf lesen" on public.seen_films;
create policy "Bande darf lesen" on public.seen_films
  for select to authenticated using ((select auth.uid()) = '8749e434-6dd5-4324-a88a-a01b24f2eb64'::uuid);

drop policy if exists "Bande darf abhaken" on public.seen_films;
create policy "Bande darf abhaken" on public.seen_films
  for insert to authenticated with check ((select auth.uid()) = '8749e434-6dd5-4324-a88a-a01b24f2eb64'::uuid);

drop policy if exists "Bande darf Haken entfernen" on public.seen_films;
create policy "Bande darf Haken entfernen" on public.seen_films
  for delete to authenticated using ((select auth.uid()) = '8749e434-6dd5-4324-a88a-a01b24f2eb64'::uuid);

revoke all on public.seen_films from anon, authenticated;
grant select, insert, delete on public.seen_films to authenticated;

-- Live-Updates: Änderungen an der Tabelle werden an alle offenen Seiten geschickt.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'seen_films'
  ) then
    alter publication supabase_realtime add table public.seen_films;
  end if;
end $$;
