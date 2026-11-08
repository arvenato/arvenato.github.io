-- Arvenato Ön Muhasebe · Supabase veritabanı kurulumu
-- Supabase panelinde: SQL Editor > New query > bu dosyanın tamamını yapıştırın > Run

create extension if not exists pgcrypto;

create table if not exists public.firmalar (
  id uuid primary key default gen_random_uuid(),
  ad text not null,
  olusturma timestamptz not null default now()
);

create table if not exists public.firma_uyeleri (
  firma_id uuid not null references public.firmalar(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  rol text not null default 'uye' check (rol in ('sahip','uye')),
  eklenme timestamptz not null default now(),
  primary key (firma_id, user_id)
);

create table if not exists public.kayitlar (
  firma_id uuid not null references public.firmalar(id) on delete cascade,
  koleksiyon text not null,
  id text not null,
  veri jsonb not null default '{}'::jsonb,
  guncelleme timestamptz not null default now(),
  primary key (firma_id, koleksiyon, id)
);
create index if not exists kayitlar_firma_idx on public.kayitlar (firma_id);

-- Yetki yardımcıları
create or replace function public.uye_mi(f uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.firma_uyeleri where firma_id = f and user_id = auth.uid());
$$;
create or replace function public.sahip_mi(f uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.firma_uyeleri where firma_id = f and user_id = auth.uid() and rol = 'sahip');
$$;

-- Satır düzeyinde güvenlik: herkes yalnızca üyesi olduğu firmanın kayıtlarını görür
alter table public.firmalar enable row level security;
alter table public.firma_uyeleri enable row level security;
alter table public.kayitlar enable row level security;

drop policy if exists firmalar_oku on public.firmalar;
create policy firmalar_oku on public.firmalar for select to authenticated using (public.uye_mi(id));
drop policy if exists firmalar_guncelle on public.firmalar;
create policy firmalar_guncelle on public.firmalar for update to authenticated using (public.sahip_mi(id)) with check (public.sahip_mi(id));

drop policy if exists uyeler_oku on public.firma_uyeleri;
create policy uyeler_oku on public.firma_uyeleri for select to authenticated using (user_id = auth.uid() or public.uye_mi(firma_id));

drop policy if exists kayit_oku on public.kayitlar;
create policy kayit_oku on public.kayitlar for select to authenticated using (public.uye_mi(firma_id));
drop policy if exists kayit_ekle on public.kayitlar;
create policy kayit_ekle on public.kayitlar for insert to authenticated with check (public.uye_mi(firma_id));
drop policy if exists kayit_guncelle on public.kayitlar;
create policy kayit_guncelle on public.kayitlar for update to authenticated using (public.uye_mi(firma_id)) with check (public.uye_mi(firma_id));
drop policy if exists kayit_sil on public.kayitlar;
create policy kayit_sil on public.kayitlar for delete to authenticated using (public.uye_mi(firma_id));

-- Firma oluşturma (oluşturan kişi firmanın sahibi olur)
create or replace function public.firma_olustur(p_ad text) returns uuid
language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception 'Giriş yapmalısınız'; end if;
  insert into public.firmalar (ad) values (coalesce(nullif(trim(p_ad), ''), 'Firmam')) returning id into v_id;
  insert into public.firma_uyeleri (firma_id, user_id, rol) values (v_id, auth.uid(), 'sahip');
  insert into public.kayitlar (firma_id, koleksiyon, id, veri) values (v_id, 'ayar', 'firma', jsonb_build_object('ad', trim(p_ad)));
  return v_id;
end $$;

-- Kullanıcı yönetimi
create or replace function public.uyeleri_listele(p_firma uuid)
returns table (user_id uuid, eposta text, rol text)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.uye_mi(p_firma) then raise exception 'Yetkiniz yok'; end if;
  return query select u.user_id, au.email::text, u.rol from public.firma_uyeleri u join auth.users au on au.id = u.user_id where u.firma_id = p_firma order by u.eklenme;
end $$;

create or replace function public.uye_ekle(p_firma uuid, p_eposta text) returns text
language plpgsql security definer set search_path = public as $$
declare v_uid uuid;
begin
  if not public.sahip_mi(p_firma) then raise exception 'Kullanıcı eklemek için firma sahibi olmalısınız'; end if;
  select id into v_uid from auth.users where lower(email) = lower(trim(p_eposta)) limit 1;
  if v_uid is null then raise exception 'Bu e-postayla açılmış bir hesap yok. Kişi önce uygulamada "Hesap oluştur" ile kaydolmalı.'; end if;
  insert into public.firma_uyeleri (firma_id, user_id, rol) values (p_firma, v_uid, 'uye') on conflict do nothing;
  return 'ok';
end $$;

create or replace function public.uye_cikar(p_firma uuid, p_user uuid) returns text
language plpgsql security definer set search_path = public as $$
begin
  if not public.sahip_mi(p_firma) then raise exception 'Kullanıcı çıkarmak için firma sahibi olmalısınız'; end if;
  if p_user = auth.uid() then raise exception 'Kendinizi çıkaramazsınız'; end if;
  delete from public.firma_uyeleri where firma_id = p_firma and user_id = p_user;
  return 'ok';
end $$;

revoke all on function public.firma_olustur(text), public.uyeleri_listele(uuid), public.uye_ekle(uuid, text), public.uye_cikar(uuid, uuid) from public, anon;
grant execute on function public.firma_olustur(text), public.uyeleri_listele(uuid), public.uye_ekle(uuid, text), public.uye_cikar(uuid, uuid), public.uye_mi(uuid), public.sahip_mi(uuid) to authenticated;
grant select, insert, update, delete on public.kayitlar to authenticated;
grant select, update on public.firmalar to authenticated;
grant select on public.firma_uyeleri to authenticated;

-- Canlı eşitleme (bilgisayarda girilen kayıt telefonda anında görünür)
do $$ begin
  alter publication supabase_realtime add table public.kayitlar;
exception when duplicate_object then null; end $$;
