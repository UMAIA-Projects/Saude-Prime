// lib/paciente/models/paciente_model.dart

class PacienteModel {
  final String id;
  final String nome;
  final String nif;
  final String dataNasc;
  final String telemovel;
  final String sns;
  final String morada;
  final String email;

  const PacienteModel({
    required this.id,
    required this.nome,
    required this.nif,
    required this.dataNasc,
    required this.telemovel,
    required this.sns,
    required this.morada,
    required this.email,
  });
}

class ConsultaModel {
  final String data;
  final String medico;
  final String tipo;
  final String status; // 'Concluída' | 'Faltou' | 'Agendada'

  const ConsultaModel({
    required this.data,
    required this.medico,
    required this.tipo,
    required this.status,
  });
}

// ---------------------------------------------------------------------------
// Dados estáticos (mock)
// ---------------------------------------------------------------------------

const pacienteMock = PacienteModel(
  id: '001',
  nome: 'Aníbal Carvalho Oliveira',
  nif: '222 222 222',
  dataNasc: '03/11/1956',
  telemovel: '910 000 000',
  sns: '000000001',
  morada: 'Rua Santana, 17, Mafamude',
  email: 'anibal.oliveira@email.pt',
);

const consultasMock = [
  ConsultaModel(
    data: '12/03/2025',
    medico: 'Dr. Menezes',
    tipo: 'Consulta Geral',
    status: 'Concluída',
  ),
  ConsultaModel(
    data: '05/01/2025',
    medico: 'Dra. Mendes',
    tipo: 'Cardiologia',
    status: 'Concluída',
  ),
  ConsultaModel(
    data: '18/11/2024',
    medico: 'Dr. Menezes',
    tipo: 'Consulta Geral',
    status: 'Faltou',
  ),
  ConsultaModel(
    data: '02/09/2024',
    medico: 'Dr. Antunes',
    tipo: 'Ortopedia',
    status: 'Concluída',
  ),
];
