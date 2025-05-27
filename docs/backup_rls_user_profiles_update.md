# Backup: RLS Policy for `user_profiles` Update (Before Granular Column Restriction)

Date: 2025-05-25

This document records the state of the RLS update policy for the `public.user_profiles` table before an intended change to restrict column-level update permissions for non-owner users.

## Current `user_profiles_update` Policy

-   **Policy Name:** `user_profiles_update`
-   **Applies to:** `UPDATE` operations on `public.user_profiles`.
-   **Conceptual `USING` and `WITH CHECK` Condition (as documented):**
    ```sql
    (auth.uid() = id) OR (get_my_role() = 'owner')
    ```
-   **Description:**
    -   This policy allows a user to update any column in their own profile row (where `auth.uid()` matches the row's `id`).
    -   It also allows a user with the 'owner' role (as determined by a conceptual `get_my_role()` function) to update any column in any user's profile row.
    -   Changes to the `role` column are additionally governed by the `prevent_role_escalation` trigger.
-   **Implication:** Non-owner users can currently update fields like `full_name`, `telegram_username`, and `contract_document_path` for their own profile.

## Intended Change

The intention is to modify this policy (or supplement it) so that non-owner users can *only* update the `full_name` and `telegram_username` columns for their own profile. Updates to other columns by non-owners (for their own profile) should be disallowed by RLS. Owner permissions are expected to remain broad.
