-- Esquema completo v18 para instalaciones nuevas.
-- Para el proyecto existente usa ACTUALIZAR_SUPABASE.sql.

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


-- Punto Audio v18: ejecutar UNA VEZ en el SQL Editor del proyecto actual.
-- Puede repetirse. No borra ni reemplaza productos, ventas o usuarios.
-- Primero ejecuta este archivo y después publica la nueva app.
begin;

alter table public.productos
  add column if not exists precio_venta numeric(12,2),
  add column if not exists stock_minimo integer not null default 3;
alter table public.ventas
  add column if not exists total numeric(14,2),
  add column if not exists nombre text;

do $$ begin
 if not exists (select 1 from pg_constraint where conname='pa_precio_venta_valido' and conrelid='public.productos'::regclass) then
  alter table public.productos add constraint pa_precio_venta_valido check (precio_venta is null or (precio_venta >= 0 and precio_venta <> 'NaN'::numeric));
 end if;
 if not exists (select 1 from pg_constraint where conname='pa_stock_minimo_valido' and conrelid='public.productos'::regclass) then
  alter table public.productos add constraint pa_stock_minimo_valido check (stock_minimo >= 0);
 end if;
 if not exists (select 1 from pg_constraint where conname='pa_venta_total_valido' and conrelid='public.ventas'::regclass) then
  alter table public.ventas add constraint pa_venta_total_valido check (total is null or (total >= 0 and total <> 'NaN'::numeric));
 end if;
end $$;

create table if not exists public.movimientos (
 id uuid primary key,
 producto_id uuid,
 codigo text not null,
 nombre text,
 categoria text not null default '',
 tipo text not null,
 cantidad integer not null,
 stock_antes integer not null,
 stock_despues integer not null,
 referencia uuid,
 nota text not null default '',
 usuario_id uuid,
 fecha timestamptz not null,
 created_at timestamptz not null default now(),
 synced_at timestamptz not null default now()
);
create index if not exists movimientos_synced_idx on public.movimientos(synced_at,id);
create index if not exists movimientos_producto_fecha_idx on public.movimientos(producto_id,fecha);

create or replace function public.pa_movimiento_insert() returns trigger
language plpgsql set search_path = public, pg_temp as $$
begin
 new.synced_at := clock_timestamp();
 -- Identidad de quien registra en la nube. El evento sigue conservando su fecha local.
 new.usuario_id := auth.uid();
 return new;
end $$;
drop trigger if exists movimientos_bi on public.movimientos;
create trigger movimientos_bi before insert on public.movimientos
 for each row execute function public.pa_movimiento_insert();

alter table public.movimientos enable row level security;
revoke all on public.movimientos from anon;
revoke update, delete, truncate on public.movimientos from authenticated;
grant select, insert on public.movimientos to authenticated;
drop policy if exists movimientos_lectura on public.movimientos;
create policy movimientos_lectura on public.movimientos for select to authenticated using (true);
drop policy if exists movimientos_registro on public.movimientos;
create policy movimientos_registro on public.movimientos for insert to authenticated with check (usuario_id = auth.uid());

-- Mantiene el modelo de acceso de la tienda actual: usuarios autenticados.
-- Los movimientos son de solo anexado para la app (sin editar ni borrar).
notify pgrst, 'reload schema';
commit;
