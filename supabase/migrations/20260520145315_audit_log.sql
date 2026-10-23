 
-- SOLUÇÃO: SINCRONIZAÇÃO DE USUÁRIOS E LOGS DE AUDITORIA
 
-- 1. Função para lidar com novos usuários do Supabase Auth
-- Esta função deve estar no schema public para ser acessível
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Inserir na tabela public.users (sincronização)
    INSERT INTO public.users (id, email, name, role)
    VALUES (
        NEW.id, 
        NEW.email, 
        COALESCE(NEW.raw_user_meta_data->>'name', 'Novo Usuário'),
        COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'patient'::user_role)
    );

    -- Criar log de auditoria para a criação do usuário
    INSERT INTO public.audit_log (action, target_user_id, target_type, description)
    VALUES (
        'USER_CREATED',
        NEW.id,
        'users',
        'Usuário criado via Supabase Auth: ' || NEW.email
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Trigger para disparar a função após a criação no auth.users
-- O trigger é criado na tabela interna do Supabase (auth.users)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 3. (Opcional) Trigger genérico para auditar outras tabelas
CREATE OR REPLACE FUNCTION public.audit_table_action()
RETURNS TRIGGER AS $$
DECLARE
    v_actor_id UUID := auth.uid();
BEGIN
    IF (TG_OP = 
'INSERT
') THEN
        INSERT INTO public.audit_log (actor_id, action, target_user_id, target_type, description)
        VALUES (v_actor_id, 
'INSERT
', NULL, TG_TABLE_NAME, 
'Inserção na tabela 
' || TG_TABLE_NAME);
        RETURN NEW;
    ELSIF (TG_OP = 
'UPDATE
') THEN
        INSERT INTO public.audit_log (actor_id, action, target_user_id, target_type, description)
        VALUES (v_actor_id, 
'UPDATE
', NULL, TG_TABLE_NAME, 
'Atualização na tabela 
' || TG_TABLE_NAME);
        RETURN NEW;
    ELSIF (TG_OP = 
'DELETE
') THEN
        INSERT INTO public.audit_log (actor_id, action, target_user_id, target_type, description)
        VALUES (v_actor_id, 
'DELETE
', NULL, TG_TABLE_NAME, 
'Remoção na tabela 
' || TG_TABLE_NAME);
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;