-- Function to get user role, optimized to prevent recursion
-- It first checks a session variable, then queries the table if not set.
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
-- SET search_path = public -- Removed to avoid potential issues, rely on explicit schema qualification
AS $$
DECLARE
    _role TEXT;
    _user_id UUID := auth.uid();
BEGIN
    -- Attempt to get role from a session variable first
    BEGIN
        _role := current_setting('request.rls.user_role', TRUE); -- TRUE allows NULL if not set
    EXCEPTION
        WHEN UNDEFINED_OBJECT THEN
            _role := NULL; -- Variable not set
    END;

    IF _role IS NOT NULL THEN
        RETURN _role;
    END IF;

    -- If not set in session, query the database
    IF _user_id IS NOT NULL THEN
        SELECT role INTO _role
        FROM public.user_profiles
        WHERE id = _user_id;

        -- Set the role in a session variable to avoid re-querying within the same transaction/policy check
        -- This helps prevent recursion if this function is called by a policy on user_profiles itself.
        IF _role IS NOT NULL THEN
            PERFORM set_config('request.rls.user_role', _role, TRUE); -- TRUE for transaction-local setting
        ELSE
            -- Handle case where user has no profile or role (e.g., new user)
            -- For safety, could default to a non-privileged role or NULL
             PERFORM set_config('request.rls.user_role', 'authenticated_user_no_profile_role', TRUE);
            _role := 'authenticated_user_no_profile_role'; -- Or NULL, depending on desired default behavior
        END IF;
    ELSE
        -- Handle case where auth.uid() is NULL (e.g. service role, anon)
        -- For RLS, this often implies a bypass or a specific 'anon' role.
        -- The original policies often treated NULL UID as owner-like if get_user_role() returned 'owner'.
        -- Let's assume 'service_or_anon' for clarity, policies will decide access.
        PERFORM set_config('request.rls.user_role', 'service_or_anon', TRUE);
        _role := 'service_or_anon';
    END IF;

    RETURN _role;
END;
$$;

-- Re-grant execute on the function
GRANT EXECUTE ON FUNCTION public.get_user_role() TO authenticated, service_role;

-- Drop existing policies on user_profiles that might cause recursion
-- It's safer to drop and recreate to ensure the new function logic is picked up correctly.
-- Note: The names might vary slightly if they were changed from the initial migrations.
-- We'll use the names from migration 11 and 14.

-- From migration 11 (initial policies)
DROP POLICY IF EXISTS user_profiles_select ON public.user_profiles;
-- user_profiles_update was already replaced by migration 14
DROP POLICY IF EXISTS user_profiles_insert ON public.user_profiles;
DROP POLICY IF EXISTS user_profiles_delete ON public.user_profiles;

-- From migration 14 (the problematic update policy)
DROP POLICY IF EXISTS user_profiles_update ON public.user_profiles;


-- Recreate user_profiles RLS policies using the improved get_user_role()

-- 1. SELECT policy: Users can select their own profile. Owners can select any profile.
CREATE POLICY user_profiles_select ON public.user_profiles
FOR SELECT
USING (
    auth.uid() = id OR public.get_user_role() = 'owner'
);

-- 2. UPDATE policy: Only owners can update user_profiles.
--    The get_user_role() will use the session variable if this policy calls it, preventing recursion.
CREATE POLICY user_profiles_update ON public.user_profiles
FOR UPDATE
USING (
    public.get_user_role() = 'owner'
)
WITH CHECK (
    public.get_user_role() = 'owner'
);

-- 3. INSERT policy: Authenticated users can insert their own profile (id must match auth.uid()). Owners can insert any profile.
CREATE POLICY user_profiles_insert ON public.user_profiles
FOR INSERT
WITH CHECK (
    (auth.uid() = id AND public.get_user_role() != 'owner') OR -- Non-owner inserting their own
    public.get_user_role() = 'owner' -- Owner inserting any
    -- Note: A new user signing up might not have a role yet.
    -- get_user_role() would return 'authenticated_user_no_profile_role' or similar.
    -- The signup process (usually a SECURITY DEFINER function) should handle initial profile creation.
    -- This RLS policy primarily governs direct table inserts via API by already authenticated users.
    -- For a new user, auth.uid() = id is the critical part.
);

-- 4. DELETE policy: Only owners can delete user profiles.
CREATE POLICY user_profiles_delete ON public.user_profiles
FOR DELETE
USING (
    public.get_user_role() = 'owner'
);

-- Ensure RLS is still enabled (should be, but as a safeguard)
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles FORCE ROW LEVEL SECURITY;

COMMENT ON FUNCTION public.get_user_role() IS 'Gets the role of the current user from user_profiles. Uses a session variable (request.rls.user_role) to cache the role within a transaction to prevent RLS recursion issues.';
COMMENT ON POLICY user_profiles_select ON public.user_profiles IS 'Allows users to select their own profile. Owners can select any profile.';
COMMENT ON POLICY user_profiles_update ON public.user_profiles IS 'Restricts ALL update operations on user_profiles to only be permissible by users with the owner role. Uses get_user_role() with session cache.';
COMMENT ON POLICY user_profiles_insert ON public.user_profiles IS 'Allows authenticated users to insert their own profile (id must match auth.uid()). Owners can insert any profile. Uses get_user_role() with session cache.';
COMMENT ON POLICY user_profiles_delete ON public.user_profiles IS 'Allows owners to delete user profiles. Uses get_user_role() with session cache.';
