-- Adiciona a coluna suspended à tabela doctors
ALTER TABLE public.doctors 
ADD COLUMN suspended BOOLEAN NOT NULL DEFAULT FALSE;

-- Comentário explicativo
COMMENT ON COLUMN public.doctors.suspended IS 'Indica se o médico está suspenso (ex: mudou de cargo) e não deve aparecer para novas marcações.';
