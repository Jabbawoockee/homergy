-- Price contracts table (multiple rows per user)
CREATE TABLE IF NOT EXISTS price_contracts (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  internal_name      TEXT NOT NULL,
  display_name       TEXT NOT NULL,
  price_per_kwh      DOUBLE PRECISION NOT NULL,
  monthly_base_price DOUBLE PRECISION NOT NULL,
  valid_from         BIGINT NOT NULL,
  brennwert          DOUBLE PRECISION NOT NULL DEFAULT 0,
  zustandszahl       DOUBLE PRECISION NOT NULL DEFAULT 0,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE price_contracts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own contracts"
  ON price_contracts
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
