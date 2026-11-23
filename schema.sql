-- Punto Audio · esquema de Supabase
-- Ejecutar completo en: Supabase → SQL Editor → New query → Run.
-- Es seguro volver a ejecutarlo (usa IF NOT EXISTS / OR REPLACE).

create table if not exists public.productos (
  id          uuid primary key,
  codigo      text        not null,
  categoria   text        not null default '',
  nombre      text,
  precio      numeric(12,2) not null check (precio >= 0),
  stock       integer     not null default 0,
  deleted     boolean     not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  synced_at   timestamptz not null default now()
);

create table if not exists public.ventas (
  id           uuid primary key,
  venta_id     uuid        not null,
  producto_id  uuid,
  codigo       text        not null,
  categoria    text        not null default '',
  cantidad     integer     not null check (cantidad > 0),
  precio       numeric(12,2) not null check (precio >= 0),
  costo        numeric(12,2) not null default 0,
  fecha        timestamptz not null,
  deleted      boolean     not null default false,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  synced_at    timestamptz not null default now()
);

-- La app descarga por synced_at (+ id): estos índices lo hacen rápido.
create index if not exists productos_synced_idx on public.productos (synced_at, id);
create index if not exists ventas_synced_idx    on public.ventas    (synced_at, id);
create index if not exists ventas_fecha_idx     on public.ventas    (fecha);
create index if not exists ventas_venta_idx     on public.ventas    (venta_id);

-- synced_at lo pone SIEMPRE el servidor (el celular no puede falsearlo).
-- Además: si llega un cambio más viejo que el que ya está guardado
-- (celular que estuvo mucho tiempo sin conexión), se ignora en silencio.
create or replace function public.pa_before_write() returns trigger
language plpgsql as $$
begin
  if tg_op = 'UPDATE' and new.updated_at < old.updated_at then
    return null;
  end if;
  new.synced_at := clock_timestamp();
  return new;
end $$;

drop trigger if exists productos_bw on public.productos;
create trigger productos_bw before insert or update on public.productos
  for each row execute function public.pa_before_write();

drop trigger if exists ventas_bw on public.ventas;
create trigger ventas_bw before insert or update on public.ventas
  for each row execute function public.pa_before_write();

-- Seguridad: solo usuarios con sesión iniciada. El rol anónimo no ve nada.
alter table public.productos enable row level security;
alter table public.ventas    enable row level security;

revoke all on public.productos, public.ventas from anon;
grant select, insert, update on public.productos, public.ventas to authenticated;

drop policy if exists productos_auth on public.productos;
create policy productos_auth on public.productos
  for all to authenticated using (true) with check (true);

drop policy if exists ventas_auth on public.ventas;
create policy ventas_auth on public.ventas
  for all to authenticated using (true) with check (true);

-- No se concede DELETE a propósito: la app borra con deleted = true.
