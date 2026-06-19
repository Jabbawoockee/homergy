-- ============================================================
-- GasTrack: Performance-Indizes
--
-- Alle CREATE INDEX sind idempotent (IF NOT EXISTS).
-- Reihenfolge: user-spezifische Tabellen → Benchmark-Tabelle
-- ============================================================

-- ------------------------------------------------------------
-- meter_readings
-- Primärfall: alle Ablesungen eines Users chronologisch abrufen
-- + Sync: WHERE user_id = $1 ORDER BY timestamp DESC
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_mr_user_timestamp
  ON meter_readings (user_id, timestamp DESC);

-- ------------------------------------------------------------
-- electricity_readings  (gleiche Zugriffsmuster wie meter_readings)
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_er_user_timestamp
  ON electricity_readings (user_id, timestamp DESC);

-- ------------------------------------------------------------
-- price_contracts
-- Suche nach aktivem Vertrag: user_id + größtes valid_from <= Datum
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_pc_user_valid_from
  ON price_contracts (user_id, valid_from DESC);

-- ------------------------------------------------------------
-- electricity_contracts  (gleiches Muster)
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_ec_user_valid_from
  ON electricity_contracts (user_id, valid_from DESC);

-- ------------------------------------------------------------
-- advance_payment_changes
-- Abfrage: aktiver Abschlag zu Datum für einen contract_type
-- WHERE user_id = $1 AND contract_type = $2 AND valid_from <= $3
-- ORDER BY valid_from DESC LIMIT 1
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_apc_user_contract_valid
  ON advance_payment_changes (user_id, contract_type, valid_from DESC);

-- ------------------------------------------------------------
-- consumption_benchmarks — Kern-Optimierung
--
-- Ohne Indizes: Full Table Scan bei JEDEM Benchmark-RPC-Aufruf.
-- Bei 10k Zeilen: ~5–50 ms. Bei 100k Zeilen: ~200–500 ms.
-- Mit Indizes: ~1–5 ms durch partiellen Index-Scan.
-- ------------------------------------------------------------

-- Gas-Benchmark: Haupt-Filterachsen (partiell auf Zeilen mit Gas-Daten)
-- Deckt die typischsten Filter ab: house_type + is_insulated +
-- has_solar_thermal + construction_year + square_meters
CREATE INDEX IF NOT EXISTS idx_cb_gas_filter
  ON consumption_benchmarks (house_type, is_insulated, has_solar_thermal, construction_year, square_meters)
  WHERE gas_kwh_monthly_avg IS NOT NULL;

-- Strom-Benchmark: Haupt-Filterachsen (partiell auf Zeilen mit Strom-Daten)
CREATE INDEX IF NOT EXISTS idx_cb_elec_filter
  ON consumption_benchmarks (number_of_persons, has_pv, square_meters, house_type)
  WHERE electricity_kwh_monthly_avg IS NOT NULL;

-- PLZ Prefix-Matching:
-- text_pattern_ops ermöglicht B-tree Prefix-Suche für LIKE 'XY%'.
-- KRITISCH: Ohne text_pattern_ops ignoriert PostgreSQL den Index bei LIKE!
-- Das Feld plz_prefix enthält die vollständige PLZ (5-stellig).
-- Der RPC filtert via plz_prefix LIKE p_plz_prefix || '%'
CREATE INDEX IF NOT EXISTS idx_cb_plz_prefix
  ON consumption_benchmarks USING btree (plz_prefix text_pattern_ops)
  WHERE gas_kwh_monthly_avg IS NOT NULL;

-- HINWEIS: user_id in consumption_benchmarks ist UNIQUE,
-- dadurch existiert bereits ein impliziter Index für den user_val-Lookup.
-- Kein zusätzlicher Index erforderlich.
