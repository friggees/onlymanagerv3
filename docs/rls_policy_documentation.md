# RLS Policy Documentation

This document outlines the Row Level Security (RLS) policies implemented in the OnlyManager project, their purpose, common patterns, and testing considerations.

## Implemented RLS Policies

The following RLS policies have been implemented across the tables. The general approach is to allow users to manage their own data, with owners having broader access.

### 1. `public.user_profiles`
- **Policies (from migration `11_user_profiles_rls_policies`):**
    - `user_profiles_select`:
        - **Purpose:** Allows users to select their own profile. Owners can select any profile.
        - **Logic (Conceptual):** `auth.uid() = id OR public.get_user_role() = 'owner'`
    - `user_profiles_update`:
        - **Purpose:** (As of migration `14_fix_user_profiles_update_rls`) Restricts ALL update operations on `user_profiles` to only be permissible by users with the 'owner' role. Non-owners can no longer update their own profiles directly via RLS. Any self-service updates (e.g., for `full_name`, `telegram_username`) would need to be handled via `SECURITY DEFINER` functions or a privileged backend process.
        - **Policy Name:** `user_profiles_update`
        - **`USING` Condition:** `public.get_user_role() = 'owner'`
        - **`WITH CHECK` Condition:** `public.get_user_role() = 'owner'`
    - `user_profiles_insert`:
        - **Purpose:** Allows authenticated users to insert their own profile (typically `id` must match `auth.uid()`). Owners can insert any profile.
        - **Logic (Conceptual):** `auth.uid() = id OR public.get_user_role() = 'owner'` (The `id = auth.uid()` part is crucial for non-owners).
    - `user_profiles_delete`:
        - **Purpose:** Allows owners to delete user profiles. Regular users cannot delete their own profiles directly through this policy.
        - **Logic (Conceptual):** `public.get_user_role() = 'owner'`

*(Note: The `public.get_user_role()` function has been created and returns the `role` from `public.user_profiles` for the current `auth.uid()`. It is a `SECURITY DEFINER` function.)*

### 2. `public.models`
- **Policies (from migration `12_models_rls_policies`):**
    - `models_select`:
        - **Purpose:** Allows models to see their own record (if `user_id` matches `auth.uid()`). Allows assigned managers/chatters to see models they are assigned to. Owners can see all models.
        - **Logic (Conceptual):** `(public.get_user_role() = 'model' AND user_id = auth.uid()) OR is_assigned_to_model(id) OR public.get_user_role() = 'owner'`
    - `models_update`:
        - **Purpose:** Allows models to update their own record. Owners can update any model. (Financial fields are further restricted by the `restrict_model_financial_updates` trigger).
        - **Logic (Conceptual):** `(public.get_user_role() = 'model' AND user_id = auth.uid()) OR public.get_user_role() = 'owner'`
    - `models_insert`:
        - **Purpose:** Allows owners to insert new models.
        - **Logic (Conceptual):** `public.get_user_role() = 'owner'`
    - `models_delete`:
        - **Purpose:** Allows owners to delete models.
        - **Logic (Conceptual):** `public.get_user_role() = 'owner'`

### 3. Business Logic Tables (Owner Only Access)
- **Policies (from migration `13_business_tables_owner_only_rls`):**
    - **`public.user_model_assignments`**:
        - `user_model_assignments_owner_only` (FOR ALL):
            - **Purpose:** Restricts all (SELECT, INSERT, UPDATE, DELETE) operations to users with the 'owner' role.
            - **Logic (Conceptual):** `public.get_user_role() = 'owner'`
    - **`public.user_financial_settings`**:
        - `user_financial_settings_owner_only` (FOR ALL):
            - **Purpose:** Restricts all operations to users with the 'owner' role.
            - **Logic (Conceptual):** `public.get_user_role() = 'owner'`
    - **`public.platform_settings`**:
        - `platform_settings_select_all` (FOR SELECT):
            - **Purpose:** Allows all authenticated users to read platform settings.
            - **Logic (Conceptual):** `auth.role() = 'authenticated'`
        - `platform_settings_update_owner_only` (FOR UPDATE):
            - **Purpose:** Restricts update operations to users with the 'owner' role.
            - **Logic (Conceptual):** `public.get_user_role() = 'owner'`
    - **`public.model_specific_settings`**:
        - `model_specific_settings_owner_only` (FOR ALL):
            - **Purpose:** Restricts all operations to users with the 'owner' role.
            - **Logic (Conceptual):** `public.get_user_role() = 'owner'`

*(Note: The `public.get_user_role()` function has been created and returns the `role` from `public.user_profiles` for the current `auth.uid()`. It is a `SECURITY DEFINER` function. The `is_assigned_to_model(model_id)` function remains conceptual for now for the `models` table policies, and would also use `public.get_user_role()` if implemented.)*

## Common RLS Patterns

1.  **Own Data Access:** Users (models, managers, chatters) can typically view and modify their own primary records (e.g., their `user_profiles` entry, or a model's own `models` entry). This is usually achieved by checking `auth.uid() = table.user_id_column`.
2.  **Owner Override:** Users with the 'owner' role generally have permissive access to all data across most tables for administrative purposes. This is often implemented with an `OR get_my_role() = 'owner'` condition in policies.
3.  **Role-Based Access for Specific Tables:** Some tables, particularly those dealing with core business logic, finances, or assignments, are restricted to 'owner' only for modifications, ensuring tight control over these critical areas.
4.  **Authenticated Read for Global Settings:** Global settings like `platform_settings` are often readable by any authenticated user but modifiable only by owners.

## Testing Limitations with MCP Tools

- **User Context:** The `execute_sql` MCP tool connects to the database as the `postgres` superuser (or the user configured for the Supabase connection). This means `auth.uid()` is typically `NULL` or does not represent an actual application user.
- **Impact on RLS:**
    - Policies relying on `auth.uid()` to identify the current user (e.g., "users can see their own profile") cannot be accurately tested for specific user roles other than how the `postgres` user context is interpreted by the RLS helper functions (often defaulting to permissive/owner-like access if `auth.uid()` is NULL and the helper functions are designed that way).
    - Scenarios like "a 'manager' trying to access data they shouldn't" or "a 'model' trying to update another model's profile" cannot be directly simulated.
- **Trigger Interaction:** Triggers that use `auth.uid()` or session-specific role functions (like `public.get_user_role()`) will also operate under this `postgres` user context, potentially leading to different behavior than when called by an application user.

## Frontend Integration Testing Checklist for RLS

Due to the limitations above, thorough RLS testing must be performed from a client application (e.g., the frontend) where users are authenticated through Supabase Auth, and API calls are made within a genuine user session context.

**For each user role (Owner, Manager, Model, Chatter):**

**`user_profiles` Table:**
- [ ] **SELECT:**
    - [ ] Can view their own profile.
    - [ ] (Non-Owner) Cannot view other users' profiles.
    - [ ] (Owner) Can view any user's profile.
- [ ] **UPDATE:**
    - [ ] Can update their own non-role fields (e.g., `full_name`, `telegram_username`).
    - [ ] (Non-Owner) Cannot update their `role` (RLS now prevents all self-updates).
    - [ ] (Non-Owner) Cannot update another user's profile.
    - [ ] (Owner) Can update any user's non-role fields.
    - [ ] (Owner) Can update a user's `role` (respecting `prevent_role_escalation` trigger logic).
- [ ] **INSERT:**
    - [ ] (Non-Owner) Can create their own profile upon signup (if `id` matches `auth.uid()`).
    - [ ] (Owner) Can create new user profiles.
- [ ] **DELETE:**
    - [ ] (Non-Owner) Cannot delete their own or other profiles.
    - [ ] (Owner) Can delete user profiles.

**`models` Table:**
- [ ] **SELECT:**
    - [ ] (Model) Can view their own model record (if `models.user_id` matches their `auth.uid()`).
    - [ ] (Manager/Chatter) Can view models they are assigned to via `user_model_assignments`.
    - [ ] (Manager/Chatter/Unassigned Model) Cannot view models they are not associated with.
    - [ ] (Owner) Can view all model records.
- [ ] **UPDATE:**
    - [ ] (Model) Can update their own model's non-financial fields.
    - [ ] (Model) Cannot update their own model's financial fields (e.g., `platform_fee_percentage`) due to `restrict_model_financial_updates` trigger.
    - [ ] (Non-Owner) Cannot update other models' records.
    - [ ] (Owner) Can update any model's non-financial fields.
    - [ ] (Owner) Can update any model's financial fields.
- [ ] **INSERT:**
    - [ ] (Non-Owner) Cannot insert new model records.
    - [ ] (Owner) Can insert new model records.
- [ ] **DELETE:**
    - [ ] (Non-Owner) Cannot delete model records.
    - [ ] (Owner) Can delete model records.

**`user_model_assignments` Table:**
- [ ] **SELECT/INSERT/UPDATE/DELETE:**
    - [ ] (Non-Owner) Cannot perform any operations.
    - [ ] (Owner) Can perform all operations (SELECT, INSERT, UPDATE, DELETE).

**`user_financial_settings` Table:**
- [ ] **SELECT/INSERT/UPDATE/DELETE:**
    - [ ] (Non-Owner) Cannot perform any operations.
    - [ ] (Owner) Can perform all operations.

**`platform_settings` Table:**
- [ ] **SELECT:**
    - [ ] (Any Authenticated Role) Can read platform settings.
- [ ] **UPDATE:**
    - [ ] (Non-Owner) Cannot update platform settings.
    - [ ] (Owner) Can update platform settings.

**`model_specific_settings` Table:**
- [ ] **SELECT/INSERT/UPDATE/DELETE:**
    - [ ] (Non-Owner) Cannot perform any operations.
    - [ ] (Owner) Can perform all operations.

This checklist provides a starting point and should be expanded based on specific application workflows and security requirements.
