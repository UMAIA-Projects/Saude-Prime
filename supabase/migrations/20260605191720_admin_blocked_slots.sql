-- Permite que admins gerem bloqueios de horário de qualquer médico
-- (o portal admin bloqueia em nome do médico selecionado)

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