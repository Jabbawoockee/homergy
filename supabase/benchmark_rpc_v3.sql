-- ============================================================
-- GasTrack: Benchmark RPCs v3 — Performance-Optimierungen
--
-- Probleme in v2:
--   1. LEFT(plz_prefix, LENGTH(p_plz_prefix)) = p_plz_prefix
--      → nicht index-sargable, erzwingt Full Table Scan trotz Index
--   2. Zwei getrennte Queries in plpgsql (user_val-Lookup + Aggregation)
--   3. LANGUAGE plpgsql: Planer kann Funktion nicht inline-en
--   4. Kein SET search_path (Security-Lücke bei SECURITY DEFINER)
--
-- Lösungen in v3:
--   1. plz_prefix LIKE p_plz_prefix || '%' → B-tree via text_pattern_ops
--   2. Scalar Subquery für user_val (idx auf UNIQUE user_id: O(1))
--   3. LANGUAGE sql STABLE → Planer kann besser optimieren / inlinen
--   4. SET search_path = public
--
-- Skalierbarkeit:
--   10k User:   Benchmark-RPC ~1–5 ms (mit Indizes)
--   100k User:  Benchmark-RPC ~5–20 ms (mit Indizes)
--   500k+ User: Materialized View mit stündlichem REFRESH empfohlen
--               (siehe Kommentar am Ende dieser Datei)
-- ============================================================

-- Alte Signaturen entfernen (Signaturwechsel erfordert DROP)
DROP FUNCTION IF EXISTS get_gas_benchmark(UUID, TEXT[], INT, INT, BOOLEAN, INT, INT, BOOLEAN, TEXT);
DROP FUNCTION IF EXISTS get_electricity_benchmark(UUID, INT, BOOLEAN, INT, INT, TEXT[]);

-- ============================================================
-- RPC: Gas-Vergleich (v3)
-- ============================================================
CREATE OR REPLACE FUNCTION get_gas_benchmark(
  p_user_id                 UUID,
  p_house_types             TEXT[]  DEFAULT NULL,
  p_sqm_min                 INT     DEFAULT NULL,
  p_sqm_max                 INT     DEFAULT NULL,
  p_has_solar_thermal       BOOLEAN DEFAULT NULL,
  p_construction_year_min   INT     DEFAULT NULL,
  p_construction_year_max   INT     DEFAULT NULL,
  p_is_insulated            BOOLEAN DEFAULT NULL,
  p_plz_prefix              TEXT    DEFAULT NULL
)
RETURNS JSON
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT json_build_object(
    'min_val',    MIN(gas_kwh_monthly_avg),
    'max_val',    MAX(gas_kwh_monthly_avg),
    'avg_val',    AVG(gas_kwh_monthly_avg),
    'median_val', PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gas_kwh_monthly_avg),
    'count_val',  COUNT(*),
    -- Scalar Subquery: O(1) via UNIQUE-Index auf user_id
    'user_val',   (
      SELECT gas_kwh_monthly_avg
      FROM consumption_benchmarks
      WHERE user_id = p_user_id
    ),
    'user_percentile',
      CASE WHEN (
        SELECT gas_kwh_monthly_avg FROM consumption_benchmarks WHERE user_id = p_user_id
      ) IS NOT NULL THEN
        ROUND(
          COUNT(*) FILTER (
            WHERE gas_kwh_monthly_avg > (
              SELECT gas_kwh_monthly_avg FROM consumption_benchmarks WHERE user_id = p_user_id
            )
          )::NUMERIC
          / GREATEST(COUNT(*), 1) * 100
        )
      ELSE NULL END
  )
  FROM consumption_benchmarks
  WHERE gas_kwh_monthly_avg IS NOT NULL
    AND (p_house_types           IS NULL OR house_type        = ANY(p_house_types))
    AND (p_sqm_min               IS NULL OR square_meters     >= p_sqm_min)
    AND (p_sqm_max               IS NULL OR square_meters     <= p_sqm_max)
    AND (p_has_solar_thermal     IS NULL OR has_solar_thermal  = p_has_solar_thermal)
    AND (p_construction_year_min IS NULL OR construction_year >= p_construction_year_min)
    AND (p_construction_year_max IS NULL OR construction_year <= p_construction_year_max)
    AND (p_is_insulated          IS NULL OR is_insulated       = p_is_insulated)
    -- LIKE statt LEFT(): nutzt B-tree-Index mit text_pattern_ops
    AND (p_plz_prefix            IS NULL OR plz_prefix LIKE p_plz_prefix || '%');
$$;

-- ============================================================
-- RPC: Strom-Vergleich (v3)
-- ============================================================
CREATE OR REPLACE FUNCTION get_electricity_benchmark(
  p_user_id           UUID,
  p_number_of_persons INT     DEFAULT NULL,
  p_has_pv            BOOLEAN DEFAULT NULL,
  p_sqm_min           INT     DEFAULT NULL,
  p_sqm_max           INT     DEFAULT NULL,
  p_house_types       TEXT[]  DEFAULT NULL
)
RETURNS JSON
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT json_build_object(
    'min_val',    MIN(electricity_kwh_monthly_avg),
    'max_val',    MAX(electricity_kwh_monthly_avg),
    'avg_val',    AVG(electricity_kwh_monthly_avg),
    'median_val', PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY electricity_kwh_monthly_avg),
    'count_val',  COUNT(*),
    'user_val',   (
      SELECT electricity_kwh_monthly_avg
      FROM consumption_benchmarks
      WHERE user_id = p_user_id
    ),
    'user_percentile',
      CASE WHEN (
        SELECT electricity_kwh_monthly_avg FROM consumption_benchmarks WHERE user_id = p_user_id
      ) IS NOT NULL THEN
        ROUND(
          COUNT(*) FILTER (
            WHERE electricity_kwh_monthly_avg > (
              SELECT electricity_kwh_monthly_avg FROM consumption_benchmarks WHERE user_id = p_user_id
            )
          )::NUMERIC
          / GREATEST(COUNT(*), 1) * 100
        )
      ELSE NULL END
  )
  FROM consumption_benchmarks
  WHERE electricity_kwh_monthly_avg IS NOT NULL
    AND (p_number_of_persons IS NULL OR number_of_persons = p_number_of_persons)
    AND (p_has_pv            IS NULL OR has_pv            = p_has_pv)
    AND (p_sqm_min           IS NULL OR square_meters     >= p_sqm_min)
    AND (p_sqm_max           IS NULL OR square_meters     <= p_sqm_max)
    AND (p_house_types       IS NULL OR house_type        = ANY(p_house_types));
$$;

-- ============================================================
-- OPTIONAL: Materialized View für 500k+ User
--
-- Bei sehr großem Datensatz wird PERCENTILE_CONT zum Flaschenhals
-- (O(n log n) Sort). Eine stündlich aktualisierte Materialized View
-- reduziert die RPC-Latenz auf <1 ms:
--
-- CREATE MATERIALIZED VIEW benchmark_gas_hourly AS
-- SELECT
--   house_type,
--   is_insulated,
--   has_solar_thermal,
--   LEFT(plz_prefix, 2)                AS plz2,
--   ((square_meters / 20) * 20)        AS sqm_band,   -- 20-qm-Bucket
--   ((construction_year / 10) * 10)    AS decade,     -- Dekaden-Bucket
--   MIN(gas_kwh_monthly_avg)           AS min_val,
--   MAX(gas_kwh_monthly_avg)           AS max_val,
--   AVG(gas_kwh_monthly_avg)           AS avg_val,
--   PERCENTILE_CONT(0.5) WITHIN GROUP
--     (ORDER BY gas_kwh_monthly_avg)   AS median_val,
--   COUNT(*)                           AS count_val
-- FROM consumption_benchmarks
-- WHERE gas_kwh_monthly_avg IS NOT NULL
-- GROUP BY house_type, is_insulated, has_solar_thermal, plz2, sqm_band, decade
-- WITH DATA;
--
-- REFRESH MATERIALIZED VIEW CONCURRENTLY benchmark_gas_hourly;
-- (via pg_cron: SELECT cron.schedule('0 * * * *', 'REFRESH MATERIALIZED VIEW CONCURRENTLY benchmark_gas_hourly'))
--
-- Die RPCs müssten dann die MV abfragen und sqm_min/max auf Bänder
-- mappen — Approximierung, aber bei 500k+ User akzeptabel.
-- ============================================================
