ALTER TABLE public.user_preferences 
ADD COLUMN IF NOT EXISTS newsletter_optin BOOLEAN DEFAULT false;

DROP POLICY IF EXISTS "prefs_staff_select" ON user_preferences;
CREATE POLICY "prefs_staff_select"
    ON user_preferences FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('receptionist', 'admin')
        )
    );

UPDATE user_preferences
SET newsletter_optin = true
WHERE user_id IN (
    SELECT id FROM users WHERE role = 'patient'
);