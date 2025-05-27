-- Rework is_assigned_to_model to be SECURITY INVOKER and take user_id as a parameter.

-- Drop the old function first
DROP FUNCTION IF EXISTS public.is_assigned_to_model(UUID);

-- Create the new function
CREATE OR REPLACE FUNCTION public.is_assigned_to_model(p_model_id UUID, p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY INVOKER -- Runs with the permissions of the calling user (the one whose RLS policy is being checked)
AS $$
DECLARE
    _is_assigned BOOLEAN := FALSE;
BEGIN
    -- No RAISE NOTICE here for now, as it might not be visible.
    -- The function is now simpler and relies on the calling RLS policy to provide the correct user_id.
    IF p_user_id IS NULL THEN
        RETURN FALSE;
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM public.user_model_assignments uma
        WHERE uma.model_id = p_model_id
        AND uma.user_id = p_user_id
    )
    INTO _is_assigned;

    RETURN _is_assigned;
END;
$$;

COMMENT ON FUNCTION public.is_assigned_to_model(UUID, UUID) IS 'Checks if the given p_user_id is assigned to the specified p_model_id. SECURITY INVOKER.';

GRANT EXECUTE ON FUNCTION public.is_assigned_to_model(UUID, UUID) TO authenticated;

-- Now, we MUST update the RLS policy on 'models' to call this new function signature.
-- Drop the existing models_select policy
DROP POLICY IF EXISTS models_select ON public.models;

-- Recreate models_select policy
CREATE POLICY models_select ON public.models
FOR SELECT
USING (
    (public.get_user_role() = 'model' AND user_id = auth.uid()) OR      -- Model sees their own
    public.is_assigned_to_model(id, auth.uid()) OR                      -- Manager/Chatter sees assigned (passing auth.uid())
    public.get_user_role() = 'owner'                                    -- Owner sees all
);

COMMENT ON POLICY models_select ON public.models IS 'Models see their own records. Managers/Chatters see models they are assigned to (via is_assigned_to_model(model.id, auth.uid())). Owners see all.';
