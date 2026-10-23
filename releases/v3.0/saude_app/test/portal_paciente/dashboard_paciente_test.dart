import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Replica `_NotificacaoData.tempoRelativo`.
String tempoRelativo(DateTime createdAt) {
  final diff = DateTime.now().difference(createdAt);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  return '${diff.inDays}d';
}

/// Replica o getter `_badgeInfo` de `_ProximaConsultaSection`.
/// Devolve o label visual para cada status de consulta.
String badgeLabelConsulta(String? status) {
  switch (status) {
    case 'scheduled':
      return 'Agendada';
    case 'completed':
      return 'Concluída';
    case 'canceled':
      return 'Cancelada';
    default:
      return 'Agendada';
  }
}

/// Replica o getter `_badgeInfo` de `_TuaSenha`.
/// Devolve o label visual para cada status de senha de fila.
String badgeLabelSenha(String status) {
  switch (status) {
    case 'called':
      return 'Chamado!';
    case 'waiting':
    default:
      return 'À espera';
  }
}

/// Replica a extração do primeiro nome para a saudação do header.
/// "Ana Lima" - "Ana"
String primeiroNome(String nomeCompleto) {
  return nomeCompleto.split(' ').first;
}

/// Replica `_DashboardHeader._dataHoje` - valida o formato produzido.
/// Devolve uma string que contém o dia da semana, dia do mês e mês por extenso.
String formatarDataHoje(DateTime now) {
  const weekdays = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo',
  ];
  const months = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  return '${weekdays[now.weekday - 1]}, ${now.day} de ${months[now.month - 1]} ${now.year}';
}

/// Replica a formatação de data/hora de consulta no _DashboardService.
/// ex: "2025-12-15" + "14:30:00" - "Seg, 15 Dez • 14:30"
String formatarDataHoraConsulta(String scheduledDate, String scheduledTime) {
  final date = DateTime.parse(scheduledDate);
  final hhmm = scheduledTime.substring(0, 5);
  const weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  const months = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];
  final dataFormatada =
      '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  return '$dataFormatada • $hhmm';
}

// WIDGETS STANDALONE - replicam os estados do DashboardPaciente

/// Replica o estado loading do DashboardPaciente.
class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Color(0xFF1A8070))),
    );
  }
}

/// Replica o estado de erro do DashboardPaciente (snapshot.hasError).
class _DashboardErro extends StatelessWidget {
  final VoidCallback onRetry;
  const _DashboardErro({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 40),
            const SizedBox(height: 12),
            const Text(
              'Erro ao carregar dados.\nVerifica a tua ligação.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Replica o header do DashboardPaciente com saudação e data.
class _DashboardHeader extends StatelessWidget {
  final String nome;
  const _DashboardHeader({required this.nome});

  @override
  Widget build(BuildContext context) {
    final firstName = nome.split(' ').first;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text('Olá, $firstName!', key: const Key('saudacao'))],
      ),
    );
  }
}

/// Replica o estado vazio de _ProximaConsultaSection (consulta == null).
class _SemConsultasWidget extends StatelessWidget {
  const _SemConsultasWidget();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Sem consultas agendadas')));
  }
}

/// Replica _TuaSenha com dados injetados diretamente.
class _SenhaWidget extends StatelessWidget {
  final String ticketNumber;
  final String status;
  final int queuePosition;
  final String? currentTicket;

  const _SenhaWidget({
    required this.ticketNumber,
    required this.status,
    required this.queuePosition,
    this.currentTicket,
  });

  String get _badgeLabel {
    switch (status) {
      case 'called':
        return 'Chamado!';
      case 'waiting':
      default:
        return 'À espera';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text(ticketNumber, key: const Key('ticketNumber')),
          Text(_badgeLabel, key: const Key('badgeLabel')),
          Text('$queuePosition à frente na fila', key: const Key('filaInfo')),
          if (currentTicket != null)
            Text(
              'A ser atendido: $currentTicket',
              key: const Key('currentTicket'),
            ),
        ],
      ),
    );
  }
}

//  TESTES

void main() {
  group('dashboard_paciente - estados de UI', () {
    // TESTE 1 - Estado loading: CircularProgressIndicator visível
    testWidgets('estado loading mostra CircularProgressIndicator', (
      tester,
    ) async {
      // GIVEN - dashboard em carregamento (FutureBuilder em waiting)
      await tester.pumpWidget(const MaterialApp(home: _DashboardLoading()));
      await tester.pump();

      // THEN
      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
        reason:
            'CircularProgressIndicator deve estar visível durante o carregamento',
      );
    });

    // TESTE 2 - Estado de erro: mensagem e botão "Tentar novamente" visíveis
    testWidgets('estado de erro mostra mensagem e botão retry', (tester) async {
      // GIVEN - erro de rede simulado
      bool retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(home: _DashboardErro(onRetry: () => retryCalled = true)),
      );
      await tester.pump();

      // THEN - mensagem de erro visível
      expect(
        find.textContaining('Erro ao carregar'),
        findsOneWidget,
        reason: 'Mensagem de erro deve ser visível ao paciente',
      );

      // THEN - botão retry visível
      expect(find.text('Tentar novamente'), findsOneWidget);

      // WHEN - utilizador toca em retry
      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();

      // THEN - callback invocado
      expect(
        retryCalled,
        isTrue,
        reason: 'onRetry deve ser chamado ao tocar em "Tentar novamente"',
      );
    });

    // TESTE 3 - Com dados: saudação com primeiro nome correto
    testWidgets('saudação usa apenas o primeiro nome do paciente', (
      tester,
    ) async {
      // GIVEN - paciente com nome composto
      await tester.pumpWidget(
        const MaterialApp(home: _DashboardHeader(nome: 'Ana Lima Ferreira')),
      );
      await tester.pumpAndSettle();

      // THEN - saudação com "Olá, Ana!" e não com o nome completo
      expect(
        find.text('Olá, Ana!'),
        findsOneWidget,
        reason: 'Saudação deve usar apenas o primeiro nome',
      );
      expect(
        find.textContaining('Lima'),
        findsNothing,
        reason: 'Apelido não deve aparecer na saudação',
      );
    });

    // TESTE 4 - Estado vazio: sem consultas exibe mensagem adequada
    testWidgets('sem consultas agendadas exibe mensagem adequada', (
      tester,
    ) async {
      // GIVEN - paciente sem consultas
      await tester.pumpWidget(const MaterialApp(home: _SemConsultasWidget()));
      await tester.pump();

      // THEN
      expect(
        find.text('Sem consultas agendadas'),
        findsOneWidget,
        reason: 'Estado vazio deve indicar ao paciente que não há consultas',
      );
    });

    // TESTE 5 - Senha com status 'waiting': badge "À espera" e posição na fila
    testWidgets('senha "waiting" exibe badge "À espera" e posição na fila', (
      tester,
    ) async {
      // GIVEN - senha ativa em espera
      await tester.pumpWidget(
        const MaterialApp(
          home: _SenhaWidget(
            ticketNumber: 'A-42',
            status: 'waiting',
            queuePosition: 3,
          ),
        ),
      );
      await tester.pump();

      // THEN - número da senha visível
      expect(find.text('A-42'), findsOneWidget);

      // THEN - badge de espera
      expect(
        find.text('À espera'),
        findsOneWidget,
        reason: 'Status "waiting" deve exibir badge "À espera"',
      );

      // THEN - posição na fila
      expect(find.textContaining('3 à frente'), findsOneWidget);
    });

    // TESTE 6 - Senha com status 'called': badge "Chamado!" e ticket atual
    testWidgets(
      'senha "called" exibe badge "Chamado!" e ticket a ser atendido',
      (tester) async {
        // GIVEN - paciente foi chamado
        await tester.pumpWidget(
          const MaterialApp(
            home: _SenhaWidget(
              ticketNumber: 'A-42',
              status: 'called',
              queuePosition: 0,
              currentTicket: 'A-42',
            ),
          ),
        );
        await tester.pump();

        // THEN
        expect(
          find.text('Chamado!'),
          findsOneWidget,
          reason: 'Status "called" deve exibir badge "Chamado!"',
        );
        expect(
          find.textContaining('A ser atendido: A-42'),
          findsOneWidget,
          reason: 'Deve mostrar qual ticket está a ser atendido',
        );
      },
    );
  });

  group('dashboard_paciente - tempoRelativo das notificações', () {
    // TESTE 7 - Notificação de há poucos minutos → formato "Xm"
    // Usado na secção "Notificações Recentes" do dashboard.
    test('notificação de há 5 minutos devolve "5m"', () {
      final createdAt = DateTime.now().subtract(const Duration(minutes: 5));
      expect(tempoRelativo(createdAt), equals('5m'));
    });

    // TESTE 8 - Notificação de há algumas horas → formato "Xh"
    test('notificação de há 3 horas devolve "3h"', () {
      final createdAt = DateTime.now().subtract(const Duration(hours: 3));
      expect(tempoRelativo(createdAt), equals('3h'));
    });

    // TESTE 9 - Notificação de há dias → formato "Xd"
    test('notificação de há 2 dias devolve "2d"', () {
      final createdAt = DateTime.now().subtract(const Duration(days: 2));
      expect(tempoRelativo(createdAt), equals('2d'));
    });
  });

  group('dashboard_paciente - badge de status de consulta', () {
    // TESTE 10 - Mapeamento de todos os status conhecidos
    test('"scheduled" mapeia para "Agendada"', () {
      expect(badgeLabelConsulta('scheduled'), equals('Agendada'));
    });

    test('"completed" mapeia para "Concluída"', () {
      expect(badgeLabelConsulta('completed'), equals('Concluída'));
    });

    test('"canceled" mapeia para "Cancelada"', () {
      expect(badgeLabelConsulta('canceled'), equals('Cancelada'));
    });

    // TESTE 11 - Status desconhecido → fallback "Agendada"
    test('status desconhecido usa fallback "Agendada"', () {
      expect(badgeLabelConsulta(null), equals('Agendada'));
      expect(badgeLabelConsulta('outro'), equals('Agendada'));
    });
  });

  group('dashboard_paciente - formatação de data/hora da BD', () {
    // TESTE 12 - Data e hora formatadas corretamente para o card de consulta
    // Um bug aqui exibe datas erradas no card "Próxima Consulta" do dashboard.
    test('2025-12-15 + 14:30:00 formata para "Seg, 15 Dez • 14:30"', () {
      final resultado = formatarDataHoraConsulta('2025-12-15', '14:30:00');
      expect(resultado, equals('Seg, 15 Dez • 14:30'));
    });

    test('2025-01-06 + 09:00:00 formata para "Seg, 6 Jan • 09:00"', () {
      final resultado = formatarDataHoraConsulta('2025-01-06', '09:00:00');
      expect(resultado, equals('Seg, 6 Jan • 09:00'));
    });

    // TESTE 13 - Extração do primeiro nome para saudação
    test('primeiroNome extrai apenas o primeiro token do nome completo', () {
      expect(primeiroNome('Ana Lima Ferreira'), equals('Ana'));
      expect(primeiroNome('João'), equals('João'));
    });
  });
}
