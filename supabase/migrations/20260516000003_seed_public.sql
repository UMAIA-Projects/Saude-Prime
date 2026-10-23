 
-- 03_SEED_PUBLIC.SQL  (versão expandida — ~30 rows por tabela principal)
--
-- Corre DEPOIS de:
--   1. 20260516000001_tabelas_iniciais.sql
--   2. 20260516000002_rls_policies.sql
--   3. seed_auth.js  ← os utilizadores auth têm de existir primeiro!
--
-- UUIDs fixos (coincidem com o seed_auth.js):
--   MEDICO_1   = 11111111-1111-1111-1111-111111111111
--   MEDICO_2   = 11111111-1111-1111-1111-111111111112
--   MEDICO_3   = 11111111-1111-1111-1111-111111111113
--   PACIENTE_1 = 22222222-2222-2222-2222-222222222221  (até ...229)
--   RECEPCAO   = 33333333-3333-3333-3333-333333333333
--   ADMIN      = 44444444-4444-4444-4444-444444444444
 


 
-- 1. ESPECIALIDADES (10)
 

INSERT INTO specialties (name) VALUES
    ('Medicina Geral e Familiar'),
    ('Cardiologia'),
    ('Ortopedia'),
    ('Dermatologia'),
    ('Pediatria'),
    ('Neurologia'),
    ('Oftalmologia'),
    ('Ginecologia'),
    ('Urologia'),
    ('Psiquiatria');


 
-- 2. SEGUROS (5)
 

INSERT INTO insurances (name, contact_email) VALUES
    ('Médis',        'parcerias@medis.pt'),
    ('AdvanceCare',  'parcerias@advancecare.pt'),
    ('Multicare',    'parcerias@multicare.pt'),
    ('Fidelidade',   'saude@fidelidade.pt'),
    ('Tranquilidade','saude@tranquilidade.pt');


 
-- 3. CONFIGURAÇÕES DA CLÍNICA
 

INSERT INTO clinic_settings (setting_key, setting_value, description) VALUES
    ('clinic_name',       'SaúdePrime',       'Nome da clínica'),
    ('clinic_phone',      '+351 220 000 000',  'Telefone principal'),
    ('slot_duration_min', '30',                'Duração padrão de consulta em minutos'),
    ('max_queue_size',    '50',                'Máximo de senhas na fila virtual');


 
-- 4. UTILIZADORES (3 médicos + 9 pacientes + recepcionista + admin = 14)
 

INSERT INTO users (id, email, name, role, nif, date_of_birth, phone) VALUES
    -- Médicos
    ('11111111-1111-1111-1111-111111111111', 'medico1@saudeprime.pt',   'Dr. João Silva',       'doctor',       '100000001', '1975-03-15', '+351 912 000 001'),
    ('11111111-1111-1111-1111-111111111112', 'medico2@saudeprime.pt',   'Dra. Carla Mendes',    'doctor',       '100000002', '1980-06-20', '+351 912 000 002'),
    ('11111111-1111-1111-1111-111111111113', 'medico3@saudeprime.pt',   'Dr. Rui Fonseca',      'doctor',       '100000003', '1972-11-08', '+351 912 000 003'),
    -- Pacientes
    ('22222222-2222-2222-2222-222222222221', 'paciente1@saudeprime.pt', 'Maria Santos',         'patient',      '200000001', '1990-07-22', '+351 912 001 001'),
    ('22222222-2222-2222-2222-222222222222', 'paciente2@saudeprime.pt', 'António Rodrigues',    'patient',      '200000002', '1985-02-14', '+351 912 001 002'),
    ('22222222-2222-2222-2222-222222222223', 'paciente3@saudeprime.pt', 'Sofia Pereira',        'patient',      '200000003', '1992-09-30', '+351 912 001 003'),
    ('22222222-2222-2222-2222-222222222224', 'paciente4@saudeprime.pt', 'Carlos Gomes',         'patient',      '200000004', '1968-04-17', '+351 912 001 004'),
    ('22222222-2222-2222-2222-222222222225', 'paciente5@saudeprime.pt', 'Inês Oliveira',        'patient',      '200000005', '1995-12-03', '+351 912 001 005'),
    ('22222222-2222-2222-2222-222222222226', 'paciente6@saudeprime.pt', 'Miguel Costa',         'patient',      '200000006', '1978-08-25', '+351 912 001 006'),
    ('22222222-2222-2222-2222-222222222227', 'paciente7@saudeprime.pt', 'Beatriz Ferreira',     'patient',      '200000007', '2000-01-11', '+351 912 001 007'),
    ('22222222-2222-2222-2222-222222222228', 'paciente8@saudeprime.pt', 'Luís Martins',         'patient',      '200000008', '1960-05-29', '+351 912 001 008'),
    ('22222222-2222-2222-2222-222222222229', 'paciente9@saudeprime.pt', 'Filipa Sousa',         'patient',      '200000009', '1988-10-16', '+351 912 001 009'),
    -- Staff
    ('33333333-3333-3333-3333-333333333333', 'recepcao@saudeprime.pt',  'Ana Ferreira',         'receptionist', '300000001', '1988-11-05', '+351 912 002 001'),
    ('44444444-4444-4444-4444-444444444444', 'admin@saudeprime.pt',     'Admin SaúdePrime',     'admin',        '400000001', '1985-01-10', '+351 912 002 002'),
    -- Equipa adicional
    ('55555555-5555-5555-5555-555555555551', 'ricardo@saudeprime.pt',   'Dr. Ricardo',          'doctor',       '500000001', '1983-04-12', '+351 912 003 001'),
    ('55555555-5555-5555-5555-555555555552', 'rodrigo@saudeprime.pt',   'Rodrigo',              'receptionist', '500000002', '1991-07-19', '+351 912 003 002'),
    ('55555555-5555-5555-5555-555555555553', 'marta@saudeprime.pt',     'Marta',                'patient',      '500000003', '1994-02-28', '+351 912 003 003'),
    ('55555555-5555-5555-5555-555555555554', 'juliana@saudeprime.pt',   'Dra. Juliana',         'doctor',       '500000004', '1979-09-03', '+351 912 003 004'),
    ('55555555-5555-5555-5555-555555555555', 'felipe@saudeprime.pt',    'Felipe',               'admin',        '500000005', '1987-06-15', '+351 912 003 005');


 
-- 5. MÉDICOS (3)
 

INSERT INTO doctors (user_id, specialty_id, license_number, default_slot_duration_min) VALUES
    ('11111111-1111-1111-1111-111111111111', 1, 'OM-10001', 30),  -- Medicina Geral
    ('11111111-1111-1111-1111-111111111112', 2, 'OM-10002', 30),  -- Cardiologia
    ('11111111-1111-1111-1111-111111111113', 4, 'OM-10003', 20),  -- Dermatologia
    ('55555555-5555-5555-5555-555555555551', 3, 'OM-10004', 30),  -- Ortopedia
    ('55555555-5555-5555-5555-555555555554', 6, 'OM-10005', 30);  -- Neurologia


 
-- 6. PACIENTES (9)
 

INSERT INTO patients (user_id, health_number, insurance_id) VALUES
    ('22222222-2222-2222-2222-222222222221', 'SNS-200000001', 1),
    ('22222222-2222-2222-2222-222222222222', 'SNS-200000002', 2),
    ('22222222-2222-2222-2222-222222222223', 'SNS-200000003', 1),
    ('22222222-2222-2222-2222-222222222224', 'SNS-200000004', 3),
    ('22222222-2222-2222-2222-222222222225', 'SNS-200000005', NULL),
    ('22222222-2222-2222-2222-222222222226', 'SNS-200000006', 4),
    ('22222222-2222-2222-2222-222222222227', 'SNS-200000227', NULL),
    ('22222222-2222-2222-2222-222222222228', 'SNS-200000008', 5),
    ('22222222-2222-2222-2222-222222222229', 'SNS-200000009', 2),
    ('55555555-5555-5555-5555-555555555553', 'SNS-500000003', NULL);


 
-- 7. PREFERÊNCIAS (todos os utilizadores)
 

INSERT INTO user_preferences (user_id) VALUES
    ('11111111-1111-1111-1111-111111111111'),
    ('11111111-1111-1111-1111-111111111112'),
    ('11111111-1111-1111-1111-111111111113'),
    ('22222222-2222-2222-2222-222222222221'),
    ('22222222-2222-2222-2222-222222222222'),
    ('22222222-2222-2222-2222-222222222223'),
    ('22222222-2222-2222-2222-222222222224'),
    ('22222222-2222-2222-2222-222222222225'),
    ('22222222-2222-2222-2222-222222222226'),
    ('22222222-2222-2222-2222-222222222227'),
    ('22222222-2222-2222-2222-222222222228'),
    ('22222222-2222-2222-2222-222222222229'),
    ('33333333-3333-3333-3333-333333333333'),
    ('44444444-4444-4444-4444-444444444444'),
    ('55555555-5555-5555-5555-555555555551'),
    ('55555555-5555-5555-5555-555555555552'),
    ('55555555-5555-5555-5555-555555555553'),
    ('55555555-5555-5555-5555-555555555554'),
    ('55555555-5555-5555-5555-555555555555');


 
-- 8. DISPONIBILIDADE DOS MÉDICOS
 

-- Médico 1: Segunda a Sexta
INSERT INTO doctor_availability (doctor_id, day_of_week, start_time, end_time, slot_duration_min) VALUES
    ('11111111-1111-1111-1111-111111111111', 1, '09:00', '13:00', 30),
    ('11111111-1111-1111-1111-111111111111', 1, '14:00', '17:00', 30),
    ('11111111-1111-1111-1111-111111111111', 2, '09:00', '13:00', 30),
    ('11111111-1111-1111-1111-111111111111', 3, '09:00', '13:00', 30),
    ('11111111-1111-1111-1111-111111111111', 4, '09:00', '13:00', 30),
    ('11111111-1111-1111-1111-111111111111', 5, '09:00', '12:00', 30);

-- Médico 2: Segunda, Terça, Quinta
INSERT INTO doctor_availability (doctor_id, day_of_week, start_time, end_time, slot_duration_min) VALUES
    ('11111111-1111-1111-1111-111111111112', 1, '10:00', '14:00', 30),
    ('11111111-1111-1111-1111-111111111112', 2, '10:00', '14:00', 30),
    ('11111111-1111-1111-1111-111111111112', 4, '10:00', '14:00', 30);

-- Médico 3: Terça e Sexta
INSERT INTO doctor_availability (doctor_id, day_of_week, start_time, end_time, slot_duration_min) VALUES
    ('11111111-1111-1111-1111-111111111113', 2, '08:00', '12:00', 20),
    ('11111111-1111-1111-1111-111111111113', 5, '08:00', '12:00', 20);


 
-- 9. CONSULTAS (30)
-- Distribuídas entre passado, hoje e futuro próximo.
 

INSERT INTO appointments (id, patient_id, doctor_id, scheduled_date, scheduled_time, duration_min, type, status, patient_notes, diagnosis_notes, created_by) VALUES

    -- Passado — completed / no_show / canceled
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222221', '11111111-1111-1111-1111-111111111111', CURRENT_DATE - 30, '09:00', 30, 'normal',    'completed', 'Dor abdominal',              'Gastrite leve. Dieta recomendada.',      '33333333-3333-3333-3333-333333333333'),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', CURRENT_DATE - 28, '09:30', 30, 'follow_up', 'completed', 'Revisão análises de sangue', 'Colesterol controlado.',                 '33333333-3333-3333-3333-333333333333'),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222223', '11111111-1111-1111-1111-111111111112', CURRENT_DATE - 25, '10:00', 30, 'normal',    'completed', 'Palpitações ocasionais',     'ECG normal. Vigilância.',                '33333333-3333-3333-3333-333333333333'),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222224', '11111111-1111-1111-1111-111111111113', CURRENT_DATE - 22, '08:00', 20, 'normal',    'completed', 'Mancha na pele',             'Queratose seborreica benigna.',           '33333333-3333-3333-3333-333333333333'),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222225', '11111111-1111-1111-1111-111111111111', CURRENT_DATE - 20, '10:30', 30, 'urgent',    'completed', 'Febre alta há 2 dias',       'Infeção respiratória. Antibiótico 7d.',  '33333333-3333-3333-3333-333333333333'),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222226', '11111111-1111-1111-1111-111111111112', CURRENT_DATE - 18, '11:00', 30, 'normal',    'no_show',   'Dor no peito',               NULL,                                     '33333333-3333-3333-3333-333333333333'),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222227', '11111111-1111-1111-1111-111111111111', CURRENT_DATE - 15, '09:00', 30, 'normal',    'completed', 'Consulta de rotina',         'Saudável.',                              '33333333-3333-3333-3333-333333333333'),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222228', '11111111-1111-1111-1111-111111111113', CURRENT_DATE - 14, '08:20', 20, 'follow_up', 'completed', 'Revisão tratamento acne',    'Boa resposta. Continuar 30 dias.',        '33333333-3333-3333-3333-333333333333'),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222229', '11111111-1111-1111-1111-111111111112', CURRENT_DATE - 12, '10:30', 30, 'normal',    'completed', 'Cansaço crónico',            'Anemia ferropénica. Suplementação.',     '33333333-3333-3333-3333-333333333333'),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222221', '11111111-1111-1111-1111-111111111112', CURRENT_DATE - 10, '11:00', 30, 'normal',    'canceled',  'Dor no peito esquerdo',      NULL,                                     '33333333-3333-3333-3333-333333333333'),

    (gen_random_uuid(), '22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111113', CURRENT_DATE - 9,  '08:00', 20, 'normal',    'completed', 'Irritação na pele',          'Dermatite de contacto. Creme prescrito.','33333333-3333-3333-3333-333333333333'),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222223', '11111111-1111-1111-1111-111111111111', CURRENT_DATE - 7,  '09:30', 30, 'normal',    'completed', 'Dores de cabeça frequentes', 'Enxaqueca tensional. Ibuprofeno SOS.',   '33333333-3333-3333-3333-333333333333'),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222224', '11111111-1111-1111-1111-111111111111', CURRENT_DATE - 5,  '10:00', 30, 'follow_up', 'completed', 'Revisão pós-cirurgia',       'Cicatrização sem complicações.',          '33333333-3333-3333-3333-333333333333'),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222225', '11111111-1111-1111-1111-111111111112', CURRENT_DATE - 4,  '10:00', 30, 'urgent',    'completed', 'Pressão arterial elevada',   'HTA grau I. Iniciar amlodipina 5mg.',    '33333333-3333-3333-3333-333333333333'),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222226', '11111111-1111-1111-1111-111111111113', CURRENT_DATE - 3,  '08:40', 20, 'normal',    'completed', 'Nevus novo no braço',        'Benigno. Fotografado para controlo.',    '33333333-3333-3333-3333-333333333333'),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222227', '11111111-1111-1111-1111-111111111111', CURRENT_DATE - 2,  '11:00', 30, 'normal',    'no_show',   'Tosse persistente',          NULL,                                     '33333333-3333-3333-3333-333333333333'),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222228', '11111111-1111-1111-1111-111111111112', CURRENT_DATE - 1,  '09:00', 30, 'follow_up', 'completed', 'Revisão ECG de esforço',     'ECG normal. Alta cardiológica.',         '33333333-3333-3333-3333-333333333333'),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222229', '11111111-1111-1111-1111-111111111111', CURRENT_DATE - 1,  '14:00', 30, 'normal',    'completed', 'Ansiedade e insónias',       'Ansiedade generalizada. Ref. psiq.',     '33333333-3333-3333-3333-333333333333'),

    -- Hoje — scheduled / em curso
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222221', '11111111-1111-1111-1111-111111111111', CURRENT_DATE, '09:00', 30, 'normal',    'scheduled', 'Renovação receita crónica',  NULL, '33333333-3333-3333-3333-333333333333'),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111112', CURRENT_DATE, '10:00', 30, 'normal',    'scheduled', 'Dor no peito ao esforço',    NULL, '33333333-3333-3333-3333-333333333333'),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222223', '11111111-1111-1111-1111-111111111113', CURRENT_DATE, '08:00', 20, 'urgent',    'scheduled', 'Reação alérgica na face',    NULL, '33333333-3333-3333-3333-333333333333'),

    -- Futuro
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222224', '11111111-1111-1111-1111-111111111111', CURRENT_DATE + 1,  '09:30', 30, 'normal',    'scheduled', 'Dores musculares',           NULL, '33333333-3333-3333-3333-333333333333'),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222225', '11111111-1111-1111-1111-111111111112', CURRENT_DATE + 2,  '10:00', 30, 'follow_up', 'scheduled', 'Revisão medicação HTA',      NULL, '33333333-3333-3333-3333-333333333333'),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222226', '11111111-1111-1111-1111-111111111113', CURRENT_DATE + 3,  '08:20', 20, 'normal',    'scheduled', 'Consulta de rotina pele',    NULL, '33333333-3333-3333-3333-333333333333'),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222227', '11111111-1111-1111-1111-111111111111', CURRENT_DATE + 4,  '11:00', 30, 'normal',    'scheduled', 'Febre recorrente',           NULL, '33333333-3333-3333-3333-333333333333'),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222228', '11111111-1111-1111-1111-111111111112', CURRENT_DATE + 5,  '10:30', 30, 'normal',    'scheduled', 'Arritmia benigna',           NULL, '33333333-3333-3333-3333-333333333333'),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222229', '11111111-1111-1111-1111-111111111113', CURRENT_DATE + 6,  '08:40', 20, 'follow_up', 'scheduled', 'Controlo nevus',             NULL, '33333333-3333-3333-3333-333333333333'),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222221', '11111111-1111-1111-1111-111111111112', CURRENT_DATE + 7,  '11:00', 30, 'normal',    'scheduled', 'Dor torácica ao repouso',    NULL, '33333333-3333-3333-3333-333333333333'),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', CURRENT_DATE + 10, '09:00', 30, 'normal',    'scheduled', 'Gripe persistente',          NULL, '33333333-3333-3333-3333-333333333333'),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222223', '11111111-1111-1111-1111-111111111111', CURRENT_DATE + 14, '10:00', 30, 'follow_up', 'scheduled', 'Revisão análises 3 meses',   NULL, '33333333-3333-3333-3333-333333333333');


 
-- 10. FILA VIRTUAL (10 entradas para hoje)
 

INSERT INTO virtual_queue (id, ticket_number, patient_id, doctor_id, status, queue_position, issued_at) VALUES
    (gen_random_uuid(), 'A001', '22222222-2222-2222-2222-222222222221', '11111111-1111-1111-1111-111111111111', 'attended', 1,  NOW() - INTERVAL '90 minutes'),
    (gen_random_uuid(), 'A002', '22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'attended', 2,  NOW() - INTERVAL '60 minutes'),
    (gen_random_uuid(), 'A003', '22222222-2222-2222-2222-222222222223', '11111111-1111-1111-1111-111111111111', 'called',   3,  NOW() - INTERVAL '30 minutes'),
    (gen_random_uuid(), 'A004', '22222222-2222-2222-2222-222222222224', '11111111-1111-1111-1111-111111111111', 'waiting',  4,  NOW() - INTERVAL '15 minutes'),
    (gen_random_uuid(), 'A005', '22222222-2222-2222-2222-222222222225', '11111111-1111-1111-1111-111111111111', 'waiting',  5,  NOW() - INTERVAL '10 minutes'),
    (gen_random_uuid(), 'B001', '22222222-2222-2222-2222-222222222226', '11111111-1111-1111-1111-111111111112', 'attended', 1,  NOW() - INTERVAL '80 minutes'),
    (gen_random_uuid(), 'B002', '22222222-2222-2222-2222-222222222227', '11111111-1111-1111-1111-111111111112', 'called',   2,  NOW() - INTERVAL '40 minutes'),
    (gen_random_uuid(), 'B003', '22222222-2222-2222-2222-222222222228', '11111111-1111-1111-1111-111111111112', 'waiting',  3,  NOW() - INTERVAL '5 minutes'),
    (gen_random_uuid(), 'C001', '22222222-2222-2222-2222-222222222223', '11111111-1111-1111-1111-111111111113', 'called',   1,  NOW() - INTERVAL '20 minutes'),
    (gen_random_uuid(), 'C002', '22222222-2222-2222-2222-222222222229', '11111111-1111-1111-1111-111111111113', 'waiting',  2,  NOW() - INTERVAL '8 minutes');


 
-- 11. FATURAS (15 — para consultas passadas)
 

DO $$
DECLARE
    patients UUID[] := ARRAY[
        '22222222-2222-2222-2222-222222222221'::UUID,
        '22222222-2222-2222-2222-222222222222'::UUID,
        '22222222-2222-2222-2222-222222222223'::UUID,
        '22222222-2222-2222-2222-222222222224'::UUID,
        '22222222-2222-2222-2222-222222222225'::UUID,
        '22222222-2222-2222-2222-222222222226'::UUID,
        '22222222-2222-2222-2222-222222222227'::UUID,
        '22222222-2222-2222-2222-222222222228'::UUID,
        '22222222-2222-2222-2222-222222222229'::UUID
    ];
    statuses invoice_status[] := ARRAY['paid','paid','paid','pending','paid','paid','pending','refunded','paid','paid','paid','paid','pending','paid','paid'];
    methods  payment_method[]  := ARRAY['card','cash','insurance','card','transfer','card','cash','card','insurance','transfer','card','cash','card','insurance','card'];
    amounts  DECIMAL[]         := ARRAY[25.00,40.00,55.00,25.00,40.00,30.00,25.00,55.00,40.00,25.00,30.00,40.00,55.00,25.00,40.00];
    i INT;
BEGIN
    FOR i IN 1..15 LOOP
        INSERT INTO invoices (id, patient_id, insurance_id, amount, tax_amount, status, payment_method, issued_at, paid_at, created_by)
        VALUES (
            gen_random_uuid(),
            patients[((i - 1) % array_length(patients, 1)) + 1],
            CASE WHEN i % 3 = 0 THEN (i % 5) + 1 ELSE NULL END,
            amounts[i],
            amounts[i] * 0.06,
            statuses[i],
            methods[i],
            NOW() - ((16 - i) || ' days')::INTERVAL,
            CASE WHEN statuses[i] = 'paid' THEN NOW() - ((16 - i) || ' days')::INTERVAL + INTERVAL '2 hours' ELSE NULL END,
            '44444444-4444-4444-4444-444444444444'
        );
    END LOOP;
END $$;


 
-- 12. NOTIFICAÇÕES (14 — uma por utilizador, mais algumas extra)
 

INSERT INTO notifications (id, user_id, type, message, is_read) VALUES
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222221', 'appointment_reminder', 'A sua consulta é amanhã às 09:30.', false),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222221', 'invoice_paid',         'Fatura #INV-001 foi paga.', true),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222222', 'appointment_reminder', 'A sua consulta é hoje às 10:00.', false),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222223', 'appointment_reminder', 'Consulta marcada para amanhã.', false),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222224', 'appointment_canceled', 'A sua consulta de ontem foi cancelada.', true),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222225', 'appointment_reminder', 'Consulta marcada para depois de amanhã.', false),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222226', 'queue_called',         'A sua vez está a chegar. Dirija-se à receção.', true),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222227', 'appointment_reminder', 'Tem consulta marcada esta semana.', false),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222228', 'invoice_pending',      'Tem uma fatura pendente.', false),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222229', 'appointment_reminder', 'Consulta marcada para 6ª feira.', false),
    (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'system',               'Agenda do dia carregada. 5 consultas.', true),
    (gen_random_uuid(), '11111111-1111-1111-1111-111111111112', 'system',               'Agenda do dia carregada. 3 consultas.', true),
    (gen_random_uuid(), '11111111-1111-1111-1111-111111111113', 'system',               'Agenda do dia carregada. 1 consulta urgente.', false),
    (gen_random_uuid(), '33333333-3333-3333-3333-333333333333', 'system',               '3 novos pacientes registados hoje.', false);


DO $$
BEGIN
    RAISE NOTICE 'Seed public (expandido) concluido com sucesso.';
    RAISE NOTICE '';
    RAISE NOTICE 'Resumo dos dados inseridos:';
    RAISE NOTICE '  10 especialidades';
    RAISE NOTICE '   5 seguros';
    RAISE NOTICE '  14 utilizadores (3 medicos, 9 pacientes, 1 recepcao, 1 admin)';
    RAISE NOTICE '  30 consultas (passado + hoje + futuro)';
    RAISE NOTICE '  10 entradas na fila virtual';
    RAISE NOTICE '  15 faturas';
    RAISE NOTICE '  14 notificacoes';
    RAISE NOTICE '';
    RAISE NOTICE 'Logins disponiveis (password: 12345678):';
    RAISE NOTICE '  medico1@saudeprime.pt  medico2@saudeprime.pt  medico3@saudeprime.pt';
    RAISE NOTICE '  paciente1..9@saudeprime.pt';
    RAISE NOTICE '  recepcao@saudeprime.pt';
    RAISE NOTICE '  admin@saudeprime.pt';
END $$;