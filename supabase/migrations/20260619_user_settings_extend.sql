-- ============================================================
-- GasTrack: user_settings — fehlende Spalten
--
-- Die initiale Migration (20260525_user_settings.sql) enthält
-- nur Standort-Felder. Der sync_service.dart schreibt aber
-- alle Hausdaten und Einstellungen. ALTER IF NOT EXISTS ist
-- idempotent und sicher mehrfach ausführbar.
-- ============================================================

ALTER TABLE user_settings
  ADD COLUMN IF NOT EXISTS meter_int_digits       INT,
  ADD COLUMN IF NOT EXISTS electricity_int_digits INT,
  ADD COLUMN IF NOT EXISTS electricity_dec_digits INT,
  ADD COLUMN IF NOT EXISTS house_type             TEXT,
  ADD COLUMN IF NOT EXISTS square_meters          INT,
  ADD COLUMN IF NOT EXISTS number_of_persons      INT,
  ADD COLUMN IF NOT EXISTS has_pv                 BOOLEAN,
  ADD COLUMN IF NOT EXISTS has_solar_thermal      BOOLEAN,
  ADD COLUMN IF NOT EXISTS construction_year      INT,
  ADD COLUMN IF NOT EXISTS is_insulated           BOOLEAN,
  ADD COLUMN IF NOT EXISTS tracking_mode          TEXT;
