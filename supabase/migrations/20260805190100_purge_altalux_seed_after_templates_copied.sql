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
-- ============================================================

delete from business_services where business_id = 'altalux';
delete from business_addons where business_id = 'altalux';
delete from business_settings where business_id = 'altalux';
