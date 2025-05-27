# Schema Documentation

This document outlines the current state of the database schema for the OnlyManager project.

## Tables

### 1. `public.user_profiles`
- **RLS Enabled:** Yes
- **RLS Forced:** Yes
- **Columns:**
    - `id` (uuid, PK, Not Null): User's unique identifier, references `auth.users(id)`.
    - `full_name` (text, Nullable): User's full name.
    - `role` (text, Not Null): User's role. CHECK constraint: `role = ANY (ARRAY['owner'::text, 'manager'::text, 'chatter'::text, 'model'::text])`.
    - `telegram_username` (text, Nullable): User's Telegram username.
    - `contract_document_path` (text, Nullable): Path to the user's contract document.
    - `supervisor_id` (uuid, Nullable): The ID of the user profile that supervises this user. References `public.user_profiles(id)`.
    - `created_at` (timestamptz, Nullable, Default: `now()`): Timestamp of creation.
    - `updated_at` (timestamptz, Nullable, Default: `now()`): Timestamp of last update.
- **Primary Key:** `id`
- **Relationships (Foreign Keys pointing to this table):**
    - `user_model_assignments.user_id` -> `user_profiles.id`
    - `user_financial_settings.user_id` -> `user_profiles.id`
    - `models.user_id` -> `user_profiles.id`
    - `user_profiles.supervisor_id` -> `user_profiles.id` (Self-referencing for supervisor)
- **Relationships (Foreign Keys from this table):**
    - `user_profiles.id` -> `auth.users.id`
    - `user_profiles.supervisor_id` -> `public.user_profiles.id`

### 2. `public.models`
- **RLS Enabled:** Yes
- **RLS Forced:** Yes
- **Columns:**
    - `id` (uuid, PK, Not Null, Default: `gen_random_uuid()`): Model's unique identifier.
    - `user_id` (uuid, Nullable, Unique): Associated user profile ID (if the model is a user). References `user_profiles(id)`.
    - `name` (text, Not Null): Name of the model.
    - `platform_fee_percentage` (numeric, Nullable, Default: `20.00`): Specific platform fee for this model (overrides global if set).
    - `split_chatting_costs` (boolean, Nullable, Default: `false`): Whether chatting costs are split.
    - `created_at` (timestamptz, Nullable, Default: `now()`): Timestamp of creation.
    - `updated_at` (timestamptz, Nullable, Default: `now()`): Timestamp of last update.
- **Primary Key:** `id`
- **Relationships (Foreign Keys pointing to this table):**
    - `model_specific_settings.model_id` -> `models.id`
    - `user_model_assignments.model_id` -> `models.id`
- **Relationships (Foreign Keys from this table):**
    - `models.user_id` -> `user_profiles.id` (One-to-One)

### 3. `public.user_model_assignments`
- **RLS Enabled:** Yes
- **RLS Forced:** Yes
- **Columns:**
    - `user_id` (uuid, PK, Not Null): User's ID. References `user_profiles(id)`.
    - `model_id` (uuid, PK, Not Null): Model's ID. References `models(id)`.
    - `assigned_at` (timestamptz, Nullable, Default: `now()`): Timestamp of assignment.
- **Primary Key:** (`user_id`, `model_id`)
- **Relationships (Foreign Keys from this table):**
    - `user_model_assignments.model_id` -> `models.id`
    - `user_model_assignments.user_id` -> `user_profiles.id`

### 4. `public.user_financial_settings`
- **RLS Enabled:** Yes
- **RLS Forced:** Yes
- **Columns:**
    - `user_id` (uuid, PK, Not Null): User's ID. References `user_profiles(id)`.
    - `commission_percentage` (numeric, Nullable): Commission percentage for the user.
    - `fixed_salary_amount` (numeric, Nullable): Fixed salary amount for the user.
    - `salary_type` (USER-DEFINED `salary_structure_type`, Not Null): Type of salary structure. Enum values: `commission_only`, `fixed_only`, `fixed_plus_commission`, `passive_tick_only`.
    - `manager_passive_tick_percentage` (numeric, Nullable): Passive tick percentage for managers.
    - `created_at` (timestamptz, Nullable, Default: `now()`): Timestamp of creation.
    - `updated_at` (timestamptz, Nullable, Default: `now()`): Timestamp of last update.
- **Primary Key:** `user_id`
- **Relationships (Foreign Keys from this table):**
    - `user_financial_settings.user_id` -> `user_profiles.id` (One-to-One)

### 5. `public.platform_settings`
- **RLS Enabled:** Yes
- **RLS Forced:** Yes
- **Columns:**
    - `id` (integer, PK, Not Null, Default: `1`): Singleton ID. CHECK constraint: `id = 1`.
    - `default_platform_fee_percentage` (numeric, Nullable, Default: `20.00`): Default platform fee percentage.
    - `currency_symbol` (text, Nullable, Default: `'$'`): Default currency symbol.
    - `currency_code` (text, Nullable, Default: `'USD'`): Default currency code.
    - `created_at` (timestamptz, Nullable, Default: `now()`): Timestamp of creation.
    - `updated_at` (timestamptz, Nullable, Default: `now()`): Timestamp of last update.
- **Primary Key:** `id`
- **Relationships:** None

### 6. `public.model_specific_settings`
- **RLS Enabled:** Yes
- **RLS Forced:** Yes
- **Columns:**
    - `model_id` (uuid, PK, Not Null): Model's ID. References `models(id)`.
    - `platform_fee_percentage` (numeric, Nullable): Specific platform fee for this model, overrides `platform_settings` and `models` table's `platform_fee_percentage`.
    - `created_at` (timestamptz, Nullable, Default: `now()`): Timestamp of creation.
    - `updated_at` (timestamptz, Nullable, Default: `now()`): Timestamp of last update.
- **Primary Key:** `model_id`
- **Relationships (Foreign Keys from this table):**
    - `model_specific_settings.model_id` -> `models.id` (One-to-One)

---

## Schema Diagram (Text-based)

```
+---------------------+      +---------------------+      +--------------------------+
|    auth.users       |<-----| public.user_profiles|<-----|  public.models           |
|---------------------|      |---------------------|      |--------------------------|
| id (uuid, PK)       |----->| id (uuid, PK)       |<-----+ id (uuid, PK)            |
| ...                 |      | full_name (text)    |----->| user_id (uuid, FK, Unique)|
+---------------------+      | role (text)         |      | name (text)              |
                             | supervisor_id (uuid, FK) |      | platform_fee_percentage  |
                             | ...                 |      | ...                      |
                             +---------------------+      +-----------^--------------+
                                    ^      ^       |                  |
                                    |      |       +------------------+ (supervisor_id points to user_profiles.id)
                                    |      |                           |
           +------------------------+      |      +--------------------+
           |                               |      |
           v                               |      v
+--------------------------+               |      +--------------------------+
| public.user_model_assignments|               |      | public.model_specific_settings|
|--------------------------|               |      |--------------------------|
| user_id (uuid, PK, FK)   |<--------------+      | model_id (uuid, PK, FK)  |
| model_id (uuid, PK, FK)  |--------------------->| platform_fee_percentage  |
| assigned_at (timestamptz)|                      | ...                      |
+--------------------------+                      +--------------------------+

+--------------------------+
| public.user_financial_settings|
|--------------------------|
| user_id (uuid, PK, FK)   |<--------------+
| commission_percentage    |               | (from user_profiles)
| fixed_salary_amount      |
| salary_type (enum)       |
| ...                      |
+--------------------------+

+--------------------------+
| public.platform_settings |
|--------------------------|
| id (int, PK, Default: 1) |
| default_platform_fee_percentage |
| currency_symbol (text)   |
| currency_code (text)     |
| ...                      |
+--------------------------+

Key:
PK = Primary Key
FK = Foreign Key
<--- = Foreign Key Relationship (arrow points from FK to PK)
```

---

## Migration History

| Version          | Name                                  |
|------------------|---------------------------------------|
| 20250524103211   | 01_create_user_profiles               |
| 20250524103358   | 02_create_models                      |
| 20250524103559   | 03_create_user_model_assignments      |
| 20250524103711   | 04_create_financial_settings          |
| 20250524103926   | 05_create_platform_settings           |
| 20250524104025   | 06_create_model_specific_settings     |
| 20250524104142   | 07_create_updated_at_triggers         |
| 20250524104317   | 08_create_role_protection_trigger     |
| 20250524104401   | 09_create_financial_protection_trigger|
| 20250524104503   | 10_enable_rls                         |
| 20250524104537   | 11_user_profiles_rls_policies         |
| 20250524104634   | 12_models_rls_policies                |
| 20250524104714   | 13_business_tables_owner_only_rls     |

---
