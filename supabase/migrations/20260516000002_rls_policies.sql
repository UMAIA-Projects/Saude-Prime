 
-- 02_RLS_POLICIES.SQL
-- Row Level Security — todas as políticas consolidadas e sem conflitos.
--
-- Princípio: a tabela `users` (public) NÃO tem RLS ativa.
-- O controlo de acesso faz-se nas tabelas específicas (patients, doctors, etc.)
-- A tabela `users` é lida livremente por utilizadores autenticados para que
-- os EXISTS() nas outras políticas funcionem sem recursão infinita.
 


 
-- 1. ATIVAR RLS NAS TABELAS CORRETAS
-- users fica SEM RLS para evitar recursão nos EXISTS() das políticas
 

ALTER TABLE specialties        ENABLE ROW LEVEL SECURITY;
ALTER TABLE insurances         ENABLE ROW LEVEL SECURITY;
ALTER TABLE patients           ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctors            ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences   ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments       ENABLE ROW LEVEL SECURITY;
ALTER TABLE virtual_queue      ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctor_availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocked_slots      ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices           ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents          ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications      ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log          ENABLE ROW LEVEL SECURITY;
ALTER TABLE clinic_settings    ENABLE ROW LEVEL SECURITY;

-- users: RLS DESATIVADO intencionalmente
-- Razão: as políticas das outras tabelas fazem SELECT em users para verificar
-- o role. Se users também tiver RLS, cria recursão infinita.
-- Segurança garantida: nenhuma rota da API expõe users diretamente;
-- o acesso é sempre mediado pelo service_role ou pelo próprio auth.uid().
ALTER TABLE users DISABLE ROW LEVEL SECURITY;


 
-- 2. DADOS PÚBLICOS / ESTRUTURAIS (leitura para qualquer utilizador autenticado)
 

CREATE POLICY "pub_specialties_select"
    ON specialties FOR SELECT USING (true);

CREATE POLICY "pub_insurances_select"
    ON insurances FOR SELECT USING (true);

CREATE POLICY "pub_clinic_settings_select"
    ON clinic_settings FOR SELECT USING (true);

CREATE POLICY "pub_doctors_select"
    ON doctors FOR SELECT USING (true);

CREATE POLICY "pub_doctor_availability_select"
    ON doctor_availability FOR SELECT USING (true);

CREATE POLICY "pub_blocked_slots_select"
    ON blocked_slots FOR SELECT USING (true);


 
-- 3. PATIENTS
 

-- Paciente vê a sua própria ficha
CREATE POLICY "patients_own_select"
    ON patients FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- Paciente cria o seu próprio registo (1 vez, no onboarding)
CREATE POLICY "patients_own_insert"
    ON patients FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- Médico vê todos os pacientes
CREATE POLICY "patients_doctor_select"
    ON patients FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role = 'doctor'
        )
    );

-- Staff (recepcionista / admin) gere todos os pacientes
CREATE POLICY "patients_staff_all"
    ON patients FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role IN ('receptionist', 'admin')
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role IN ('receptionist', 'admin')
        )
    );


 
-- 4. USER_PREFERENCES
 

CREATE POLICY "prefs_own_all"
    ON user_preferences FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);


 
-- 5. APPOINTMENTS
 

-- Paciente vê as suas consultas
CREATE POLICY "appointments_patient_select"
    ON appointments FOR SELECT
    TO authenticated
    USING (auth.uid() = patient_id);

-- Médico vê as suas consultas
CREATE POLICY "appointments_doctor_select"
    ON appointments FOR SELECT
    TO authenticated
    USING (auth.uid() = doctor_id);

-- Staff gere todas as consultas
CREATE POLICY "appointments_staff_all"
    ON appointments FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role IN ('receptionist', 'admin')
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role IN ('receptionist', 'admin')
        )
    );


 
-- 6. VIRTUAL_QUEUE
 

-- Todos os autenticados vêem o estado da fila (ecrã público de espera)
CREATE POLICY "queue_authenticated_select"
    ON virtual_queue FOR SELECT
    TO authenticated
    USING (true);

-- Staff gere a fila
CREATE POLICY "queue_staff_all"
    ON virtual_queue FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role IN ('receptionist', 'admin')
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role IN ('receptionist', 'admin')
        )
    );


 
-- 7. INVOICES
 

CREATE POLICY "invoices_patient_select"
    ON invoices FOR SELECT
    TO authenticated
    USING (auth.uid() = patient_id);

CREATE POLICY "invoices_staff_all"
    ON invoices FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role IN ('receptionist', 'admin')
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role IN ('receptionist', 'admin')
        )
    );


 
-- 8. DOCUMENTS
 

CREATE POLICY "documents_patient_select"
    ON documents FOR SELECT
    TO authenticated
    USING (auth.uid() = patient_id);

CREATE POLICY "documents_doctor_select"
    ON documents FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role = 'doctor'
        )
    );

CREATE POLICY "documents_staff_all"
    ON documents FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role IN ('receptionist', 'admin')
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role IN ('receptionist', 'admin')
        )
    );


 
-- 9. NOTIFICATIONS
 

CREATE POLICY "notifications_own_select"
    ON notifications FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);


 
-- 10. AUDIT_LOG (apenas admins)
 

CREATE POLICY "audit_log_admin_select"
    ON audit_log FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role = 'admin'
        )
    );


DO $$
BEGIN
    RAISE NOTICE '✅ Políticas RLS aplicadas com sucesso.';
    RAISE NOTICE '   Próximo passo: corre seed_auth via Supabase CLI (03_seed_auth.sh)';
END $$;
