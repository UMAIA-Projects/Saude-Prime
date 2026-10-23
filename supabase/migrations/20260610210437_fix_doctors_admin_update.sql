-- Adiciona política para permitir que administradores atualizem registos na tabela doctors
-- Isto é necessário para reativar médicos suspensos ou mudar a sua especialidade
DROP POLICY IF EXISTS "doctors_admin_update" ON public.doctors;
CREATE POLICY "doctors_admin_update" ON public.doctors 
FOR UPDATE TO authenticated
USING (public.get_user_role(auth.uid()) = 'admin')
WITH CHECK (public.get_user_role(auth.uid()) = 'admin');

-- Garantir que o admin também pode apagar se necessário (opcional mas recomendado para consistência)
DROP POLICY IF EXISTS "doctors_admin_delete" ON public.doctors;
CREATE POLICY "doctors_admin_delete" ON public.doctors 
FOR DELETE TO authenticated
USING (public.get_user_role(auth.uid()) = 'admin');
