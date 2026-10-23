import 'package:flutter_test/flutter_test.dart';

enum StatusConsulta { agendada, cancelada, concluida, emAndamento }

/// Replica da validação de cancelamento.
/// Retorna null se o cancelamento pode prosseguir, ou mensagem de erro.
String? validarCancelamento({
  required StatusConsulta statusActual,
  required String? motivo,
  required DateTime dataConsulta,
  required int antecedenciaMinutosMinima,
}) {
  if (statusActual == StatusConsulta.cancelada) {
    return 'Esta consulta já se encontra cancelada.';
  }
  if (statusActual == StatusConsulta.concluida) {
    return 'Não é possível cancelar uma consulta já concluída.';
  }
  if (motivo == null || motivo.trim().isEmpty) {
    return 'Indique o motivo do cancelamento.';
  }
  final agora = DateTime.now();
  final diferenca = dataConsulta.difference(agora).inMinutes;
  if (diferenca < antecedenciaMinutosMinima) {
    return 'Cancelamento deve ser feito com pelo menos '
        '${antecedenciaMinutosMinima ~/ 60}h de antecedência.';
  }
  return null;
}

/// Replica da validação de alteração de horário.
/// Retorna null se a alteração pode prosseguir, ou mensagem de erro.
String? validarAlteracaoHorario({
  required DateTime? novaData,
  required DateTime? hojeRef, // injectado para tornar o teste determinístico
  required Map<String, dynamic>? slotOcupado,
}) {
  if (novaData == null) return 'Indique a nova data e hora.';

  final ref = hojeRef ?? DateTime.now();
  if (novaData.isBefore(ref)) {
    return 'A nova data não pode ser no passado.';
  }
  if (slotOcupado != null) {
    return 'O novo horário já tem uma consulta marcada.';
  }
  return null;
}

/// Replica da geração da mensagem de notificação enviada ao paciente.
/// (lógica pura - o envio em si é feito via Supabase Edge Function)
String gerarTextoNotificacaoCancelamento({
  required String nomePaciente,
  required String nomeMediaco,
  required DateTime dataConsulta,
  required String motivo,
}) {
  final dataFmt =
      '${dataConsulta.day.toString().padLeft(2, '0')}/${dataConsulta.month.toString().padLeft(2, '0')}/${dataConsulta.year}';
  return 'Caro(a) $nomePaciente, a sua consulta com $nomeMediaco '
      'marcada para $dataFmt foi cancelada. Motivo: $motivo.';
}

/// Replica da geração da mensagem de notificação de alteração de horário.
String gerarTextoNotificacaoAlteracao({
  required String nomePaciente,
  required DateTime novaData,
}) {
  final dataFmt =
      '${novaData.day.toString().padLeft(2, '0')}/${novaData.month.toString().padLeft(2, '0')}/${novaData.year}';
  return 'Caro(a) $nomePaciente, o horário da sua consulta foi alterado para $dataFmt.';
}

//  TESTES

void main() {
  group('cancelar_consulta - validação de cancelamento', () {
    // TESTE 1 - Happy path: cancelamento válido sem erros
    // Fluxo standard: consulta agendada, motivo preenchido, antecedência ok.
    test(
      'cancelamento válido com motivo e antecedência suficiente retorna null',
      () {
        // GIVEN - consulta daqui a 2 dias, motivo fornecido
        final dataConsulta = DateTime.now().add(const Duration(hours: 48));
        const motivo = 'Paciente contactou a cancelar por motivos pessoais.';
        const antecedenciaMinima = 120; // 2 horas

        // WHEN
        final erro = validarCancelamento(
          statusActual: StatusConsulta.agendada,
          motivo: motivo,
          dataConsulta: dataConsulta,
          antecedenciaMinutosMinima: antecedenciaMinima,
        );

        // THEN
        expect(
          erro,
          isNull,
          reason:
              'Cancelamento com todas as condições cumpridas deve ser permitido',
        );
      },
    );

    // TESTE 2 - Consulta já cancelada não pode ser cancelada novamente
    // Protege contra double-click ou resubmissão acidental do formulário.
    test('consulta já cancelada retorna mensagem de erro adequada', () {
      // GIVEN - status já é "cancelada" (ex: médico cancelou antes da rececionista)
      final dataConsulta = DateTime.now().add(const Duration(hours: 48));
      // WHEN
      final erro = validarCancelamento(
        statusActual: StatusConsulta.cancelada, // ← já cancelada
        motivo: 'Qualquer motivo',
        dataConsulta: dataConsulta,
        antecedenciaMinutosMinima: 120,
      );
      // THEN
      expect(
        erro,
        equals('Esta consulta já se encontra cancelada.'),
        reason:
            'Tentar cancelar uma consulta já cancelada deve mostrar erro claro',
      );
    });

    // TESTE 3 - Consulta concluída não pode ser cancelada
    test('consulta concluída retorna mensagem de erro', () {
      // GIVEN - médico já marcou a consulta como concluída
      final dataConsulta = DateTime.now().subtract(const Duration(hours: 2));

      // WHEN
      final erro = validarCancelamento(
        statusActual: StatusConsulta.concluida, // ← já concluída
        motivo: 'Motivo tardio',
        dataConsulta: dataConsulta,
        antecedenciaMinutosMinima: 0,
      );

      // THEN
      expect(
        erro,
        equals('Não é possível cancelar uma consulta já concluída.'),
      );
    });
 
    // TESTE 4 - Motivo em branco → erro obrigatório
    // A razão do cancelamento é obrigatória para auditoria e para a notificação
    // ao paciente.
    test('motivo em branco retorna "Indique o motivo do cancelamento."', () {
      // GIVEN - rececionista tentou submeter sem preencher o campo de motivo
      final dataConsulta = DateTime.now().add(const Duration(hours: 48));

      // WHEN
      final erro = validarCancelamento(
        statusActual: StatusConsulta.agendada,
        motivo: '   ', // ← só espaços
        dataConsulta: dataConsulta,
        antecedenciaMinutosMinima: 120,
      );

      // THEN
      expect(
        erro,
        equals('Indique o motivo do cancelamento.'),
        reason:
            'Campo motivo não pode ficar vazio - é obrigatório para auditoria',
      );
    });

    // TESTE 5 - Antecedência insuficiente → erro com horas mínimas
    // Se a clínica exigir 2h de antecedência, cancelar 30 min antes é inválido.
    test('cancelamento com menos de 2h de antecedência retorna erro', () {
      // GIVEN - consulta daqui a 30 minutos, mas mínimo é 2h (120 min)
      final dataConsulta = DateTime.now().add(const Duration(minutes: 30));

      // WHEN
      final erro = validarCancelamento(
        statusActual: StatusConsulta.agendada,
        motivo: 'Motivo válido',
        dataConsulta: dataConsulta,
        antecedenciaMinutosMinima: 120, // 2 horas
      );

      // THEN
      expect(
        erro,
        isNotNull,
        reason:
            'Cancelamento de última hora deve ser bloqueado pela regra de negócio',
      );
      expect(
        erro,
        contains('2h de antecedência'),
        reason:
            'Mensagem deve indicar quantas horas de antecedência são necessárias',
      );
    });
  });

  group('alterar_horario_consulta - validação de alteração', () {
    // TESTE 6 - Happy path: nova data no futuro e slot livre
    test('nova data válida com slot livre retorna null', () {
      // GIVEN - consulta transferida para daqui a 3 dias, slot vazio
      final novaData = DateTime.now().add(const Duration(days: 3));
      final hoje = DateTime.now();

      // WHEN
      final erro = validarAlteracaoHorario(
        novaData: novaData,
        hojeRef: hoje,
        slotOcupado: null, // ← slot disponível
      );

      // THEN
      expect(
        erro,
        isNull,
        reason: 'Alteração para data futura com slot livre deve ser permitida',
      );
    });

    // TESTE 7 - Nova data no passado → erro
    // Rececionista não pode transferir consulta para uma data que já passou.
    test(
      'nova data no passado retorna "A nova data não pode ser no passado."',
      () {
        // GIVEN - data ontem às 10h00
        final ontem = DateTime.now().subtract(const Duration(hours: 24));
        final hoje = DateTime.now();

        // WHEN
        final erro = validarAlteracaoHorario(
          novaData: ontem,
          hojeRef: hoje,
          slotOcupado: null,
        );

        // THEN
        expect(
          erro,
          equals('A nova data não pode ser no passado.'),
          reason: 'Não deve ser possível mover uma consulta para o passado',
        );
      },
    );

    // TESTE 8 - Novo slot já ocupado → erro de conflito
    test('novo horário já ocupado retorna mensagem de conflito', () {
      // GIVEN - existe outra consulta no novo slot escolhido
      final novaData = DateTime.now().add(const Duration(days: 2));
      final hoje = DateTime.now();
      final stubOcupado = {'id': 'appt-conflito-xyz'};

      // WHEN
      final erro = validarAlteracaoHorario(
        novaData: novaData,
        hojeRef: hoje,
        slotOcupado: stubOcupado, // ← slot com consulta existente
      );

      // THEN
      expect(
        erro,
        equals('O novo horário já tem uma consulta marcada.'),
        reason:
            'Conflito de agenda deve ser detectado antes de alterar o horário',
      );
    });
  });

  group('cancelar_consulta - geração de notificação ao paciente', () {
 
    // TESTE 9 - Texto de notificação de cancelamento inclui todos os campos
    // A notificação é enviada via Edge Function - o formato tem de ser exacto
    // para que o template de e-mail/SMS seja preenchido correctamente.
    test(
      'gerarTextoNotificacaoCancelamento contém nome, médico, data e motivo',
      () {
        // GIVEN
        const nomePaciente = 'João Ferreira';
        const nomeMedico = 'Dra. Costa';
        final dataConsulta = DateTime(2025, 11, 5);
        const motivo = 'Consulta remarcada por indisponibilidade do médico';

        // WHEN
        final texto = gerarTextoNotificacaoCancelamento(
          nomePaciente: nomePaciente,
          nomeMediaco: nomeMedico,
          dataConsulta: dataConsulta,
          motivo: motivo,
        );

        // THEN - todos os campos presentes no texto final
        expect(
          texto,
          contains(nomePaciente),
          reason: 'Texto deve incluir o nome do paciente',
        );
        expect(
          texto,
          contains(nomeMedico),
          reason: 'Texto deve incluir o nome do médico',
        );
        expect(
          texto,
          contains('05/11/2025'),
          reason: 'Data deve aparecer no formato DD/MM/YYYY',
        );
        expect(
          texto,
          contains(motivo),
          reason: 'Motivo do cancelamento deve estar no texto',
        );
      },
    );

    // TESTE 10 - Texto de notificação de alteração de horário correcto
    test(
      'gerarTextoNotificacaoAlteracao contém nome do paciente e nova data',
      () {
        // GIVEN
        const nomePaciente = 'Maria Sousa';
        final novaData = DateTime(2025, 12, 3);

        // WHEN
        final texto = gerarTextoNotificacaoAlteracao(
          nomePaciente: nomePaciente,
          novaData: novaData,
        );

        // THEN
        expect(
          texto,
          contains(nomePaciente),
          reason: 'Texto deve endereçar o paciente pelo nome',
        );
        expect(
          texto,
          contains('03/12/2025'),
          reason: 'Nova data deve aparecer no formato DD/MM/YYYY',
        );
      },
    );
  });
}
