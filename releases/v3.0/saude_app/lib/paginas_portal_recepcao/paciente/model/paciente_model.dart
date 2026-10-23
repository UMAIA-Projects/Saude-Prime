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
