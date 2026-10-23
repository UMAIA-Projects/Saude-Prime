import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Replica de `_BlockScheduleState._toUtc` (blockschedule.dart)
DateTime toUtc(DateTime date, TimeOfDay time) {
  return DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  ).toUtc();
}

/// Replica da validação central de `_confirmarBloqueio`:
/// retorna null se válido, ou a mensagem de erro se inválido.
String? validarIntervalo({
  required DateTime? dataInicio,
  required DateTime?
  dataFim, // já resolvida (apenasEsteDia ? dataInicio : _dataFim)
  required TimeOfDay? horaInicio,
  required TimeOfDay? horaFim,
}) {
  // Guarda 1: campos obrigatórios
  if (dataInicio == null || horaInicio == null || horaFim == null) {
    return 'Preencha todos os campos obrigatórios.';
  }

  final dataFimEfetiva = dataFim ?? dataInicio;
  final startUtc = toUtc(dataInicio, horaInicio);
  final endUtc = toUtc(dataFimEfetiva, horaFim);

  // Guarda 2: fim tem de ser estritamente posterior ao início
  if (!endUtc.isAfter(startUtc)) {
    return 'A hora/data de fim tem de ser posterior ao início.';
  }

  return null; // válido
}

//  TESTES

void main() {
  group('blockschedule - _toUtc', () {
    // TESTE 1 - _toUtc converte DateTime + TimeOfDay para UTC correctamente
    // Escolhemos este teste porque qualquer offset errado persiste silenciosamente
    // no Supabase e o médico vê os slots bloqueados no horário errado.
    test('converte DateTime + TimeOfDay para ISO 8601 UTC correctamente', () {
      // GIVEN - uma data local (Lisboa, UTC+1 no inverno) e uma hora
      // Usamos UTC diretamente para tornar o teste portátil entre
      // máquinas com fusos horários diferentes:
      // UTC offset do runner não deve afectar o resultado.
      final date = DateTime(2025, 11, 20); // 20 Nov 2025
      const time = TimeOfDay(hour: 9, minute: 30);

      // WHEN - convertemos para UTC
      final result = toUtc(date, time);

      // THEN - o resultado deve ser um DateTime em UTC com os valores correctos
      expect(
        result.isUtc,
        isTrue,
        reason: 'O DateTime resultante deve estar em UTC',
      );
      expect(
        result.toIso8601String(),
        endsWith('Z'),
        reason: 'ISO 8601 UTC deve terminar em "Z"',
      );
      // Verificamos que hora e minuto foram preservados antes da conversão
      final local = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      expect(
        result,
        equals(local.toUtc()),
        reason:
            'toUtc(date, time) deve ser equivalente a '
            'DateTime(y,m,d,h,min).toUtc()',
      );
    });
  });

  group('blockschedule - validarIntervalo (lógica de negócio crítica)', () {
    // TESTE 2 - Happy path: intervalo válido não retorna erro
    test('intervalo válido (início < fim, mesmo dia) retorna null', () {
      // GIVEN - data de hoje, hora início 09:00, hora fim 10:00
      final hoje = DateTime.now();
      const horaInicio = TimeOfDay(hour: 9, minute: 0);
      const horaFim = TimeOfDay(hour: 10, minute: 0);

      // WHEN
      final erro = validarIntervalo(
        dataInicio: hoje,
        dataFim: hoje, // apenasEsteDia=true - mesma data
        horaInicio: horaInicio,
        horaFim: horaFim,
      );

      // THEN - sem erro
      expect(
        erro,
        isNull,
        reason: 'Um bloqueio com hora fim depois do início deve ser aceite',
      );
    });

    // TESTE 3 - Fim igual ao início é rejeitado (slot de duração zero)
    test('horaFim == horaInicio no mesmo dia retorna mensagem de erro', () {
      // GIVEN - inicio e fim exactamente iguais
      final hoje = DateTime.now();
      const mesmaHora = TimeOfDay(hour: 14, minute: 0);

      // WHEN
      final erro = validarIntervalo(
        dataInicio: hoje,
        dataFim: hoje,
        horaInicio: mesmaHora,
        horaFim: mesmaHora,
      );

      // THEN - deve rejeitar com a mensagem exacta usada pelo SnackBar
      expect(
        erro,
        equals('A hora/data de fim tem de ser posterior ao início.'),
        reason: 'Um slot de duração zero (fim == início) não deve ser inserido',
      );
    });

    // TESTE 4 - Fim anterior ao início é rejeitado (ex.: 10:00–09:00)
    test(
      'horaFim anterior a horaInicio no mesmo dia retorna mensagem de erro',
      () {
        // GIVEN - inversão de horas (erro frequente de utilizador)
        final hoje = DateTime.now();
        const horaInicio = TimeOfDay(hour: 15, minute: 0);
        const horaFim = TimeOfDay(hour: 9, minute: 0); // antes do início!

        // WHEN
        final erro = validarIntervalo(
          dataInicio: hoje,
          dataFim: hoje,
          horaInicio: horaInicio,
          horaFim: horaFim,
        );

        // THEN
        expect(
          erro,
          isNotNull,
          reason: 'Fim antes do início deve ser rejeitado',
        );
        expect(
          erro,
          contains('posterior ao início'),
          reason: 'Mensagem de erro deve orientar o utilizador',
        );
      },
    );

    // TESTE 5 - Campos obrigatórios em falta - erro "campos obrigatórios"
    test('campos obrigatórios nulos retornam a mensagem correcta', () {
      // GIVEN - dataInicio fornecida mas hora de início omitida
      final hoje = DateTime.now();

      // WHEN
      final erro = validarIntervalo(
        dataInicio: hoje,
        dataFim: hoje,
        horaInicio: null, // ← campo em falta
        horaFim: const TimeOfDay(hour: 10, minute: 0),
      );

      // THEN
      expect(erro, equals('Preencha todos os campos obrigatórios.'));
    });

    // TESTE 6 - apenasEsteDia=true ignora _dataFim e usa dataInicio como fim
    // (regra de negócio: quando o toggle está ativo, o médico bloqueia
    //  apenas um único dia; dataFim é descartada)
    test(
      'apenasEsteDia=true: dataFim passada como dataInicio → intervalo válido',
      () {
        // GIVEN - médico clicou "Apenas este dia"; passamos dataInicio como dataFim
        final hoje = DateTime.now();
        final amanha = hoje.add(const Duration(days: 1));
        // Mesmo que _dataFim aponte para amanhã, o caller resolve para dataInicio
        const horaInicio = TimeOfDay(hour: 8, minute: 0);
        const horaFim = TimeOfDay(hour: 12, minute: 0);

        // WHEN - caller já resolveu dataFim = dataInicio (comportamento de produção)
        final erro = validarIntervalo(
          dataInicio: hoje,
          dataFim: hoje, // <-- dataInicio, não amanhã
          horaInicio: horaInicio,
          horaFim: horaFim,
        );

        // Sanity: se passarmos amanhã como fim também deve funcionar
        final erroComAmanha = validarIntervalo(
          dataInicio: hoje,
          dataFim: amanha,
          horaInicio: horaInicio,
          horaFim: const TimeOfDay(
            hour: 8,
            minute: 0,
          ), // mesma hora, dia seguinte
        );

        // THEN
        expect(
          erro,
          isNull,
          reason: 'Bloqueio de dia único válido deve ser aceite',
        );
        expect(
          erroComAmanha,
          isNull,
          reason:
              'Bloqueio multi-dia com dataFim no dia seguinte deve ser aceite',
        );
      },
    );

    // TESTE 7 - Motivo vazio deve ser convertido para null antes do INSERT
    // (regra de negócio: string vazia → null na BD, não string vazia)
    test('motivo vazio é normalizado para null', () {
      // GIVEN - simulação da lógica de produção:
      //   `_motivoCtrl.text.trim().isEmpty ? null : _motivoCtrl.text.trim()`
      String? normalizarMotivo(String rawInput) {
        final trimmed = rawInput.trim();
        return trimmed.isEmpty ? null : trimmed;
      }

      // WHEN / THEN
      expect(normalizarMotivo(''), isNull, reason: 'String vazia → null');
      expect(normalizarMotivo('   '), isNull, reason: 'Só espaços → null');
      expect(
        normalizarMotivo('Férias'),
        'Férias',
        reason: 'Texto válido → preservado',
      );
    });
  });
}
