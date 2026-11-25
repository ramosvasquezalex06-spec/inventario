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
