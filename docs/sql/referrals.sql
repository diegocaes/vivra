-- ============================================================
-- PetLog — Sistema de Referidos
-- Ejecutar en Supabase SQL Editor
-- ============================================================

-- 1. Tabla de codigos de referido (uno por usuario)
CREATE TABLE IF NOT EXISTS referral_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  code TEXT NOT NULL,
  uses_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT referral_codes_user_unique UNIQUE (user_id),
  CONSTRAINT referral_codes_code_unique UNIQUE (code)
);

ALTER TABLE referral_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own referral code"
  ON referral_codes FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users update own referral code"
  ON referral_codes FOR UPDATE
  USING (user_id = auth.uid());

-- Allow anyone to check if a code exists (for registration validation)
CREATE POLICY "Anyone can check code exists"
  ON referral_codes FOR SELECT
  USING (true);

-- 2. Tabla de referidos (quien refirio a quien)
CREATE TABLE IF NOT EXISTS referrals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_id UUID NOT NULL REFERENCES auth.users(id),
  referred_id UUID NOT NULL REFERENCES auth.users(id),
  code TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'rewarded')),
  reward_granted BOOLEAN DEFAULT FALSE,
  premium_days_granted INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  CONSTRAINT referrals_referred_unique UNIQUE (referred_id)
);

ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see referrals they made"
  ON referrals FOR SELECT
  USING (referrer_id = auth.uid() OR referred_id = auth.uid());

-- 3. Tabla de suscripciones / estado premium
CREATE TABLE IF NOT EXISTS user_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan TEXT NOT NULL DEFAULT 'free' CHECK (plan IN ('free', 'premium')),
  source TEXT CHECK (source IN ('referral', 'iap', 'promo', 'trial')),
  premium_until TIMESTAMPTZ,
  trial_ends_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT user_subscriptions_user_unique UNIQUE (user_id)
);

ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own subscription"
  ON user_subscriptions FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users update own subscription"
  ON user_subscriptions FOR UPDATE
  USING (user_id = auth.uid());

-- 4. Funcion helper: generar codigo basado en nombre de mascota
-- Llamada desde el servidor despues de crear la mascota
-- Formato: NOMBRE + 4 digitos random (ej: TINTO2847)
CREATE OR REPLACE FUNCTION generate_referral_code(pet_name TEXT)
RETURNS TEXT AS $$
DECLARE
  base_code TEXT;
  full_code TEXT;
  attempts INTEGER := 0;
BEGIN
  base_code := UPPER(REGEXP_REPLACE(UNACCENT(pet_name), '[^A-Z0-9]', '', 'g'));
  IF LENGTH(base_code) > 8 THEN
    base_code := SUBSTRING(base_code, 1, 8);
  END IF;
  LOOP
    full_code := base_code || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
    BEGIN
      -- Check uniqueness
      PERFORM 1 FROM referral_codes WHERE code = full_code;
      IF NOT FOUND THEN
        RETURN full_code;
      END IF;
    END;
    attempts := attempts + 1;
    IF attempts > 20 THEN
      -- Fallback: add more random chars
      RETURN base_code || LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Necesita la extension unaccent para quitar tildes
CREATE EXTENSION IF NOT EXISTS unaccent;

-- 5. Indices para performance
CREATE INDEX IF NOT EXISTS idx_referral_codes_code ON referral_codes(code);
CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON referrals(referrer_id);
CREATE INDEX IF NOT EXISTS idx_referrals_status ON referrals(status);
