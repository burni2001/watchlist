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

-- Zugriffsregeln: Jeder Besucher darf lesen, abhaken und Häkchen entfernen,
-- aber nichts ändern und keine anderen Tabellen anfassen.
alter table public.seen_films enable row level security;

drop policy if exists "Alle duerfen lesen" on public.seen_films;
create policy "Alle duerfen lesen" on public.seen_films
  for select to anon, authenticated using (true);

drop policy if exists "Alle duerfen abhaken" on public.seen_films;
create policy "Alle duerfen abhaken" on public.seen_films
  for insert to anon, authenticated with check (true);

drop policy if exists "Alle duerfen Haken entfernen" on public.seen_films;
create policy "Alle duerfen Haken entfernen" on public.seen_films
  for delete to anon, authenticated using (true);

revoke all on public.seen_films from anon, authenticated;
grant select, insert, delete on public.seen_films to anon, authenticated;

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
