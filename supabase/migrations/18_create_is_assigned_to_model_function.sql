-- Function to check if the current user is assigned to a given model_id
-- This is used in the RLS policy for the 'models' table.

CREATE OR REPLACE FUNCTION public.is_assigned_to_model(p_model_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER -- Important for RLS to access user_model_assignments
AS $$
DECLARE
    current_user_id UUID := auth.uid();
    user_role TEXT;
    is_assigned BOOLEAN := FALSE;
BEGIN
    -- Get the current user's role.
    -- We use the existing get_user_role() which has recursion protection.
    user_role := public.get_user_role();

    -- Only managers or chatters can be "assigned" in this context for viewing models.
    -- Models see their own record via a different part of the RLS policy.
    -- Owners also have a separate OR condition for full access.
    IF user_role IN ('manager', 'chatter') THEN
        SELECT EXISTS (
            SELECT 1
            FROM public.user_model_assignments uma
            WHERE uma.model_id = p_model_id
            AND uma.user_id = current_user_id
        )
        INTO is_assigned;
    END IF;

    RETURN is_assigned;
END;
$$;

COMMENT ON FUNCTION public.is_assigned_to_model(UUID) IS 'Checks if the current authenticated user (manager or chatter) is assigned to the specified model_id via the user_model_assignments table.';

-- Grant execute permission to authenticated users, as RLS policies will call this.
GRANT EXECUTE ON FUNCTION public.is_assigned_to_model(UUID) TO authenticated;

-- The RLS policy 'models_select' on public.models already uses is_assigned_to_model(id).
-- No change to the policy definition itself is needed, but it will now use this implemented function.
-- Example of the policy for reference (from migration 12_models_rls_policies):
-- CREATE POLICY models_select ON public.models
-- FOR SELECT
-- USING (
--     (public.get_user_role() = 'model' AND user_id = auth.uid()) OR -- Model sees their own
--     public.is_assigned_to_model(id) OR -- Manager/Chatter sees assigned
--     public.get_user_role() = 'owner' -- Owner sees all
-- );
