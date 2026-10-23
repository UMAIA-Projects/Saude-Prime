 
-- MIGRATION: RESOLVER RECURSÃO RLS NA TABELA USERS
 

-- PASSO 1: CRIAR A FUNÇÃO "CHAVE MESTRA" (Ignora o RLS para ver o cargo)

CREATE OR REPLACE FUNCTION public.get_user_role(uid UUID)
RETURNS public.user_role AS $$
  SELECT role FROM public.users WHERE id = uid;
$$ LANGUAGE sql SECURITY DEFINER;

-- Garantir segurança da função
REVOKE ALL ON FUNCTION public.get_user_role(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_user_role(UUID) TO authenticated;


-- PASSO 2: ATUALIZAR AS POLÍTICAS EXISTENTES (Substituir pela função)

-- Tabela: PATIENTS
DROP POLICY IF EXISTS "patients_doctor_select" ON patients;
CREATE POLICY "patients_doctor_select" ON patients FOR SELECT TO authenticated 
USING (public.get_user_role(auth.uid()) = 'doctor');

DROP POLICY IF EXISTS "patients_staff_all" ON patients;
CREATE POLICY "patients_staff_all" ON patients FOR ALL TO authenticated
USING (public.get_user_role(auth.uid()) IN ('receptionist', 'admin'))
WITH CHECK (public.get_user_role(auth.uid()) IN ('receptionist', 'admin'));

-- Tabela: APPOINTMENTS
DROP POLICY IF EXISTS "appointments_staff_all" ON appointments;
CREATE POLICY "appointments_staff_all" ON appointments FOR ALL TO authenticated
USING (public.get_user_role(auth.uid()) IN ('receptionist', 'admin'))
WITH CHECK (public.get_user_role(auth.uid()) IN ('receptionist', 'admin'));

DROP POLICY IF EXISTS "appointments_doctor_insert" ON appointments;
CREATE POLICY "appointments_doctor_insert" ON appointments FOR INSERT TO authenticated
WITH CHECK (
    auth.uid() = doctor_id 
    AND public.get_user_role(auth.uid()) = 'doctor' 
    AND EXISTS (SELECT 1 FROM doctors WHERE doctors.user_id = auth.uid())
);

-- Tabela: VIRTUAL_QUEUE
DROP POLICY IF EXISTS "queue_staff_all" ON virtual_queue;
CREATE POLICY "queue_staff_all" ON virtual_queue FOR ALL TO authenticated
USING (public.get_user_role(auth.uid()) IN ('receptionist', 'admin'))
WITH CHECK (public.get_user_role(auth.uid()) IN ('receptionist', 'admin'));

-- Tabela: INVOICES
DROP POLICY IF EXISTS "invoices_staff_all" ON invoices;
CREATE POLICY "invoices_staff_all" ON invoices FOR ALL TO authenticated
USING (public.get_user_role(auth.uid()) IN ('receptionist', 'admin'))
WITH CHECK (public.get_user_role(auth.uid()) IN ('receptionist', 'admin'));

-- Tabela: DOCUMENTS
DROP POLICY IF EXISTS "documents_doctor_select" ON documents;
CREATE POLICY "documents_doctor_select" ON documents FOR SELECT TO authenticated 
USING (public.get_user_role(auth.uid()) = 'doctor');

DROP POLICY IF EXISTS "documents_staff_all" ON documents;
CREATE POLICY "documents_staff_all" ON documents FOR ALL TO authenticated
USING (public.get_user_role(auth.uid()) IN ('receptionist', 'admin'))
WITH CHECK (public.get_user_role(auth.uid()) IN ('receptionist', 'admin'));

DROP POLICY IF EXISTS "documents_doctor_insert" ON documents;
CREATE POLICY "documents_doctor_insert" ON documents FOR INSERT TO authenticated
WITH CHECK (public.get_user_role(auth.uid()) = 'doctor' AND uploaded_by = auth.uid());

-- Tabela: AUDIT_LOG
DROP POLICY IF EXISTS "audit_log_admin_select" ON audit_log;
CREATE POLICY "audit_log_admin_select" ON audit_log FOR SELECT TO authenticated 
USING (public.get_user_role(auth.uid()) = 'admin');

-- Tabela: BLOCKED_SLOTS
DROP POLICY IF EXISTS "blocked_slots_doctor_insert" ON blocked_slots;
CREATE POLICY "blocked_slots_doctor_insert" ON blocked_slots FOR INSERT TO authenticated
WITH CHECK (auth.uid() = doctor_id AND public.get_user_role(auth.uid()) = 'doctor');

-- Tabela: USER_PREFERENCES
DROP POLICY IF EXISTS "prefs_staff_insert" ON user_preferences;
CREATE POLICY "prefs_staff_insert" ON user_preferences FOR INSERT TO authenticated
WITH CHECK (public.get_user_role(auth.uid()) IN ('receptionist', 'admin'));

DROP POLICY IF EXISTS "prefs_staff_select" ON user_preferences;
CREATE POLICY "prefs_staff_select" ON user_preferences FOR SELECT TO authenticated
USING (public.get_user_role(auth.uid()) IN ('receptionist', 'admin'));

-- Tabela: DOCTORS
DROP POLICY IF EXISTS "doctors_admin_insert" ON doctors;
CREATE POLICY "doctors_admin_insert" ON doctors FOR INSERT TO authenticated
WITH CHECK (public.get_user_role(auth.uid()) = 'admin');

-- STORAGE (Documentos PDF)
DROP POLICY IF EXISTS "patient_documents_doctor_insert" ON storage.objects;
CREATE POLICY "patient_documents_doctor_insert" ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'patient-documents' AND public.get_user_role(auth.uid()) = 'doctor');

DROP POLICY IF EXISTS "patient_documents_staff_insert" ON storage.objects;
CREATE POLICY "patient_documents_staff_insert" ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'patient-documents' AND public.get_user_role(auth.uid()) IN ('receptionist', 'admin'));

DROP POLICY IF EXISTS "patient_documents_doctor_select" ON storage.objects;
CREATE POLICY "patient_documents_doctor_select" ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'patient-documents' AND public.get_user_role(auth.uid()) IN ('doctor', 'receptionist', 'admin'));


-- PASSO 3: ATIVAR O RLS NA TABELA USERS

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- PASSO 4: CRIAR AS POLÍTICAS DE ACESSO PARA A TABELA USERS

-- 1. Toda a gente precisa de conseguir ler a tabela users (para ver nomes dos médicos, etc)
CREATE POLICY "users_read_all" ON public.users 
FOR SELECT TO authenticated USING (true);

-- 2. Cada pessoa pode atualizar apenas a sua própria informação
CREATE POLICY "users_own_update" ON public.users 
FOR UPDATE TO authenticated 
USING (auth.uid() = id) 
WITH CHECK (auth.uid() = id);

-- 3. O Admin tem acesso total (Ler, Criar, Atualizar, Apagar) a todos os users
CREATE POLICY "users_admin_all" ON public.users 
FOR ALL TO authenticated 
USING (public.get_user_role(auth.uid()) = 'admin') 
WITH CHECK (public.get_user_role(auth.uid()) = 'admin');