-- ============================================================
-- GasTrack: Anonyme Verbrauchsvergleich-Tabelle + RPCs
-- Im Supabase SQL-Editor ausführen
-- ============================================================

CREATE TABLE IF NOT EXISTS consumption_benchmarks (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                   UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  -- Matching-Kriterien (aus Hausdaten)
  house_type                TEXT,
  square_meters             INT,
  number_of_persons         INT,
  has_pv                    BOOLEAN,
  has_solar_thermal         BOOLEAN,
  construction_year         INT,
  is_insulated              BOOLEAN,
  plz_prefix                TEXT,          -- erste 2 Stellen der PLZ (Klimazone)
  -- Normierte Verbrauchswerte (null = Typ wird nicht getrackt)
  gas_kwh_monthly_avg       DOUBLE PRECISION,
  electricity_kwh_monthly_avg DOUBLE PRECISION,
  updated_at                TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Row Level Security
ALTER TABLE consumption_benchmarks ENABLE ROW LEVEL SECURITY;

-- Jeder User darf nur seine eigene Zeile schreiben
CREATE POLICY "own_write" ON consumption_benchmarks
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Alle authentifizierten User (inkl. anonym) dürfen alle Zeilen lesen
CREATE POLICY "authenticated_read" ON consumption_benchmarks
  FOR SELECT
  USING (auth.role() = 'authenticated');

-- ============================================================
-- RPC: Gas-Vergleich
-- ============================================================
CREATE OR REPLACE FUNCTION get_gas_benchmark(
  p_user_id                 UUID,
  p_house_type              TEXT    DEFAULT NULL,
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
    AND (p_house_type            IS NULL OR house_type             =  p_house_type)
    AND (p_sqm_min               IS NULL OR square_meters          >= p_sqm_min)
    AND (p_sqm_max               IS NULL OR square_meters          <= p_sqm_max)
    AND (p_has_solar_thermal     IS NULL OR has_solar_thermal      =  p_has_solar_thermal)
    AND (p_construction_year_min IS NULL OR construction_year      >= p_construction_year_min)
    AND (p_construction_year_max IS NULL OR construction_year      <= p_construction_year_max)
    AND (p_is_insulated          IS NULL OR is_insulated           =  p_is_insulated)
    AND (p_plz_prefix            IS NULL OR plz_prefix             =  p_plz_prefix);

  RETURN v_result;
END;
$$;

-- ============================================================
-- RPC: Strom-Vergleich
-- ============================================================
CREATE OR REPLACE FUNCTION get_electricity_benchmark(
  p_user_id           UUID,
  p_number_of_persons INT     DEFAULT NULL,
  p_has_pv            BOOLEAN DEFAULT NULL,
  p_sqm_min           INT     DEFAULT NULL,
  p_sqm_max           INT     DEFAULT NULL,
  p_house_type        TEXT    DEFAULT NULL
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
    AND (p_house_type        IS NULL OR house_type        =  p_house_type);

  RETURN v_result;
END;
$$;
