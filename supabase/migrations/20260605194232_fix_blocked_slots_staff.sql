 
-- Corrigir bloqueios de horário pelo portal admin/receção
-- (mesmo padrão de appointments_staff_all)
 

-- Reforçar get_user_role (search_path explícito)
CREATE OR REPLACE FUNCTION public.get_user_role(uid UUID)
RETURNS public.user_role AS $$
  SELECT role
  FROM public.users
  WHERE id = uid
    AND deleted_at IS NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public;

REVOKE ALL ON FUNCTION public.get_user_role(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_user_role(UUID) TO authenticated;

-- Staff (admin + receção) gere bloqueios de qualquer médico
DROP POLICY IF EXISTS "blocked_slots_staff_all" ON blocked_slots;
CREATE POLICY "blocked_slots_staff_all"
ON blocked_slots FOR ALL TO authenticated
USING (
  public.get_user_role(auth.uid()) IN ('receptionist', 'admin')
)
WITH CHECK (
  public.get_user_role(auth.uid()) IN ('receptionist', 'admin')
);

-- Manter políticas admin explícitas (redundante mas claro)
DROP POLICY IF EXISTS "blocked_slots_admin_insert" ON blocked_slots;
CREATE POLICY "blocked_slots_admin_insert"
ON blocked_slots FOR INSERT TO authenticated
WITH CHECK (public.get_user_role(auth.uid()) = 'admin');

DROP POLICY IF EXISTS "blocked_slots_admin_update" ON blocked_slots;
CREATE POLICY "blocked_slots_admin_update"
ON blocked_slots FOR UPDATE TO authenticated
USING (public.get_user_role(auth.uid()) = 'admin')
WITH CHECK (public.get_user_role(auth.uid()) = 'admin');

DROP POLICY IF EXISTS "blocked_slots_admin_delete" ON blocked_slots;
CREATE POLICY "blocked_slots_admin_delete"
ON blocked_slots FOR DELETE TO authenticated
USING (public.get_user_role(auth.uid()) = 'admin');

-- RPC: inserir/eliminar bloqueio (contorna falhas de RLS no cliente admin)
CREATE OR REPLACE FUNCTION public.admin_insert_blocked_slot(
  p_doctor_id UUID,
  p_start TIMESTAMPTZ,
  p_end TIMESTAMPTZ,
  p_reason TEXT DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role public.user_role;
  v_id INTEGER;
BEGIN
  SELECT role INTO v_role
  FROM public.users
  WHERE id = auth.uid() AND deleted_at IS NULL;

  IF v_role NOT IN ('admin', 'receptionist') THEN
    RAISE EXCEPTION 'Sem permissão para bloquear horários';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.doctors WHERE user_id = p_doctor_id) THEN
    RAISE EXCEPTION 'Médico inválido';
  END IF;

  IF p_end <= p_start THEN
    RAISE EXCEPTION 'Intervalo de bloqueio inválido';
  END IF;

  INSERT INTO public.blocked_slots (doctor_id, start_datetime, end_datetime, reason)
  VALUES (p_doctor_id, p_start, p_end, NULLIF(trim(p_reason), ''))
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_delete_blocked_slot(p_id INTEGER)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role public.user_role;
BEGIN
  SELECT role INTO v_role
  FROM public.users
  WHERE id = auth.uid() AND deleted_at IS NULL;

  IF v_role NOT IN ('admin', 'receptionist') THEN
    RAISE EXCEPTION 'Sem permissão para eliminar bloqueios';
  END IF;

  DELETE FROM public.blocked_slots WHERE id = p_id;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_insert_blocked_slot(UUID, TIMESTAMPTZ, TIMESTAMPTZ, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_delete_blocked_slot(INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_insert_blocked_slot(UUID, TIMESTAMPTZ, TIMESTAMPTZ, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_delete_blocked_slot(INTEGER) TO authenticated;

