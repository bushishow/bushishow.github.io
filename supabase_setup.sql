-- ============================================================
-- THE BUSHI SHOW · setup database admin
-- Da incollare in Supabase: Dashboard → SQL Editor → New query → Run
-- ============================================================

-- Spettacoli
create table if not exists bushi_shows (
  id bigint generated always as identity primary key,
  date date not null,
  title text not null,
  venue text default '',
  city text default '',
  url text default '',
  created_at timestamptz default now()
);

-- Video YouTube
create table if not exists bushi_videos (
  id bigint generated always as identity primary key,
  yt text not null,               -- link o ID YouTube
  title text not null,
  subtitle text default '',
  position int default 0,
  visible boolean default true,
  created_at timestamptz default now()
);

-- Foto (file nello Storage, bucket "foto")
create table if not exists bushi_photos (
  id bigint generated always as identity primary key,
  path text not null,             -- percorso nel bucket
  caption text default '',
  album text default 'duo',       -- nikolas | dashnor | duo
  position int default 0,
  created_at timestamptz default now()
);

-- Impostazioni (email, whatsapp, follower...)
create table if not exists bushi_settings (
  key text primary key,
  value text default ''
);

insert into bushi_settings (key, value) values
  ('booking_email',''),
  ('whatsapp',''),
  ('tiktok_followers','2600000'),
  ('youtube_subs','786000'),
  ('instagram_followers','109000')
on conflict (key) do nothing;

-- ---------- Sicurezza (RLS): tutti leggono, scrive SOLO l'account di Nikolas ----------
alter table bushi_shows enable row level security;
alter table bushi_videos enable row level security;
alter table bushi_photos enable row level security;
alter table bushi_settings enable row level security;

create policy "public read shows"    on bushi_shows    for select using (true);
create policy "public read videos"   on bushi_videos   for select using (true);
create policy "public read photos"   on bushi_photos   for select using (true);
create policy "public read settings" on bushi_settings for select using (true);

create policy "admin write shows"    on bushi_shows    for all to authenticated using ((auth.jwt()->>'email') = 'nikolasbushi.com@gmail.com') with check ((auth.jwt()->>'email') = 'nikolasbushi.com@gmail.com');
create policy "admin write videos"   on bushi_videos   for all to authenticated using ((auth.jwt()->>'email') = 'nikolasbushi.com@gmail.com') with check ((auth.jwt()->>'email') = 'nikolasbushi.com@gmail.com');
create policy "admin write photos"   on bushi_photos   for all to authenticated using ((auth.jwt()->>'email') = 'nikolasbushi.com@gmail.com') with check ((auth.jwt()->>'email') = 'nikolasbushi.com@gmail.com');
create policy "admin write settings" on bushi_settings for all to authenticated using ((auth.jwt()->>'email') = 'nikolasbushi.com@gmail.com') with check ((auth.jwt()->>'email') = 'nikolasbushi.com@gmail.com');

-- ---------- Storage: bucket pubblico per le foto ----------
insert into storage.buckets (id, name, public) values ('foto','foto', true)
on conflict (id) do nothing;

create policy "public read foto"  on storage.objects for select using (bucket_id = 'foto');
create policy "admin insert foto" on storage.objects for insert to authenticated with check (bucket_id = 'foto' and (auth.jwt()->>'email') = 'nikolasbushi.com@gmail.com');
create policy "admin update foto" on storage.objects for update to authenticated using (bucket_id = 'foto' and (auth.jwt()->>'email') = 'nikolasbushi.com@gmail.com');
create policy "admin delete foto" on storage.objects for delete to authenticated using (bucket_id = 'foto' and (auth.jwt()->>'email') = 'nikolasbushi.com@gmail.com');
