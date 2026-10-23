 
-- VERSÃO ROBUSTA: EVITA ERROS NO SIGNUP DO SUPABASE
 

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_role user_role;
    v_name TEXT;
BEGIN
    -- 1. Extrair e validar o role (garante que não quebre se o metadado for inválido)
    BEGIN
        v_role := (NEW.raw_user_meta_data->>'role')::user_role;
    EXCEPTION WHEN OTHERS THEN
        v_role := 'patient'::user_role; -- Fallback seguro
    END;

    -- 2. Extrair o nome
    v_name := COALESCE(NEW.raw_user_meta_data->>'name', 'Novo Usuário');

    -- 3. Inserir ou Atualizar (UPSERT) para evitar erro de "Duplicate Key"
    INSERT INTO public.users (id, email, name, role)
    VALUES (NEW.id, NEW.email, v_name, v_role)
    ON CONFLICT (id) DO UPDATE 
    SET 
        email = EXCLUDED.email,
        name = EXCLUDED.name,
        role = EXCLUDED.role;

    -- 4. Criar log de auditoria
    INSERT INTO public.audit_log (action, target_user_id, target_type, description)
    VALUES (
        'USER_CREATED',
        NEW.id,
        'users',
        'Usuário processado via Supabase Auth: ' || NEW.email
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Re-aplicar o trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();