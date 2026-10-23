-- Permite que a receção crie novos utilizadores na tabela public.users
-- Restrição: A receção só pode criar utilizadores com o cargo 'patient'
DROP POLICY IF EXISTS "users_receptionist_insert_patient" ON public.users;
CREATE POLICY "users_receptionist_insert_patient" ON public.users 
FOR INSERT TO authenticated
WITH CHECK (
    public.get_user_role(auth.uid()) = 'receptionist' 
    AND role = 'patient'
);

-- Permite que a receção atualize dados de pacientes
DROP POLICY IF EXISTS "users_receptionist_update_patient" ON public.users;
CREATE POLICY "users_receptionist_update_patient" ON public.users 
FOR UPDATE TO authenticated
USING (
    public.get_user_role(auth.uid()) = 'receptionist' 
    AND role = 'patient'
)
WITH CHECK (
    public.get_user_role(auth.uid()) = 'receptionist' 
    AND role = 'patient'
);

-- Garantir que a receção pode inserir em user_preferences
DROP POLICY IF EXISTS "prefs_receptionist_insert" ON public.user_preferences;
CREATE POLICY "prefs_receptionist_insert" ON public.user_preferences 
FOR INSERT TO authenticated
WITH CHECK (public.get_user_role(auth.uid()) = 'receptionist');
