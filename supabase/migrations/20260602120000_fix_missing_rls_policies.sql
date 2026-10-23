
-- MIGRATION: CORRIGIR POLÍTICAS RLS EM FALTA
-- Data: 2026-06-02
-- Resolve:
--   • Fila virtual do médico (SELECT + UPDATE em virtual_queue)
--   • Abandonar fila do paciente (UPDATE em virtual_queue)
--   • Bloquear horários — lista não carregava (SELECT em blocked_slots)
--   • Gestão de disponibilidade do médico (INSERT/UPDATE/DELETE em doctor_availability)
--   • Configurar fila virtual / Dados da clínica (UPDATE/INSERT em clinic_settings)



-- 1. VIRTUAL_QUEUE — médico

-- O médico precisa de VER as senhas da sua fila
DROP POLICY IF EXISTS "queue_doctor_select" ON virtual_queue;
CREATE POLICY "queue_doctor_select"
ON virtual_queue FOR SELECT TO authenticated
USING (
    doctor_id = auth.uid()
    AND public.get_user_role(auth.uid()) = 'doctor'
);

-- O médico precisa de ATUALIZAR o estado das senhas (chamar, marcar atendido, ausente)
DROP POLICY IF EXISTS "queue_doctor_update" ON virtual_queue;
CREATE POLICY "queue_doctor_update"
ON virtual_queue FOR UPDATE TO authenticated
USING (
    doctor_id = auth.uid()
    AND public.get_user_role(auth.uid()) = 'doctor'
)
WITH CHECK (
    doctor_id = auth.uid()
);


-- 2. VIRTUAL_QUEUE — paciente

-- O paciente precisa de ATUALIZAR a sua senha para abandonar a fila (status → 'absent')
DROP POLICY IF EXISTS "queue_patient_update_own" ON virtual_queue;
CREATE POLICY "queue_patient_update_own"
ON virtual_queue FOR UPDATE TO authenticated
USING (
    patient_id = auth.uid()
    AND public.get_user_role(auth.uid()) = 'patient'
)
WITH CHECK (
    patient_id = auth.uid()
);


-- 3. BLOCKED_SLOTS — médico (SELECT em falta)
-- Os INSERT/UPDATE/DELETE já existem. Só faltava o SELECT para listar bloqueios.

DROP POLICY IF EXISTS "blocked_slots_doctor_select" ON blocked_slots;
CREATE POLICY "blocked_slots_doctor_select"
ON blocked_slots FOR SELECT TO authenticated
USING (
    doctor_id = auth.uid()
    AND public.get_user_role(auth.uid()) = 'doctor'
);


-- 4. DOCTOR_AVAILABILITY — médico
-- O SELECT público (pub_doctor_availability_select) já existe para booking.
-- O médico precisa de gerir a sua própria disponibilidade.

DROP POLICY IF EXISTS "availability_doctor_select" ON doctor_availability;
CREATE POLICY "availability_doctor_select"
ON doctor_availability FOR SELECT TO authenticated
USING (
    doctor_id = auth.uid()
    AND public.get_user_role(auth.uid()) = 'doctor'
);

DROP POLICY IF EXISTS "availability_doctor_insert" ON doctor_availability;
CREATE POLICY "availability_doctor_insert"
ON doctor_availability FOR INSERT TO authenticated
WITH CHECK (
    doctor_id = auth.uid()
    AND public.get_user_role(auth.uid()) = 'doctor'
);

DROP POLICY IF EXISTS "availability_doctor_update" ON doctor_availability;
CREATE POLICY "availability_doctor_update"
ON doctor_availability FOR UPDATE TO authenticated
USING (
    doctor_id = auth.uid()
    AND public.get_user_role(auth.uid()) = 'doctor'
)
WITH CHECK (
    doctor_id = auth.uid()
);

DROP POLICY IF EXISTS "availability_doctor_delete" ON doctor_availability;
CREATE POLICY "availability_doctor_delete"
ON doctor_availability FOR DELETE TO authenticated
USING (
    doctor_id = auth.uid()
    AND public.get_user_role(auth.uid()) = 'doctor'
);


-- 5. CLINIC_SETTINGS — admin
-- O SELECT público (pub_clinic_settings_select) já existe.
-- O admin precisa de poder editar as definições da clínica.

DROP POLICY IF EXISTS "clinic_settings_admin_all" ON clinic_settings;
CREATE POLICY "clinic_settings_admin_all"
ON clinic_settings FOR ALL TO authenticated
USING (
    public.get_user_role(auth.uid()) = 'admin'
)
WITH CHECK (
    public.get_user_role(auth.uid()) = 'admin'
);
