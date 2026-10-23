CREATE POLICY "users_insert_own"
ON users FOR INSERT TO authenticated
WITH CHECK (
    id = auth.uid()
);