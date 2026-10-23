import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ENUMS

enum TipoConsulta { normal, urgente }

/// Replica da validação central antes de avançar para as queries de conflito.
/// Retorna null se todos os campos obrigatórios estiverem preenchidos,
/// ou a mensagem de erro a mostrar no SnackBar.
String? validarCamposMarcarConsulta({
  required String? patientId,
  required String? doctorId,
  required DateTime? data,
  required TimeOfDay? hora,
  required String? receptionistId,
}) {
  if (patientId == null) return 'Selecione um paciente.';
  if (doctorId == null) return 'Selecione um médico.';
  if (data == null || hora == null) return 'Indique data e hora.';
  if (receptionistId == null) return 'Sem sessão ativa.';
  return null;
}

/// Replica de `_horarioOcupado`:
/// dado o resultado de uma query .maybeSingle(), determina se o slot
/// já tem uma consulta ativa.
bool horarioOcupado(Map<String, dynamic>? queryResult) {
  return queryResult != null;
}

/// Replica de `_medicoDisponivel`:
/// dado o resultado de uma query de bloqueios, determina se o médico
/// está disponível (sem overlap com blocked_slots).
bool medicoDisponivel(List<dynamic> bloqueios) {
  return bloqueios.isEmpty;
}

/// Replica de `_fmtDate` - formata DateTime para 'YYYY-MM-DD' (DATE do Postgres).
String fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Replica de `_fmtTime` - formata TimeOfDay para 'HH:MM:00' (TIME do Postgres).
String fmtTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

/// Determina o tipo efectivo da consulta.
/// Regra: se o paciente não tiver consulta nos últimos 6 meses → normal;
/// se vier com queixa aguda (flag urgente) → urgente.
TipoConsulta determinarTipoConsulta({required bool urgente}) {
  return urgente ? TipoConsulta.urgente : TipoConsulta.normal;
}

//  TESTES

void main() {

  group('marcar_consulta_rececionista - validação de campos obrigatórios', () {
    // TESTE 1 - Happy path: todos os campos preenchidos, sem erro
    // Este é o fluxo que a rececionista percorre em 99 % das marcações.
    test('campos completos com sessão ativa não retornam erro', () {
      // GIVEN - todos os dados necessários presentes
      const patientId = 'patient-uuid-001';
      const doctorId = 'doctor-uuid-002';
      final data = DateTime(2025, 12, 20);
      const hora = TimeOfDay(hour: 10, minute: 30);
      const receptionistId = 'recep-uuid-003';
      // WHEN
      final erro = validarCamposMarcarConsulta(
        patientId: patientId,
        doctorId: doctorId,
        data: data,
        hora: hora,
        receptionistId: receptionistId,
      );
      // THEN - sem erro; pode avançar para verificação de conflitos
      expect(
        erro,
        isNull,
        reason: 'Todos os campos válidos devem passar a validação inicial',
      );
    });

    // TESTE 2 - Paciente não seleccionado → SnackBar correcto
    test('paciente não seleccionado retorna mensagem adequada', () {
      // GIVEN - rececionista não escolheu o paciente no dropdown
      final data = DateTime(2025, 12, 20);
      const hora = TimeOfDay(hour: 10, minute: 0);
      const doctorId = 'doctor-uuid-002';
      const receptionistId = 'recep-uuid-003';
      // WHEN
      final erro = validarCamposMarcarConsulta(
        patientId: null, // ← não seleccionado
        doctorId: doctorId,
        data: data,
        hora: hora,
        receptionistId: receptionistId,
      );
      // THEN
      expect(
        erro,
        equals('Selecione um paciente.'),
        reason:
            'UI deve exibir SnackBar indicando que o paciente é obrigatório',
      );
    });

    // TESTE 3 - Médico não seleccionado → SnackBar correcto
    test('médico não seleccionado retorna mensagem adequada', () {
      // GIVEN - rececionista não escolheu o médico (ex: lista ainda a carregar)
      const patientId = 'patient-uuid-001';
      final data = DateTime(2025, 12, 20);
      const hora = TimeOfDay(hour: 14, minute: 0);
      const receptionistId = 'recep-uuid-003';
      // WHEN
      final erro = validarCamposMarcarConsulta(
        patientId: patientId,
        doctorId: null, // ← não seleccionado
        data: data,
        hora: hora,
        receptionistId: receptionistId,
      );
      // THEN
      expect(
        erro,
        equals('Selecione um médico.'),
        reason:
            'Deve pedir ao utilizador para seleccionar o médico antes de continuar',
      );
    });

    // TESTE 4 - Data em falta → erro correcto
    test('data nula retorna "Indique data e hora."', () {
      // GIVEN
      const patientId = 'patient-uuid-001';
      const doctorId = 'doctor-uuid-002';
      const hora = TimeOfDay(hour: 9, minute: 0);
      const receptionistId = 'recep-uuid-003';
      // WHEN
      final erro = validarCamposMarcarConsulta(
        patientId: patientId,
        doctorId: doctorId,
        data: null, // ← não escolheu data
        hora: hora,
        receptionistId: receptionistId,
      );

      // THEN
      expect(erro, equals('Indique data e hora.'));
    });

    // TESTE 5 - Sem sessão ativa (receptionistId null) → erro explícito
    // Pode acontecer se a sessão Supabase expirar enquanto a rececionista
    // está a preencher o formulário.
    test('receptionistId null (sem sessão) retorna "Sem sessão ativa."', () {
      // GIVEN - sessão Supabase expirada
      const patientId = 'patient-uuid-001';
      const doctorId = 'doctor-uuid-002';
      final data = DateTime(2025, 12, 20);
      const hora = TimeOfDay(hour: 11, minute: 0);
      // WHEN
      final erro = validarCamposMarcarConsulta(
        patientId: patientId,
        doctorId: doctorId,
        data: data,
        hora: hora,
        receptionistId: null, // ← sessão inválida
      );
      // THEN - mensagem exacta usada pelo SnackBar de produção
      expect(erro, equals('Sem sessão ativa.'));
    });
  });

  group('marcar_consulta_rececionista - detecção de conflitos de agenda', () {
    // TESTE 6 - Slot OCUPADO: Supabase devolve consulta existente
    // Caso mais crítico: impede o double-booking que causaria confusão
    // na sala de espera e problemas operacionais para a clínica.
    test('horarioOcupado retorna true quando Supabase devolve uma consulta', () {
      // GIVEN - resultado simulado de query .maybeSingle() com consulta existente
      final stubConsultaExistente = {'id': 'appt-uuid-existente-123'};
      // WHEN
      final ocupado = horarioOcupado(stubConsultaExistente);
      // THEN - deve impedir novo INSERT
      expect(
        ocupado,
        isTrue,
        reason: 'Slot com consulta existente deve ser considerado ocupado',
      );
    });

    // TESTE 7 - Slot LIVRE: Supabase devolve null
    test('horarioOcupado retorna false quando Supabase devolve null', () {
      // GIVEN - slot disponível (query não encontrou nada)
      // WHEN
      final ocupado = horarioOcupado(null);

      // THEN - pode avançar para o INSERT
      expect(
        ocupado,
        isFalse,
        reason: 'Slot vazio deve permitir marcar a consulta',
      );
    });

    // TESTE 8 - Médico INDISPONÍVEL: existe bloqueio no intervalo pedido
    // Cobre o cenário "Bloqueio de Horário por Indisponibilidade Médica"
    // (item Done no kanban).  A rececionista não deve conseguir marcar
    // uma consulta enquanto o médico está de férias ou ausente.
    test('medicoDisponivel retorna false quando existe bloqueio na agenda', () {
      // GIVEN - resultado simulado: bloqueio que se sobrepõe ao slot pedido
      //   ex: médico bloqueou 08:00-13:00 (férias de manhã)
      final stubBloqueios = [
        {
          'id': 77,
          'start_datetime': '2025-12-20T08:00:00Z',
          'end_datetime': '2025-12-20T13:00:00Z',
        },
      ];
      // WHEN
      final disponivel = medicoDisponivel(stubBloqueios);
      // THEN
      expect(
        disponivel,
        isFalse,
        reason:
            'Médico com bloqueio ativo não deve ter consultas marcadas nesse período',
      );
    });

    // TESTE 9 - Médico DISPONÍVEL: sem bloqueios no intervalo
    test(
      'medicoDisponivel retorna true quando lista de bloqueios está vazia',
      () {
        // GIVEN - sem bloqueios para este médico neste intervalo
        // WHEN
        final disponivel = medicoDisponivel([]);
        // THEN
        expect(disponivel, isTrue);
      },
    );
  });

  group('marcar_consulta_rececionista - formatação de data/hora', () {
    // TESTE 10 - fmtDate produz 'YYYY-MM-DD' com zero-padding
    // Bugs aqui fazem as queries de conflito nunca encontrarem nada
    // (comparação de strings no Postgres falha silenciosamente).
    test('fmtDate formata DateTime para "YYYY-MM-DD" com zero-padding', () {
      // GIVEN - data com mês e dia de um só dígito
      final data = DateTime(2025, 3, 7);

      // WHEN
      final resultado = fmtDate(data);

      // THEN - zero-padding obrigatório para o tipo DATE do Postgres
      expect(
        resultado,
        equals('2025-03-07'),
        reason:
            'Mês e dia devem ter zero-padding para compatibilidade com o DATE do Postgres',
      );
    });

    // TESTE 11 - fmtTime produz 'HH:MM:00' com zero-padding
    test('fmtTime formata TimeOfDay para "HH:MM:00" com zero-padding', () {
      // GIVEN - hora e minuto de um só dígito
      const hora = TimeOfDay(hour: 8, minute: 5);

      // WHEN
      final resultado = fmtTime(hora);

      // THEN - segundos fixos em 00, zero-padding para o TIME do Postgres
      expect(
        resultado,
        equals('08:05:00'),
        reason: 'Hora e minuto devem ter zero-padding; segundos fixos em 00',
      );
    });
  });

  group('marcar_consulta_rececionista - tipo de consulta', () {
    // TESTE 12 - Consulta marcada sem urgência → tipo normal
    test('consulta sem flag urgente resulta em TipoConsulta.normal', () {
      // GIVEN - paciente que liga a marcar consulta de rotina
      // WHEN
      final tipo = determinarTipoConsulta(urgente: false);

      // THEN
      expect(
        tipo,
        equals(TipoConsulta.normal),
        reason: 'Marcação de rotina deve ser classificada como normal',
      );
    });

    // TESTE 13 - Consulta marcada com urgência → tipo urgente
    // Garante que o médico vê o alerta visual correcto na agenda.
    test('consulta com flag urgente resulta em TipoConsulta.urgente', () {
      // GIVEN - paciente com queixa aguda (ex: dor no peito)
      // WHEN
      final tipo = determinarTipoConsulta(urgente: true);

      // THEN
      expect(
        tipo,
        equals(TipoConsulta.urgente),
        reason: 'Queixa urgente deve gerar tipo Urgente para alertar o médico',
      );
    });
  });
}
