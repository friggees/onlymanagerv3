-- Seed or update specific user profiles with given roles and placeholder data if new.
-- Assumes corresponding entries in auth.users already exist for these UUIDs.
-- user_profiles columns: id, full_name, role, telegram_username, contract_document_path, created_at, updated_at

-- Upsert Owner
INSERT INTO public.user_profiles (id, full_name, role)
VALUES ('1c8debf1-ccbf-45ef-ac54-c5b1891299db', 'Owner User 1c8deb', 'owner')
ON CONFLICT (id) DO UPDATE SET
  role = EXCLUDED.role,
  full_name = COALESCE(public.user_profiles.full_name, EXCLUDED.full_name),
  updated_at = now();

-- Upsert Manager
INSERT INTO public.user_profiles (id, full_name, role)
VALUES ('3c858221-62e9-4de0-9179-028d68a4b2f1', 'Manager User 3c8582', 'manager')
ON CONFLICT (id) DO UPDATE SET
  role = EXCLUDED.role,
  full_name = COALESCE(public.user_profiles.full_name, EXCLUDED.full_name),
  updated_at = now();

-- Upsert Chatter
INSERT INTO public.user_profiles (id, full_name, role)
VALUES ('f14d09f2-2996-4ed9-913c-43e7753b5545', 'Chatter User f14d09', 'chatter')
ON CONFLICT (id) DO UPDATE SET
  role = EXCLUDED.role,
  full_name = COALESCE(public.user_profiles.full_name, EXCLUDED.full_name),
  updated_at = now();

-- Upsert Model
INSERT INTO public.user_profiles (id, full_name, role)
VALUES ('22460f36-ed94-40d1-b0c0-3203ff1ee087', 'Model User 22460f', 'model')
ON CONFLICT (id) DO UPDATE SET
  role = EXCLUDED.role,
  full_name = COALESCE(public.user_profiles.full_name, EXCLUDED.full_name),
  updated_at = now();
