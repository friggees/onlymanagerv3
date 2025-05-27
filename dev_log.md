## 2025-05-25

- **Applied Migration `22_debug_rls_with_verbose_logging`**:
    - Added a `DO $$ BEGIN ... END $$;` block to conditionally create the `public.user_role_type` ENUM ('owner', 'manager', 'chatter', 'model') if it doesn't already exist. This resolved the previous "type does not exist" error.
    - Created debug versions of RLS functions:
        - `public.is_assigned_to_model_debug(UUID, UUID)`: Logs its inputs, assignment count, and final boolean result.
        - `public.get_user_role_debug()`: Logs `auth.uid()`, cached role status, queried role, and final returned role.
    - Granted `EXECUTE` permissions on these debug functions to the `authenticated` role.
    - Replaced the `models_select` RLS policy on `public.models` with `models_select_debug`, which utilizes the new debug functions. The policy logic remains:
        - Models see their own records (`get_user_role_debug() = 'model' AND user_id = auth.uid()`).
        - Managers/Chatters see models they are assigned to (`is_assigned_to_model_debug(id, auth.uid())`).
        - Owners see all (`get_user_role_debug() = 'owner'`).
    - Ensured test data for `public.user_model_assignments` was correctly inserted for manager '37988e39-c60c-4ede-ae3f-5be31ca052cd' and chatter '62c22102-e59d-4c48-a54f-1478bdd062a7' assigned to model '10000000-0000-0000-0000-000000000001'.
    - Ensured the user profile '37988e39-c60c-4ede-ae3f-5be31ca052cd' has the role 'manager'.
    - The migration includes verification SELECT statements for user profiles and assignments.
- Advised user to trigger the RLS policy (e.g., by querying `public.models` as a test user) and then check Supabase logs for `NOTICE` messages to gather debug information.
