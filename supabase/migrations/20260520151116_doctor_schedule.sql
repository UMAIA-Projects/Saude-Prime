CREATE POLICY "appointments_doctor_insert"
    ON appointments FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() = doctor_id
        AND EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role = 'doctor'
        )
        AND EXISTS (
            SELECT 1 FROM doctors
            WHERE doctors.user_id = auth.uid()
        )
    );

CREATE POLICY "appointments_doctor_update"
    ON appointments FOR UPDATE
    TO authenticated
    USING (auth.uid() = doctor_id)
    WITH CHECK (auth.uid() = doctor_id);

CREATE POLICY "blocked_slots_doctor_insert"
    ON blocked_slots FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() = doctor_id
        AND EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role = 'doctor'
        )
    );

CREATE POLICY "blocked_slots_doctor_update"
    ON blocked_slots FOR UPDATE
    TO authenticated
    USING (auth.uid() = doctor_id)
    WITH CHECK (auth.uid() = doctor_id);

CREATE POLICY "blocked_slots_doctor_delete"
    ON blocked_slots FOR DELETE
    TO authenticated
    USING (auth.uid() = doctor_id);