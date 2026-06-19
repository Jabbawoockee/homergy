-- ============================================================
-- GasTrack: Fehlende Tabellen-Migrationen
--
-- Der sync_service.dart referenziert diese 4 Tabellen, jedoch
-- existieren bisher keine offiziellen Migrations-Dateien dafür.
-- Alle Statements sind idempotent (IF NOT EXISTS / IF NOT EXISTS).
-- ============================================================

-- ------------------------------------------------------------
-- meter_readings
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS meter_readings (
  id         UUID             PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID             NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  value      DOUBLE PRECISION NOT NULL,
  timestamp  TIMESTAMPTZ      NOT NULL,
  note       TEXT,
  created_at TIMESTAMPTZ      NOT NULL DEFAULT now()
);

ALTER TABLE meter_readings ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'meter_readings' AND policyname = 'meter_readings_own'
  ) THEN
    CREATE POLICY "meter_readings_own" ON meter_readings
      FOR ALL
      USING     (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- ------------------------------------------------------------
-- electricity_readings
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS electricity_readings (
  id         UUID             PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID             NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  value      DOUBLE PRECISION NOT NULL,
  timestamp  TIMESTAMPTZ      NOT NULL,
  note       TEXT,
  created_at TIMESTAMPTZ      NOT NULL DEFAULT now()
);

ALTER TABLE electricity_readings ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'electricity_readings' AND policyname = 'electricity_readings_own'
  ) THEN
    CREATE POLICY "electricity_readings_own" ON electricity_readings
      FOR ALL
      USING     (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- ------------------------------------------------------------
-- electricity_contracts
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS electricity_contracts (
  id                      UUID             PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                 UUID             NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  internal_name           TEXT             NOT NULL,
  display_name            TEXT             NOT NULL,
  price_per_kwh           DOUBLE PRECISION NOT NULL,
  monthly_base_price      DOUBLE PRECISION NOT NULL,
  valid_from              BIGINT           NOT NULL,
  contract_end_date       BIGINT,
  monthly_advance_payment DOUBLE PRECISION,
  created_at              TIMESTAMPTZ      NOT NULL DEFAULT now()
);

ALTER TABLE electricity_contracts ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'electricity_contracts' AND policyname = 'electricity_contracts_own'
  ) THEN
    CREATE POLICY "electricity_contracts_own" ON electricity_contracts
      FOR ALL
      USING     (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- ------------------------------------------------------------
-- advance_payment_changes
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS advance_payment_changes (
  id            UUID             PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID             NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  contract_type TEXT             NOT NULL CHECK (contract_type IN ('gas', 'electricity')),
  amount        DOUBLE PRECISION NOT NULL,
  valid_from    BIGINT           NOT NULL,
  created_at    TIMESTAMPTZ      NOT NULL DEFAULT now()
);

ALTER TABLE advance_payment_changes ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'advance_payment_changes' AND policyname = 'advance_payment_changes_own'
  ) THEN
    CREATE POLICY "advance_payment_changes_own" ON advance_payment_changes
      FOR ALL
      USING     (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;
