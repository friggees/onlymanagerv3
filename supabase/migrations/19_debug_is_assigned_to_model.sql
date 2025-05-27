-- Debug and refine is_assigned_to_model function

CREATE OR REPLACE FUNCTION public.is_assigned_to_model(p_model_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    _current_user_id UUID;
    _user_role TEXT;
    _is_assigned BOOLEAN := FALSE;
BEGIN
    _current_user_id := auth.uid();
    RAISE NOTICE '[is_assigned_to_model] Called for model_id: %, current_user_id: %', p_model_id, _current_user_id;

    IF _current_user_id IS NULL THEN
        RAISE NOTICE '[is_assigned_to_model] current_user_id is NULL, returning FALSE.';
        RETURN FALSE;
    END IF;

    _user_role := public.get_user_role(); -- This uses session cache
    RAISE NOTICE '[is_assigned_to_model] User role determined as: %', _user_role;

    IF _user_role IN ('manager', 'chatter') THEN
        RAISE NOTICE '[is_assigned_to_model] User role is manager or chatter. Checking assignment...';
        SELECT EXISTS (
            SELECT 1
            FROM public.user_model_assignments uma
            WHERE uma.model_id = p_model_id
            AND uma.user_id = _current_user_id
        )
        INTO _is_assigned;
        RAISE NOTICE '[is_assigned_to_model] Assignment check result for model % and user %: %', p_model_id, _current_user_id, _is_assigned;
    ELSE
        RAISE NOTICE '[is_assigned_to_model] User role is NOT manager or chatter (%), returning FALSE for assignment check.', _user_role;
    END IF;

    RAISE NOTICE '[is_assigned_to_model] Returning: %', _is_assigned;
    RETURN _is_assigned;
END;
$$;

-- Re-grant execute permission
GRANT EXECUTE ON FUNCTION public.is_assigned_to_model(UUID) TO authenticated;

COMMENT ON FUNCTION public.is_assigned_to_model(UUID) IS 'DEBUG VERSION: Checks if the current authenticated user (manager or chatter) is assigned to the specified model_id via the user_model_assignments table. Includes RAISE NOTICE for debugging.';
