-- ============================================================
-- Baseline core tables — reconstructed from the live production
-- schema (project xmhsehfdmiqbwhpqjgon), 2026-08-09.
-- ============================================================
-- These 8 tables (bookings, customers, jobs, payments, invoices,
-- vehicles, job_addons, job_vehicles) were created directly via the
-- Supabase SQL Editor when this project started, before any migration
-- file existed. No migration in this repo creates them — every
-- existing migration only ALTERs them, assuming they're already
-- there. supabase db push against a fresh project therefore leaves
-- the schema fatally incomplete without this file.
--
-- Reconstructed by introspecting the live project's
-- information_schema/pg_catalog (pg_dump was not usable — this
-- sandbox has no Docker, which `supabase db dump` requires).
--
-- Deliberately excludes every column/constraint/policy that a LATER
-- migration in this repo already adds via `ADD COLUMN IF NOT EXISTS`
-- (idempotent, so it doesn't matter either way) — except two cases
-- that are NOT idempotent and would break if duplicated here:
--   1. `jobs_job_number_unique` (UNIQUE constraint) — added by
--      20260718150000_fix_duplicate_job_number.sql via a bare
--      `ADD CONSTRAINT`, which has no IF NOT EXISTS form. Included
--      here would make that migration fail with "already exists".
--   2. `jobs.assigned_to` (-> employees) and `jobs.service_id` /
--      `invoices.service_id` (-> business_services) carry inline
--      `REFERENCES` on the migrations that add them
--      (20260707121103_employees.sql, 20260714214443_phase_b_invoicing.sql)
--      — if pre-created here without the FK, the later
--      `ADD COLUMN IF NOT EXISTS` would no-op and the FK would
--      silently never get added. Left out of this file entirely so
--      those later migrations create both the column and its FK
--      together, as originally written. (Every OTHER column those
--      same migrations add — `start_time`/`end_time` on `jobs`,
--      `original_service_name`/`original_amount`/etc. on `invoices`
--      — is a plain column with no FK; excluded from here for the
--      same idempotent-ADD-COLUMN reason as everything else, not
--      because it carries a reference.)
--
-- This file is NOT idempotent (plain `create table`/`create policy`,
-- no `if not exists`) — unlike every other migration in this repo.
-- Re-running `db push` against a database that already has these
-- tables will fail. If a from-scratch retry is ever needed, wipe the
-- whole public schema first (see the plan's Task 4 for the exact
-- commands) rather than trying to re-run just this file.
-- ============================================================

-- ============================================================
-- customers (no FK dependencies on the other 7 tables)
-- ============================================================
create table customers (
  id uuid primary key default gen_random_uuid(),
  created_at timestamp with time zone default now(),
  full_name text not null,
  phone text,
  email text,
  address text,
  billing_address text,
  source text,
  notes text,
  receive_reminders boolean default true,
  receive_offers boolean default true
);

alter table customers enable row level security;

-- ============================================================
-- vehicles (-> customers)
-- ============================================================
create table vehicles (
  id uuid primary key default gen_random_uuid(),
  created_at timestamp with time zone default now(),
  customer_id uuid references customers(id) on delete cascade,
  year text,
  make text,
  model text,
  color text,
  license_plate text,
  vehicle_type text,
  notes text,
  is_default boolean default false
);

alter table vehicles enable row level security;

-- ============================================================
-- jobs (-> customers)
-- ============================================================
create table jobs (
  id uuid primary key default gen_random_uuid(),
  created_at timestamp with time zone default now(),
  job_number serial not null,
  customer_id uuid references customers(id),
  category text,
  package text,
  service_date date,
  service_time text,
  status text default 'Pending',
  subtotal numeric,
  addons_total numeric,
  total numeric,
  deposit numeric,
  balance_due numeric,
  payment_status text default 'Unpaid',
  notes text
);

alter table jobs enable row level security;

-- ============================================================
-- bookings (no FK to the other 7 tables)
-- ============================================================
create table bookings (
  id uuid primary key default gen_random_uuid(),
  created_at timestamp with time zone default now(),
  full_name text,
  phone text,
  email text,
  address text,
  vehicle text,
  category text,
  package text,
  vehicle_type text,
  service_date date,
  service_time text,
  subtotal numeric,
  addons_total numeric,
  total numeric,
  deposit numeric,
  addons jsonb,
  receive_reminders boolean,
  receive_offers boolean,
  stripe_session_id text,
  status text default 'Pending'
);

alter table bookings enable row level security;

-- The public booking widget (booking/index.html) only ever INSERTs
-- into this table, never SELECTs — this is the only RLS policy this
-- table needs pre-migration, and the only one this repo's migrations
-- never (re)create because it was never dropped/replaced, only ever
-- added-to (see e2e_fixes_2026_07_10.sql, security_rls_audit_part2.sql
-- for the `authenticated` side).
create policy "Allow public insert on bookings" on public.bookings
  for insert to anon with check (true);

-- ============================================================
-- payments (-> customers, jobs)
-- ============================================================
create table payments (
  id uuid primary key default gen_random_uuid(),
  created_at timestamp with time zone default now(),
  job_id uuid references jobs(id),
  customer_id uuid references customers(id),
  amount numeric,
  payment_method text,
  payment_type text,
  reference_number text,
  notes text,
  payment_date date default current_date
);

alter table payments enable row level security;

-- ============================================================
-- invoices (-> customers, jobs)
-- ============================================================
create table invoices (
  id uuid primary key default gen_random_uuid(),
  created_at timestamp with time zone default now(),
  invoice_number serial not null,
  job_id uuid references jobs(id),
  customer_id uuid references customers(id),
  status text default 'Draft',
  due_date date,
  tax_enabled boolean default false,
  tax_rate numeric default 6,
  notes text,
  sent_at timestamp with time zone
);

alter table invoices enable row level security;

-- ============================================================
-- job_addons (-> jobs)
-- ============================================================
create table job_addons (
  id uuid primary key default gen_random_uuid(),
  job_id uuid references jobs(id) on delete cascade,
  name text,
  price numeric
);

alter table job_addons enable row level security;

-- ============================================================
-- job_vehicles (-> jobs, vehicles)
-- ============================================================
create table job_vehicles (
  id uuid primary key default gen_random_uuid(),
  job_id uuid references jobs(id) on delete cascade,
  vehicle_id uuid references vehicles(id),
  vehicle_type text,
  service text,
  package text,
  price numeric
);

alter table job_vehicles enable row level security;
