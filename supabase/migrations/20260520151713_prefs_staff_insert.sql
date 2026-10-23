-- Permite que rececionistas e admins criem preferências para novos utentes
CREATE POLICY "prefs_staff_insert"
    ON user_preferences FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role IN ('receptionist', 'admin')
        )
    );