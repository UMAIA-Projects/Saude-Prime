 
-- REVERT: desfaz 20260605194232_fix_blocked_slots_staff.sql
 

-- Remover funções RPC criadas
DROP FUNCTION IF EXISTS public.admin_insert_blocked_slot(UUID, TIMESTAMPTZ, TIMESTAMPTZ, TEXT);
DROP FUNCTION IF EXISTS public.admin_delete_blocked_slot(INTEGER);

-- Remover políticas criadas/alteradas nessa migration
DROP POLICY IF EXISTS "blocked_slots_staff_all" ON blocked_slots;
DROP POLICY IF EXISTS "blocked_slots_admin_insert" ON blocked_slots;
DROP POLICY IF EXISTS "blocked_slots_admin_update" ON blocked_slots;
DROP POLICY IF EXISTS "blocked_slots_admin_delete" ON blocked_slots;

-- Restaurar get_user_role ao estado anterior (20260531201248_redo_policies.sql)
CREATE OR REPLACE FUNCTION public.get_user_role(uid UUID)
RETURNS public.user_role AS $$
  SELECT role FROM public.users WHERE id = uid;
$$ LANGUAGE sql SECURITY DEFINER;

REVOKE ALL ON FUNCTION public.get_user_role(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_user_role(UUID) TO authenticated;
