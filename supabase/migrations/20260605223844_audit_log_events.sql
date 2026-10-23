 
-- Sistema de auditoria: função central + triggers para atividade recente
 

-- 1. Função central (SECURITY DEFINER — ignora RLS no INSERT)
CREATE OR REPLACE FUNCTION public.log_audit_event(
  p_action         TEXT,
  p_target_user_id UUID    DEFAULT NULL,
  p_target_type    TEXT    DEFAULT NULL,
  p_description    TEXT    DEFAULT NULL,
  p_actor_id       UUID    DEFAULT NULL
)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id BIGINT;
BEGIN
  INSERT INTO public.audit_log (actor_id, action, target_user_id, target_type, description)
  VALUES (
    COALESCE(p_actor_id, auth.uid()),
    p_action,
    p_target_user_id,
    p_target_type,
    p_description
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.log_audit_event(TEXT, UUID, TEXT, TEXT, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.log_audit_event(TEXT, UUID, TEXT, TEXT, UUID) TO authenticated;


-- 2. Índice para o dashboard (últimas entradas)
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at
  ON public.audit_log (created_at DESC);


-- 3. Trigger: alterações em utilizadores (soft delete, role, perfil)
CREATE OR REPLACE FUNCTION public.audit_users_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_name TEXT;
BEGIN
  v_name := COALESCE(NEW.name, NEW.email, 'utilizador');

  IF OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL THEN
    PERFORM public.log_audit_event(
      'USER_DELETED',
      NEW.id,
      'users',
      'Eliminou utilizador ' || v_name
    );
    RETURN NEW;
  END IF;

  IF OLD.role IS DISTINCT FROM NEW.role THEN
    PERFORM public.log_audit_event(
      'ROLE_CHANGED',
      NEW.id,
      'users',
      'Alterou role de ' || v_name || ' (' || OLD.role || ' → ' || NEW.role || ')'
    );
  END IF;

  IF OLD.deleted_at IS NULL
     AND NEW.deleted_at IS NULL
     AND (
       OLD.name IS DISTINCT FROM NEW.name
       OR OLD.phone IS DISTINCT FROM NEW.phone
       OR OLD.address IS DISTINCT FROM NEW.address
       OR OLD.nif IS DISTINCT FROM NEW.nif
     ) THEN
    PERFORM public.log_audit_event(
      'USER_UPDATED',
      NEW.id,
      'users',
      'Actualizou perfil de ' || v_name
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_users_changes ON public.users;
CREATE TRIGGER trg_audit_users_changes
  AFTER UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.audit_users_changes();


-- 4. Trigger: consultas (criar e mudar estado)
CREATE OR REPLACE FUNCTION public.audit_appointments_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_patient_name TEXT;
  v_doctor_name  TEXT;
BEGIN
  SELECT u.name INTO v_patient_name
  FROM public.users u
  WHERE u.id = NEW.patient_id;

  SELECT u.name INTO v_doctor_name
  FROM public.users u
  WHERE u.id = NEW.doctor_id;

  IF TG_OP = 'INSERT' THEN
    PERFORM public.log_audit_event(
      'APPOINTMENT_CREATED',
      NEW.patient_id,
      'appointments',
      'Marcou consulta para ' || COALESCE(v_patient_name, 'paciente')
        || ' com ' || COALESCE(v_doctor_name, 'médico')
        || ' em ' || NEW.scheduled_date
    );
  ELSIF TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status THEN
    PERFORM public.log_audit_event(
      'APPOINTMENT_STATUS_CHANGED',
      NEW.patient_id,
      'appointments',
      'Consulta de ' || COALESCE(v_patient_name, 'paciente')
        || ': ' || OLD.status || ' → ' || NEW.status
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_appointments_changes ON public.appointments;
CREATE TRIGGER trg_audit_appointments_changes
  AFTER INSERT OR UPDATE ON public.appointments
  FOR EACH ROW
  EXECUTE FUNCTION public.audit_appointments_changes();


-- 5. Trigger: criação de paciente/médico pelo staff (portal admin)
CREATE OR REPLACE FUNCTION public.audit_role_record_created()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_actor_role public.user_role;
  v_user_name  TEXT;
  v_role_label TEXT;
BEGIN
  SELECT role INTO v_actor_role
  FROM public.users
  WHERE id = auth.uid() AND deleted_at IS NULL;

  IF v_actor_role IS NULL OR v_actor_role NOT IN ('admin', 'receptionist') THEN
    RETURN NEW;
  END IF;

  SELECT name INTO v_user_name
  FROM public.users
  WHERE id = NEW.user_id;

  v_role_label := CASE TG_TABLE_NAME
    WHEN 'patients' THEN 'paciente'
    WHEN 'doctors'  THEN 'médico'
    ELSE 'utilizador'
  END;

  PERFORM public.log_audit_event(
    'USER_CREATED_BY_STAFF',
    NEW.user_id,
    TG_TABLE_NAME,
    'Criou ' || v_role_label || ' ' || COALESCE(v_user_name, 'sem nome')
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_patients_created ON public.patients;
CREATE TRIGGER trg_audit_patients_created
  AFTER INSERT ON public.patients
  FOR EACH ROW
  EXECUTE FUNCTION public.audit_role_record_created();

DROP TRIGGER IF EXISTS trg_audit_doctors_created ON public.doctors;
CREATE TRIGGER trg_audit_doctors_created
  AFTER INSERT ON public.doctors
  FOR EACH ROW
  EXECUTE FUNCTION public.audit_role_record_created();


-- 6. Trigger: senhas na fila virtual
CREATE OR REPLACE FUNCTION public.audit_virtual_queue_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_patient_name TEXT;
  v_doctor_name  TEXT;
BEGIN
  SELECT name INTO v_patient_name FROM public.users WHERE id = NEW.patient_id;
  SELECT name INTO v_doctor_name  FROM public.users WHERE id = NEW.doctor_id;

  PERFORM public.log_audit_event(
    'QUEUE_TICKET_ISSUED',
    NEW.patient_id,
    'virtual_queue',
    'Senha ' || NEW.ticket_number
      || ' para ' || COALESCE(v_patient_name, 'paciente')
      || ' (' || COALESCE(v_doctor_name, 'médico') || ')'
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_virtual_queue_insert ON public.virtual_queue;
CREATE TRIGGER trg_audit_virtual_queue_insert
  AFTER INSERT ON public.virtual_queue
  FOR EACH ROW
  EXECUTE FUNCTION public.audit_virtual_queue_insert();


-- 7. Actualizar handle_new_user para usar log_audit_event
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role user_role;
  v_name TEXT;
BEGIN
  BEGIN
    v_role := (NEW.raw_user_meta_data->>'role')::user_role;
  EXCEPTION WHEN OTHERS THEN
    v_role := 'patient'::user_role;
  END;

  v_name := COALESCE(NEW.raw_user_meta_data->>'name', 'Novo Utilizador');

  INSERT INTO public.users (id, email, name, role)
  VALUES (NEW.id, NEW.email, v_name, v_role)
  ON CONFLICT (id) DO UPDATE
  SET
    email = EXCLUDED.email,
    name  = EXCLUDED.name,
    role  = EXCLUDED.role;

  PERFORM public.log_audit_event(
    'USER_CREATED',
    NEW.id,
    'users',
    'Utilizador registado: ' || v_name || ' (' || NEW.email || ')'
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
