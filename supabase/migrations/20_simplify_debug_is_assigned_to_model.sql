-- Simplified debug version of is_assigned_to_model function
-- Temporarily removes the explicit role check inside the function
-- to isolate if the core assignment lookup is working.

CREATE OR REPLACE FUNCTION public.is_assigned_to_model(p_model_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    _current_user_id UUID;
    _is_assigned BOOLEAN := FALSE;
BEGIN
    _current_user_id := auth.uid();
    RAISE NOTICE '[is_assigned_to_model_simplified] Called for model_id: %, current_user_id: %', p_model_id, _current_user_id;

    IF _current_user_id IS NULL THEN
        RAISE NOTICE '[is_assigned_to_model_simplified] current_user_id is NULL, returning FALSE.';
        RETURN FALSE;
    END IF;

    -- Directly check assignment without explicit role check here,
    -- relying on the calling RLS policy structure.
    SELECT EXISTS (
        SELECT 1
        FROM public.user_model_assignments uma
        WHERE uma.model_id = p_model_id
        AND uma.user_id = _current_user_id
    )
    INTO _is_assigned;
    RAISE NOTICE '[is_assigned_to_model_simplified] Assignment check result for model % and user %: %', p_model_id, _current_user_id, _is_assigned;

    RAISE NOTICE '[is_assigned_to_model_simplified] Returning: %', _is_assigned;
    RETURN _is_assigned;
END;
$$;

GRANT EXECUTE ON FUNCTION public.is_assigned_to_model(UUID) TO authenticated;

COMMENT ON FUNCTION public.is_assigned_to_model(UUID) IS 'SIMPLIFIED DEBUG VERSION: Checks if current user is assigned to model. Role check removed for debugging.';
