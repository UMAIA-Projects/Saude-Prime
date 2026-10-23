-- Permite que admins criem registos de médicos
-- (necessário para o fluxo de criação de utilizadores pelo portal admin)
CREATE POLICY "doctors_admin_insert"
    ON doctors FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role = 'admin'
        )
    );
 