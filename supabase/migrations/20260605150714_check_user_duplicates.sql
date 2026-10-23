-- Verificação fiável de duplicados (ignora RLS) para criação de utilizadores pelo admin
CREATE OR REPLACE FUNCTION public.check_new_user_duplicates(
  p_email TEXT,
  p_nif TEXT DEFAULT NULL,
  p_health_number TEXT DEFAULT NULL
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role public.user_role;
BEGIN
  SELECT role INTO v_role
  FROM public.users
  WHERE id = auth.uid() AND deleted_at IS NULL;

  IF v_role IS DISTINCT FROM 'admin' THEN
    RAISE EXCEPTION 'Apenas administradores podem criar utilizadores';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.users
    WHERE lower(trim(email)) = lower(trim(p_email))
      AND deleted_at IS NULL
  ) THEN
    RETURN 'email';
  END IF;

  IF p_nif IS NOT NULL AND trim(p_nif) <> '' AND EXISTS (
    SELECT 1
    FROM public.users
    WHERE trim(nif) = trim(p_nif)
      AND deleted_at IS NULL
  ) THEN
    RETURN 'nif';
  END IF;

  IF p_health_number IS NOT NULL AND trim(p_health_number) <> '' AND EXISTS (
    SELECT 1
    FROM public.patients p
    INNER JOIN public.users u ON u.id = p.user_id
    WHERE trim(p.health_number) = trim(p_health_number)
      AND u.deleted_at IS NULL
  ) THEN
    RETURN 'health_number';
  END IF;

  RETURN NULL;
END;
$$;

REVOKE ALL ON FUNCTION public.check_new_user_duplicates(TEXT, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_new_user_duplicates(TEXT, TEXT, TEXT) TO authenticated;
