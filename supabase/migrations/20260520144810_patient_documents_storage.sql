-- Bucket de documentos clínicos (PDF / imagens)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'patient-documents',
    'patient-documents',
    false,
    10485760, -- 10 MB
    ARRAY['application/pdf', 'image/png', 'image/jpeg', 'image/jpg']
)
ON CONFLICT (id) DO NOTHING;

-- Storage: upload 
CREATE POLICY "patient_documents_doctor_insert"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'patient-documents'
        AND EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role = 'doctor'
        )
    );

CREATE POLICY "patient_documents_staff_insert"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'patient-documents'
        AND EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role IN ('receptionist', 'admin')
        )
    );

-- Storage: leitura 
CREATE POLICY "patient_documents_doctor_select"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'patient-documents'
        AND EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role IN ('doctor', 'receptionist', 'admin')
        )
    );

CREATE POLICY "patient_documents_patient_select"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'patient-documents'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Tabela documents: médicos podem inserir
CREATE POLICY "documents_doctor_insert"
    ON documents FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role = 'doctor'
        )
        AND uploaded_by = auth.uid()
    );