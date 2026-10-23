-- POLÍTICAS RLS — UPDATE em appointments para pacientes
--
-- SEM ESTA MIGRATION, o Supabase bloqueia TODOS os UPDATE feitos pelo
-- paciente autenticado, sem lançar erro — simplesmente não escreve nada.
-- Isto afecta reagendar e cancelar consultas no portal do paciente.

-- 1. Reagendar
-- O paciente pode alterar data/hora de uma consulta sua com status 'scheduled'.
CREATE POLICY "Paciente pode reagendar a sua consulta"
ON public.appointments
FOR UPDATE
TO authenticated
USING (
    auth.uid() = patient_id
    AND status = 'scheduled'
)
WITH CHECK (
    auth.uid() = patient_id
);

-- 2. Cancelar 
-- O paciente pode cancelar uma consulta sua que ainda esteja em 'scheduled'.
-- (UPDATE de status → 'canceled')
CREATE POLICY "Paciente pode cancelar a sua consulta"
ON public.appointments
FOR UPDATE
TO authenticated
USING (
    auth.uid() = patient_id
    AND status IN ('scheduled', 'no_show')
)
WITH CHECK (
    auth.uid() = patient_id
    AND status = 'canceled'
);