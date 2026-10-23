-- 1. Remover o trigger criado na tabela interna do Supabase
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 2. Remover a função que processava os novos utilizadores
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 3. Remover a função genérica de auditoria de tabelas
DROP FUNCTION IF EXISTS public.audit_table_action();