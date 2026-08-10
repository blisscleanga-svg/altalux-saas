-- ============================================================
-- Purge AltaLux's real business data after it served its purpose.
-- ============================================================
-- 20260713231400_phase_a_seed_altalux.sql seeds business_id='altalux'
-- into business_settings/business_services/business_addons purely so
-- 20260805190000_onboarding_system.sql has real content to copy into
-- service_templates/addon_templates (the generic platform catalog new
-- tenants get seeded from — it has no business_id column, so it's
-- unaffected by anything below). This clone's whole point is to have
-- no AltaLux tenant data in it, so once the copy is done, remove the
-- source rows. service_templates/addon_templates keep their 21+10
-- rows — those were already copied by the time this file runs.
--
-- 20260707121103_employees.sql separately seeds 2 real employees
-- (Luis Pabón, Dario Pabón — real emails/phone) directly on the
-- `employees` table, unconditionally, not gated by the phase_a seed
-- above. Purged here too. Safe only because `jobs` is guaranteed
-- empty at this point in a fresh clone (jobs.assigned_to references
-- employees(id) — deleting a referenced employee would fail if any
-- job pointed at one).
-- ============================================================

delete from business_services where business_id = 'altalux';
delete from business_addons where business_id = 'altalux';
delete from business_settings where business_id = 'altalux';
delete from employees where business_id = 'altalux';
