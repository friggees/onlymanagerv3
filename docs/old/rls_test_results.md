# RLS Policy Test Results and Recommended Fixes

This document summarizes the results of the Row Level Security (RLS) policy testing performed on `2025-05-23` and provides recommendations for addressing the identified vulnerabilities.

**Legend:**
-   **[FAIL]**: Test case failed; RLS policy did not behave as expected.
-   **[PASS]**: Test case passed; RLS policy behaved as expected.
-   **[PASS\*]**: Test case passed due to other database constraints (e.g., Foreign Key), but RLS policy might still be too permissive or not the primary blocker.

---

## 1. `user_profiles` Table (Tests performed on 2025-05-23)

### 1.1. Owner Role (`owner_user_id`: `5d6275c2-5a30-4f56-b71a-ef82370caf95`)
-   **SELECT own profile**: [PASS]
-   **SELECT `manager_user_id`'s profile**: [PASS]
-   **SELECT `model_user_A_id`'s profile**: [PASS]
-   **SELECT `chatter_user_A_id`'s profile**: [PASS]
-   **SELECT all profiles**: [PASS] (Count: 5)
-   **INSERT new user profile (`a11e901b-c97d-48d0-a34c-0227d1ed9b2b`)**: [PASS] (Profile deleted after test)
-   **UPDATE own profile (`full_name`)**: [PASS]
-   **UPDATE `manager_user_id`'s profile (`full_name`, `role` to 'chatter' then back to 'manager')**: [PASS]
-   **DELETE `chatter_user_A_id`'s profile**: [PASS] (Profile and assignments restored after test)

### 1.2. Manager Role (`manager_user_id`: `34076ddf-948b-4629-a35d-b7b42d2c9618`)
-   **SELECT own profile**: [PASS]
-   **SELECT `chatter_user_A_id`'s profile (assigned to same model)**: [PASS]
-   **SELECT `model_user_A_id`'s profile (model user linked to manager's assigned model)**: [PASS]
-   **SELECT `owner_user_id`'s profile**: **[FAIL]** Manager could see Owner's profile.
-   **SELECT `chatter_user_B_id`'s profile (assigned to different model)**: **[FAIL]** Manager could see unrelated Chatter's profile.
-   **INSERT new user profile**: **[PASS*]** (Blocked by FK constraint `user_profiles_id_fkey` as test UUID not in `auth.users`. RLS INSERT policy for non-owners might not be restrictive enough or not evaluated first.)
-   **UPDATE own `full_name`**: [PASS]
-   **UPDATE own `role` (to 'owner')**: [PASS] (Blocked by `prevent_role_escalation` trigger. Error: "Only owners can modify user roles. Current JWT role: manager")
-   **UPDATE `chatter_user_A_id`'s profile (`full_name`)**: **[FAIL]** Manager could update assigned chatter's `full_name`.
-   **DELETE own profile**: **[FAIL]** Manager could delete own profile. (Profile and assignments restored after test)
-   **DELETE `chatter_user_A_id`'s profile**: **[FAIL]** Manager could delete assigned chatter's profile. (Profile and assignments restored after test)

### 1.3. Chatter Role (`chatter_user_A_id`: `d901a1e8-3695-4101-96a1-110f80315402`)
-   **SELECT own profile**: [PASS]
-   **SELECT `manager_user_id`'s profile**: **[FAIL]** Chatter could see Manager's profile.
-   **SELECT `model_user_A_id`'s profile**: **[FAIL]** Chatter could see Model User's profile.
-   **SELECT `owner_user_id`'s profile**: **[FAIL]** Chatter could see Owner's profile.
-   **SELECT `chatter_user_B_id`'s profile**: **[FAIL]** Chatter A could see Chatter B's profile.
-   **INSERT new user profile**: **[PASS*]** (Blocked by FK constraint. RLS INSERT policy for non-owners might not be restrictive enough.)
-   **UPDATE own `full_name`**: [PASS]
-   **UPDATE own `role` (to 'owner')**: [PASS] (Blocked by `prevent_role_escalation` trigger. Error: "Only owners can modify user roles. Current JWT role: chatter")
-   **UPDATE `other_user_id`'s (Manager's) profile (`full_name`)**: **[FAIL]** Chatter could update Manager's `full_name`.
-   **DELETE own profile**: **[FAIL]** Chatter could delete own profile. (Profile and assignments restored after test)

### 1.4. Model User Role (`model_user_A_id`: `53566d3b-8480-4393-b1ff-8f30dab87a73`)
-   **SELECT own profile**: [PASS]
-   **SELECT `manager_user_id`'s profile**: **[FAIL]** Model User could see Manager's profile.
-   **SELECT `chatter_user_A_id`'s profile**: **[FAIL]** Model User could see Chatter's profile.
-   **INSERT new user profile**: **[PASS*]** (Blocked by FK constraint. RLS INSERT policy for non-owners might not be restrictive enough.)
-   **UPDATE own `full_name`**: [PASS]
-   **UPDATE own `role` (to 'owner')**: [PASS] (Blocked by `prevent_role_escalation` trigger. Error: "Only owners can modify user roles. Current JWT role: model")
-   **DELETE own profile**: **[FAIL]** Model User could delete own profile. (Profile restored after test)

---

## 2. `models` Table (Tests performed on 2025-05-23)

### 2.1. Owner Role (`owner_user_id`)
-   **SELECT `model_A_record_id`**: [PASS]
-   **SELECT `model_B_record_id`**: [PASS]
-   **SELECT all models**: [PASS] (Count: 2)
-   **INSERT new model record**: [PASS] (Temporary model `model_C_record_id` created and deleted after test)
-   **UPDATE `model_A_record_id` (`name`, `platform_fee_percentage`, `split_chatting_costs`)**: [PASS]
-   **DELETE `model_A_record_id`**: [PASS] (`model_A_record_id` and its assignments restored after test)

### 2.2. Manager Role (`manager_user_id`)
-   **SELECT `model_A_record_id` (assigned model)**: [PASS]
-   **SELECT `model_B_record_id` (unassigned model)**: **[FAIL]** Manager could see an unassigned model.
-   **INSERT new model**: **[FAIL]** Manager could insert a new model. (Temporary model deleted after test)
-   **UPDATE `model_A_record_id` (`name`)**: **[FAIL]** Manager could update assigned model's name.
-   **DELETE `model_A_record_id`**: **[FAIL]** Manager could delete assigned model. (`model_A_record_id` and assignments restored after test)

### 2.3. Chatter Role (`chatter_user_A_id`)
-   **SELECT `model_A_record_id` (assigned model)**: [PASS]
-   **SELECT `model_B_record_id` (unassigned model)**: **[FAIL]** Chatter could see an unassigned model.
-   **INSERT new model**: **[FAIL]** Chatter could insert a new model. (Temporary model deleted after test)
-   **UPDATE `model_A_record_id` (`name`)**: **[FAIL]** Chatter could update assigned model's name.
-   **DELETE `model_A_record_id`**: **[FAIL]** Chatter could delete assigned model. (`model_A_record_id` and assignments restored after test)

### 2.4. Model User Role (`model_user_A_id`, linked to `model_A_record_id`)
-   **SELECT `model_A_record_id` (own model record)**: [PASS]
-   **SELECT `model_B_record_id` (other model)**: **[FAIL]** Model User could see another model's record.
-   **INSERT new model**: **[FAIL]** Model User could insert a new model. (Temporary model deleted after test)
-   **UPDATE `model_A_record_id.name`**: [PASS]
-   **UPDATE `model_A_record_id.platform_fee_percentage`**: [PASS] (Blocked by `restrict_model_financial_updates` trigger. Error: "Only owners can modify sensitive financial settings on models. Current JWT role: model")
-   **UPDATE `model_A_record_id.split_chatting_costs`**: [PASS] (Blocked by `restrict_model_financial_updates` trigger. Error: "Only owners can modify sensitive financial settings on models. Current JWT role: model")
-   **DELETE `model_A_record_id` (own model record)**: **[FAIL]** Model User could delete own model record. (`model_A_record_id` and assignments restored after test)

---

## 3. `user_model_assignments` Table (Tests performed on 2025-05-23)

### 3.1. Owner Role (`owner_user_id`)
-   **SELECT assignment for (`chatter_user_A_id`, `model_A_record_id`)**: [PASS]
-   **SELECT all assignments**: [PASS] (Count: 3)
-   **INSERT new assignment (assign `chatter_user_B_id` to `model_A_record_id`)**: [PASS] (Temporary assignment deleted after test)
-   **UPDATE**: (No updateable fields other than PKs, typically not updated directly) - Skipped.
-   **DELETE assignment**: [PASS]

### 3.2. Manager Role (`manager_user_id`, assigned to `model_A_record_id`)
-   **SELECT own assignment to `model_A_record_id`**: [PASS]
-   **SELECT `chatter_user_A_id`'s assignment to `model_A_record_id`**: [PASS]
-   **SELECT `chatter_user_B_id`'s assignment to `model_B_record_id`**: **[FAIL]** Manager could see assignment for an unassigned model.
-   **INSERT new assignments**: **[FAIL]** Manager could insert new assignment. (Temporary assignment deleted after test)
-   **DELETE assignments (`chatter_user_A_id`'s to `model_A_record_id`)**: **[FAIL]** Manager could delete assignment. (Assignment restored after test)

### 3.3. Chatter Role (`chatter_user_A_id`)
-   **SELECT own assignment to `model_A_record_id`**: [PASS]
-   **SELECT `manager_user_id`'s assignment to `model_A_record_id`**: **[FAIL]** Chatter could see manager's assignment on the same model.
-   **SELECT `chatter_user_B_id`'s assignment to `model_B_record_id`**: **[FAIL]** Chatter A could see Chatter B's (unrelated) assignment.
-   **INSERT new assignments**: **[FAIL]** Chatter could insert new assignment. (Temporary assignment deleted after test)
-   **DELETE assignments (own assignment)**: **[FAIL]** Chatter could delete own assignment. (Assignment restored after test)

### 3.4. Model User Role (`model_user_A_id`)
-   **SELECT assignments related to their model (`model_A_record_id`)**: [PASS] (Shows assignments of manager and chatter A to model A)
-   **INSERT**: **[FAIL]** Model user could insert new assignment. (Temporary assignment deleted after test)
-   **DELETE**: **[FAIL]** Model user could delete `chatter_user_A_id`'s assignment to `model_A_record_id`. (Assignment restored after test)

---

## 4. `user_financial_settings` Table (Tests performed on 2025-05-23)

### 4.1. Owner Role (`owner_user_id`)
-   **SELECT financial settings for `chatter_user_A_id`**: [PASS]
-   **SELECT all financial settings**: [PASS] (Count: 2 after setup)
-   **INSERT financial settings for `chatter_user_A_id`**: [PASS]
-   **UPDATE financial settings for `chatter_user_A_id`**: [PASS]
-   **DELETE financial settings for `chatter_user_A_id`**: [PASS] (Settings restored after test for subsequent sections)

### 4.2. Manager Role (`manager_user_id`)
-   **SELECT own financial settings**: [PASS]
-   **SELECT financial settings for `chatter_user_A_id` (assigned)**: [PASS]
-   **SELECT financial settings for `chatter_user_B_id` (unassigned)**: **[FAIL]** Manager could see settings for unassigned chatter. (Settings for Chatter B created for test, then deleted)
-   **SELECT financial settings for `owner_user_id` (no settings exist)**: [PASS] (Returned 0 rows - due to no data)
-   **INSERT financial settings (for `model_user_A_id`)**: **[FAIL]** Manager could insert settings. (Settings deleted after test)
-   **UPDATE own financial settings**: **[FAIL]** Manager could update own settings. (Settings restored after test)
-   **UPDATE financial settings for `chatter_user_A_id`**: **[FAIL]** Manager could update assigned chatter's settings. (Settings restored after test)
-   **DELETE financial settings (for `chatter_user_A_id`)**: **[FAIL]** Manager could delete assigned chatter's settings. (Settings restored after test)

### 4.3. Chatter Role (`chatter_user_A_id`)
-   **SELECT own financial settings**: [PASS]
-   **SELECT financial settings for `manager_user_id`**: **[FAIL]** Chatter could see manager's settings.
-   **SELECT financial settings for `chatter_user_B_id` (no settings exist)**: [PASS] (Returned 0 rows - due to no data)
-   **INSERT financial settings (for `model_user_A_id`)**: **[FAIL]** Chatter could insert settings. (Settings deleted after test)
-   **UPDATE own financial settings**: **[FAIL]** Chatter could update own settings. (Settings restored after test)
-   **DELETE own financial settings**: **[FAIL]** Chatter could delete own settings. (Settings restored after test)

### 4.4. Model User Role (`model_user_A_id`)
-   **SELECT own financial settings (no settings exist initially)**: [PASS] (Returned 0 rows)
-   **INSERT own settings**: **[FAIL]** Model User could insert own settings.
-   **UPDATE own settings**: **[FAIL]** Model User could update own settings.
-   **DELETE own settings**: **[FAIL]** Model User could delete own settings. (Settings created and deleted by Model User within this test block)

---

## 5. `platform_settings` Table (Singleton) (Tests performed on 2025-05-23)

### 5.1. Owner Role (`owner_user_id`)
-   **SELECT**: [PASS]
-   **INSERT (attempt with id=2)**: [PASS*] (Blocked by CHECK constraint `platform_settings_id_check`. RLS INSERT policy for owner allows attempt.)
-   **UPDATE `default_platform_fee_percentage`**: [PASS]
-   **DELETE (the singleton row id=1)**: **[FAIL]** Owner could delete the singleton row. (Row restored after test)

### 5.2. Manager Role (`manager_user_id`)
-   **SELECT**: [PASS]
-   **INSERT (attempt with id=2)**: [PASS*] (Blocked by CHECK constraint. RLS INSERT policy for non-owner likely not effective.)
-   **UPDATE `default_platform_fee_percentage`**: **[FAIL]** Manager could update settings. (Settings restored by owner after test)
-   **DELETE (the singleton row id=1)**: **[FAIL]** Manager could delete settings. (Row restored by owner after test)

### 5.3. Chatter Role (`chatter_user_A_id`)
-   **SELECT**: [PASS]
-   **INSERT (attempt with id=2)**: [PASS*] (Blocked by CHECK constraint. RLS INSERT policy for non-owner likely not effective.)
-   **UPDATE `default_platform_fee_percentage`**: **[FAIL]** Chatter could update settings. (Settings restored by owner after test)
-   **DELETE (the singleton row id=1)**: **[FAIL]** Chatter could delete settings. (Row restored by owner after test)

### 5.4. Model User Role (`model_user_A_id`)
-   **SELECT**: [PASS] (Inferred)
-   **INSERT (attempt with id=2)**: [PASS*] (Inferred, blocked by CHECK constraint)
-   **UPDATE `default_platform_fee_percentage`**: **[FAIL]** (Inferred) Model user could update settings.
-   **DELETE (the singleton row id=1)**: **[FAIL]** (Inferred) Model user could delete settings.

---

## 6. `model_specific_settings` Table (Tests performed on 2025-05-23)

### 6.1. Owner Role (`owner_user_id`)
-   **SELECT settings for `model_A_record_id`**: [PASS]
-   **SELECT all model-specific settings**: [PASS] (Count: 2 after setup)
-   **INSERT settings for `model_A_record_id`**: [PASS]
-   **UPDATE settings for `model_A_record_id`**: [PASS]
-   **DELETE settings for `model_A_record_id`**: [PASS] (Setting restored after test)

### 6.2. Manager Role (`manager_user_id`)
-   **SELECT settings for `model_A_record_id` (assigned model)**: [PASS]
-   **SELECT settings for `model_B_record_id` (unassigned model)**: **[FAIL]** Manager could see settings for an unassigned model.
-   **INSERT (for a non-existent model_id)**: **[PASS*]** (Blocked by FK constraint `model_specific_settings_model_id_fkey`. RLS INSERT for non-owner likely not effective.)
-   **UPDATE settings for `model_A_record_id`**: **[FAIL]** Manager could update settings for an assigned model.
-   **DELETE settings for `model_A_record_id`**: **[FAIL]** Manager could delete settings for an assigned model. (Setting restored after test)

### 6.3. Chatter Role (`chatter_user_A_id`)
-   **SELECT settings for `model_A_record_id` (assigned model)**: [PASS] (Inferred)
-   **SELECT settings for `model_B_record_id` (unassigned model)**: **[FAIL]** (Inferred) Chatter could see settings for an unassigned model.
-   **INSERT**: **[PASS*]** (Inferred, FK block)
-   **UPDATE**: **[FAIL]** (Inferred) Chatter could update settings for an assigned model.
-   **DELETE**: **[FAIL]** (Inferred) Chatter could delete settings for an assigned model.

### 6.4. Model User Role (`model_user_A_id`)
-   **SELECT settings for `model_A_record_id` (own model)**: [PASS] (Inferred)
-   **SELECT settings for `model_B_record_id` (other model)**: **[FAIL]** (Inferred) Model User could see settings for another model.
-   **INSERT**: **[PASS*]** (Inferred, FK block)
-   **UPDATE**: **[FAIL]** (Inferred) Model User could update settings for own model.
-   **DELETE**: **[FAIL]** (Inferred) Model User could delete settings for own model.

---

**General Recommendations:**
1.  **Principle of Least Privilege**: Policies for non-owner roles need to be significantly tightened. Default to denying access unless explicitly required.
2.  **Role Column Protection**: Updating the `role` column in `user_profiles` must be strictly controlled, likely owner-only.
3.  **Self-Modification vs. Admin Modification**: Clearly define what users can change about their own records/settings versus what administrators (owners) manage.
4.  **Foreign Key Constraints vs. RLS**: While FK constraints prevented some unauthorized actions, RLS should be the primary mechanism for enforcing access control logic. Relying on FKs for security can be misleading.
5.  **Singleton Table Protection**: The `platform_settings` table needs a robust mechanism (RLS or trigger) to prevent deletion of its single row.
6.  **Consistent Scoping**: Ensure SELECT policies for Managers, Chatters, and Model Users consistently scope data based on their assignments or ownership (e.g., `user_model_assignments`, `models.user_id`).

Reviewing and rewriting the RLS policies based on these findings is crucial for application security.

---

## Post-Revision Testing and Outstanding Concerns (After applying revised policies up to user_profiles v14 and other tables v1)

The RLS policies for all tables have been revised and reapplied. While these revisions aim to address the initially identified vulnerabilities, the following areas require specific re-testing and attention:

**1. `user_profiles` Table - Role Change Prevention:**
    -   **Concern**: The `UPDATE` policies for Manager, Chatter, and Model User roles use `WITH CHECK (... AND role = 'their_actual_role')` (implicitly referring to `NEW.role`). Previous attempts with similar `NEW.column = OLD.column` constructs failed due to parser errors ("missing FROM-clause entry for table 'new'").
    -   **Needs Testing**: Verify if non-owner roles (Manager, Chatter, Model User) can still change their own `role` field in the `user_profiles` table. If they can, this critical vulnerability remains, and alternative solutions (e.g., database triggers or column-level privileges if feasible and effective in this environment) must be implemented.

**2. `models` Table - Model User Update on Sensitive Fields:**
    -   **Concern**: The revised RLS policy allows Model Users to update their own model record (`models_model_user_update_own_name_policy`). This policy, as implemented (due to issues with `NEW.col = OLD.col`), allows updates to *all* fields on their own record, including potentially sensitive fields like `platform_fee_percentage` and `split_chatting_costs`.
    -   **Needs Testing**: Confirm Model Users can update fields like `name`. Confirm if they can also update `platform_fee_percentage` and `split_chatting_costs`.
    -   **Further Action**: If Model Users can update sensitive fields, and this is not desired, this needs to be addressed. Since RLS with `NEW.col = OLD.col` was problematic, consider database triggers or application-level logic to restrict updates to only specific columns (e.g., `name`) by Model Users.

**3. General Verification of All Revised Policies:**
    -   **Needs Testing**: Although the revised policies are designed to be more restrictive and align with the initial test case goals, a full re-run of the test cases in `docs/rls_test_cases.md` is highly recommended to confirm:
        -   All previously failed [FAIL] test cases now pass [PASS].
        -   All previously passed [PASS] test cases still pass.
        -   The behavior of [PASS\*] cases is as expected (i.e., RLS is now the primary enforcer where applicable, not just FK constraints).

**4. Performance of `get_user_role` Function:**
    -   **Concern**: The `get_user_role(UUID)` function is now used in many policies. While `SECURITY DEFINER` is appropriate, frequent calls to this function (especially if it involves a table scan on `user_profiles` for each row evaluated by RLS) could have performance implications on large datasets.
    -   **Needs Testing/Monitoring**: Monitor query performance for operations on tables with these RLS policies, especially under load. Ensure `user_profiles.id` has an efficient index (primary key usually does).

Addressing these points will ensure the RLS implementation is both secure and performs adequately.
