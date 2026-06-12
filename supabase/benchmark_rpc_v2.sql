-- ============================================================
-- GasTrack: RPCs v2 — Haustyp als TEXT[] für Mehrfachauswahl
-- Im Supabase SQL-Editor ausführen
-- ============================================================

-- Alte Funktionen entfernen (Signatur hat sich geändert)
DROP FUNCTION IF EXISTS get_gas_benchmark(UUID, TEXT, INT, INT, BOOLEAN, INT, INT, BOOLEAN, TEXT);
DROP FUNCTION IF EXISTS get_electricity_benchmark(UUID, INT, BOOLEAN, INT, INT, TEXT);

-- ============================================================
-- RPC: Gas-Vergleich (v2)
-- ============================================================
CREATE OR REPLACE FUNCTION get_gas_benchmark(
  p_user_id                 UUID,
  p_house_types             TEXT[]  DEFAULT NULL,   -- Mehrfachauswahl, NULL = kein Filter
  p_sqm_min                 INT     DEFAULT NULL,
  p_sqm_max                 INT     DEFAULT NULL,
  p_has_solar_thermal       BOOLEAN DEFAULT NULL,
  p_construction_year_min   INT     DEFAULT NULL,
  p_construction_year_max   INT     DEFAULT NULL,
  p_is_insulated            BOOLEAN DEFAULT NULL,
  p_plz_prefix              TEXT    DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_user_val DOUBLE PRECISION;
  v_result   JSON;
BEGIN
  SELECT gas_kwh_monthly_avg INTO v_user_val
  FROM consumption_benchmarks WHERE user_id = p_user_id;

  SELECT json_build_object(
    'min_val',        MIN(gas_kwh_monthly_avg),
    'max_val',        MAX(gas_kwh_monthly_avg),
    'avg_val',        AVG(gas_kwh_monthly_avg),
    'median_val',     PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gas_kwh_monthly_avg),
    'count_val',      COUNT(*),
    'user_val',       v_user_val,
    'user_percentile',
      CASE WHEN v_user_val IS NOT NULL THEN
        ROUND(
          COUNT(*) FILTER (WHERE gas_kwh_monthly_avg > v_user_val)::NUMERIC
          / GREATEST(COUNT(*), 1) * 100
        )
      ELSE NULL END
  ) INTO v_result
  FROM consumption_benchmarks
  WHERE gas_kwh_monthly_avg IS NOT NULL
    AND (p_house_types            IS NULL OR house_type             = ANY(p_house_types))
    AND (p_sqm_min                IS NULL OR square_meters          >= p_sqm_min)
    AND (p_sqm_max                IS NULL OR square_meters          <= p_sqm_max)
    AND (p_has_solar_thermal      IS NULL OR has_solar_thermal      =  p_has_solar_thermal)
    AND (p_construction_year_min  IS NULL OR construction_year      >= p_construction_year_min)
    AND (p_construction_year_max  IS NULL OR construction_year      <= p_construction_year_max)
    AND (p_is_insulated           IS NULL OR is_insulated           =  p_is_insulated)
    AND (p_plz_prefix             IS NULL OR plz_prefix             =  p_plz_prefix);

  RETURN v_result;
END;
$$;

-- ============================================================
-- RPC: Strom-Vergleich (v2)
-- ============================================================
CREATE OR REPLACE FUNCTION get_electricity_benchmark(
  p_user_id           UUID,
  p_number_of_persons INT     DEFAULT NULL,
  p_has_pv            BOOLEAN DEFAULT NULL,
  p_sqm_min           INT     DEFAULT NULL,
  p_sqm_max           INT     DEFAULT NULL,
  p_house_types       TEXT[]  DEFAULT NULL    -- Mehrfachauswahl, NULL = kein Filter
)
RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_user_val DOUBLE PRECISION;
  v_result   JSON;
BEGIN
  SELECT electricity_kwh_monthly_avg INTO v_user_val
  FROM consumption_benchmarks WHERE user_id = p_user_id;

  SELECT json_build_object(
    'min_val',        MIN(electricity_kwh_monthly_avg),
    'max_val',        MAX(electricity_kwh_monthly_avg),
    'avg_val',        AVG(electricity_kwh_monthly_avg),
    'median_val',     PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY electricity_kwh_monthly_avg),
    'count_val',      COUNT(*),
    'user_val',       v_user_val,
    'user_percentile',
      CASE WHEN v_user_val IS NOT NULL THEN
        ROUND(
          COUNT(*) FILTER (WHERE electricity_kwh_monthly_avg > v_user_val)::NUMERIC
          / GREATEST(COUNT(*), 1) * 100
        )
      ELSE NULL END
  ) INTO v_result
  FROM consumption_benchmarks
  WHERE electricity_kwh_monthly_avg IS NOT NULL
    AND (p_number_of_persons IS NULL OR number_of_persons =  p_number_of_persons)
    AND (p_has_pv            IS NULL OR has_pv            =  p_has_pv)
    AND (p_sqm_min           IS NULL OR square_meters     >= p_sqm_min)
    AND (p_sqm_max           IS NULL OR square_meters     <= p_sqm_max)
    AND (p_house_types       IS NULL OR house_type        = ANY(p_house_types));

  RETURN v_result;
END;
$$;
