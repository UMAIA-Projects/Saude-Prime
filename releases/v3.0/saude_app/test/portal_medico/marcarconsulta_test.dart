import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simula o comportamento de `_MarcarConsultaState._confirmar`:
/// retorna uma mensagem de erro se os campos obrigatórios estiverem em falta,
/// ou null se a validação de campos passar.
String? validarCamposObrigatorios({
  required String? patientId,
  required DateTime? data,
  required TimeOfDay? hora,
  required String? doctorId,
}) {
  if (patientId == null) return 'Selecione um paciente.';
  if (data == null || hora == null) return 'Indique data e hora.';
  if (doctorId == null) return 'Sem sessão ativa.';
  return null;
}

/// Replica de `_MarcarConsultaState._horarioOcupado`:
/// dado o resultado de uma query Supabase (que pode ser null ou um Map),
/// determina se o slot está ocupado.
bool horarioOcupado(Map<String, dynamic>? queryResult) {
  return queryResult != null;
}

/// Replica de `_MarcarConsultaState._horarioBloqueado`:
/// dado o resultado de uma query Supabase (uma lista, possivelmente vazia),
/// determina se existe overlap com blocked_slots.
bool horarioBloqueado(List<dynamic> queryResult) {
  return queryResult.isNotEmpty;
}

/// Replica de `_fmtDate` e `_fmtTime` usadas na construção dos parâmetros
/// da query Supabase (formato que chega ao insert).
String fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String fmtTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

//  TESTES

void main() {
  group('marcarconsulta - validação de campos obrigatórios', () {
    // TESTE 1 - Happy path: todos os campos preenchidos, sem erro de validação
    // Este é o fluxo que o médico percorre em 99 % das marcações correctas.
    test('campos completos com sessão ativa não retornam erro', () {
      // GIVEN - todos os campos necessários presentes
      const patientId = 'patient-uuid-123';
      final data = DateTime(2025, 12, 15);
      const hora = TimeOfDay(hour: 10, minute: 30);
      const doctorId = 'doctor-uuid-456';

      // WHEN
      final erro = validarCamposObrigatorios(
        patientId: patientId,
        data: data,
        hora: hora,
        doctorId: doctorId,
      );

      // THEN - sem erro; pode avançar para as verificações de conflito
      expect(
        erro,
        isNull,
        reason: 'Todos os campos válidos devem passar a validação inicial',
      );
    });

    // TESTE 2 - Paciente nulo → erro correcto
    test('paciente não seleccionado retorna mensagem adequada', () {
      // GIVEN - patientId omitido (dropdown em branco)
      final data = DateTime(2025, 12, 15);
      const hora = TimeOfDay(hour: 10, minute: 30);
      const doctorId = 'doctor-uuid-456';

      // WHEN
      final erro = validarCamposObrigatorios(
        patientId: null, // ← não seleccionado
        data: data,
        hora: hora,
        doctorId: doctorId,
      );

      // THEN
      expect(
        erro,
        equals('Selecione um paciente.'),
        reason:
            'UI deve exibir SnackBar indicando que o paciente é obrigatório',
      );
    });

    // TESTE 3 - Sem sessão ativa (doctorId null) → erro explícito
    test('doctorId null (sem sessão) retorna "Sem sessão ativa."', () {
      // GIVEN - sessão Supabase expirada ou utilizador não autenticado
      const patientId = 'patient-uuid-123';
      final data = DateTime(2025, 12, 15);
      const hora = TimeOfDay(hour: 10, minute: 0);

      // WHEN
      final erro = validarCamposObrigatorios(
        patientId: patientId,
        data: data,
        hora: hora,
        doctorId: null, // ← sessão inválida
      );

      // THEN - mensagem exacta usada pelo SnackBar de produção
      expect(erro, equals('Sem sessão ativa.'));
    });
  });

  group('marcarconsulta - detecção de conflitos de agenda', () {
    // TESTE 4 - Slot OCUPADO: Supabase devolve uma consulta existente
    // Caso mais crítico: impede double-booking.
    // A query em `_horarioOcupado` usa .maybeSingle() - devolve Map ou null.
    test('horarioOcupado retorna true quando Supabase devolve uma consulta', () {
      // GIVEN - resultado simulado de:
      //   db.from('appointments').select('id')
      //     .eq('doctor_id', ...).eq('scheduled_date', ...).eq('scheduled_time', ...)
      //     .neq('status', 'canceled').isFilter('deleted_at', null)
      //     .maybeSingle()
      final stubExistingAppointment = {'id': 'appt-uuid-789'};

      // WHEN
      final ocupado = horarioOcupado(stubExistingAppointment);

      // THEN
      expect(
        ocupado,
        isTrue,
        reason: 'Deve detectar slot ocupado e impedir novo INSERT',
      );
    });

    // TESTE 5 - Slot LIVRE: Supabase devolve null (sem consulta)
    test('horarioOcupado retorna false quando Supabase devolve null', () {
      // GIVEN - slot vazio
      // WHEN
      final ocupado = horarioOcupado(null);

      // THEN
      expect(
        ocupado,
        isFalse,
        reason: 'Slot livre deve permitir avançar para o INSERT',
      );
    });

    // TESTE 6 - Slot BLOQUEADO: overlap parcial com blocked_slots
    // A query usa .lte('start_datetime', endIso).gte('end_datetime', startIso)
    // - detecta qualquer overlap, incluindo parcial.
    test(
      'horarioBloqueado retorna true quando existe overlap com blocked_slots',
      () {
        // GIVEN - resultado simulado: bloqueio que se sobrepõe ao slot pedido
        //   ex: médico bloqueou 09:00-12:00, consulta pedida para 10:00-10:30
        final stubBloqueios = [
          {'id': 42},
        ];

        // WHEN
        final bloqueado = horarioBloqueado(stubBloqueios);

        // THEN
        expect(
          bloqueado,
          isTrue,
          reason: 'Overlap com blocked_slots deve bloquear o INSERT',
        );
      },
    );

    // TESTE 7 - Slot DESBLOQUEADO: lista vazia
    test('horarioBloqueado retorna false quando lista está vazia', () {
      // GIVEN - sem bloqueios para este intervalo
      // WHEN
      final bloqueado = horarioBloqueado([]);

      // THEN
      expect(bloqueado, isFalse);
    });
  });

  group('marcarconsulta - formatação de data/hora para query Supabase', () {
    // TESTE 8 - fmtDate e fmtTime produzem o formato esperado pela BD
    // Bugs de formatação aqui significam que a query de conflito nunca encontra
    // nada (comparação de strings falha silenciosamente na BD).
    test('fmtDate formata DateTime para "YYYY-MM-DD"', () {
      // GIVEN
      final data = DateTime(2025, 6, 4);

      // WHEN
      final resultado = fmtDate(data);

      // THEN
      expect(
        resultado,
        equals('2025-06-04'),
        reason:
            'Mês e dia devem ter zero-padding para corresponder ao tipo DATE do Postgres',
      );
    });

    test('fmtTime formata TimeOfDay para "HH:MM:00"', () {
      // GIVEN
      const hora = TimeOfDay(hour: 9, minute: 5);

      // WHEN
      final resultado = fmtTime(hora);

      // THEN
      expect(
        resultado,
        equals('09:05:00'),
        reason:
            'Segundos fixos em 00 e zero-padding são necessários para o tipo TIME do Postgres',
      );
    });
  });
}
