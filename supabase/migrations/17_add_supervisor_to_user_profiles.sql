-- Add supervisor_id to user_profiles for direct manager-chatter assignments

ALTER TABLE public.user_profiles
ADD COLUMN supervisor_id UUID NULL;

COMMENT ON COLUMN public.user_profiles.supervisor_id IS 'The ID of the user profile that supervises this user (e.g., a manager supervising a chatter).';

-- Add foreign key constraint for supervisor_id to user_profiles(id)
-- This means a supervisor must also be a user in user_profiles.
ALTER TABLE public.user_profiles
ADD CONSTRAINT fk_supervisor_id
FOREIGN KEY (supervisor_id)
REFERENCES public.user_profiles(id)
ON DELETE SET NULL -- If a supervisor profile is deleted, remove the link from their supervisees
ON UPDATE CASCADE; -- If a supervisor's ID changes (unlikely for UUIDs), update references

-- Optional: Add a CHECK constraint to enforce role logic for supervisors/supervisees
-- This example assumes only 'manager' can be a supervisor, and only 'chatter' or 'model' can have a supervisor.
-- Adjust roles as per actual business logic.
-- This constraint might be too restrictive if, for example, an owner can also be a supervisor,
-- or if other roles can be supervised. For now, let's keep it flexible,
-- RLS will control who can SET the supervisor_id.
-- A more complex check could be:
-- CHECK (supervisor_id IS NULL OR ( (SELECT role FROM public.user_profiles WHERE id = supervisor_id) = 'manager' AND role IN ('chatter', 'model') ))
-- However, such checks involving subqueries in CHECK constraints can be complex and have performance implications.
-- We will rely on application logic and RLS to manage this correctly for now.
-- The owner, via RLS, is the only one who can set user_profiles.role and supervisor_id.

-- The existing RLS policy user_profiles_update already restricts updates to owners.
-- Owners will be responsible for setting valid supervisor_id values.
