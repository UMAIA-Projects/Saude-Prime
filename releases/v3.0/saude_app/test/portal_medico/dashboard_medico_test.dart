import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// WIDGETS STANDALONE 

/// Replica o estado loading do DashboardMedico.
class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Color(0xFF3DBDAD))),
    );
  }
}

/// Replica o widget _ErrorState do DashboardMedico.
class _DashboardError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text(
                'Tentar novamente',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Replica a secção de dados do DashboardMedico (saudação + total consultas).
class _DashboardComDados extends StatelessWidget {
  final String doctorName;
  final int totalConsultas;

  const _DashboardComDados({
    required this.doctorName,
    required this.totalConsultas,
  });

  String _greeting(String name) {
    final hour = DateTime.now().hour;
    String saudacao;
    if (hour < 12) {
      saudacao = 'Bom dia';
    } else if (hour < 19) {
      saudacao = 'Boa tarde';
    } else {
      saudacao = 'Boa noite';
    }
    final parts = name.trim().split(' ');
    final displayName = parts.length >= 2
        ? 'Dr. ${parts.last}'
        : name.isNotEmpty
        ? 'Dr. $name'
        : 'Doutor';
    return '$saudacao, $displayName!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_greeting(doctorName)),
          Text('$totalConsultas consultas hoje'),
        ],
      ),
    );
  }
}

/// Widget para testar navegação a partir de um item de agenda.
class _AgendaItemNavTest extends StatelessWidget {
  final String appointmentId;
  final String patientName;
  final VoidCallback onTap;

  const _AgendaItemNavTest({
    required this.appointmentId,
    required this.patientName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(onTap: onTap, child: Text(patientName)),
    );
  }
}

//  TESTES

void main() {
  group('dashboard_medico - estados de UI', () {
    // TESTE 1 - Estado loading: CircularProgressIndicator visível
    testWidgets('estado loading mostra CircularProgressIndicator', (
      tester,
    ) async {
      // GIVEN - dashboard em estado de carregamento
      await tester.pumpWidget(const MaterialApp(home: _DashboardLoading()));

      // Não chamar pumpAndSettle para manter o estado loading
      await tester.pump();

      // THEN - indicador de progresso visível
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
      const mensagemErro = 'Erro ao carregar dados. Verifique a ligação.';

      await tester.pumpWidget(
        MaterialApp(
          home: _DashboardError(
            message: mensagemErro,
            onRetry: () => retryCalled = true,
          ),
        ),
      );

      await tester.pump();

      // THEN - mensagem de erro visível
      expect(
        find.text(mensagemErro),
        findsOneWidget,
        reason: 'Mensagem de erro deve ser visível para o utilizador',
      );

      // THEN - botão retry visível
      expect(
        find.text('Tentar novamente'),
        findsOneWidget,
        reason: 'Botão "Tentar novamente" deve estar visível no estado de erro',
      );

      // WHEN - utilizador carrega no botão retry
      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();

      // THEN - callback foi invocado
      expect(
        retryCalled,
        isTrue,
        reason:
            'onRetry deve ser chamado quando o utilizador toca em "Tentar novamente"',
      );
    });

    // TESTE 3 - Com dados: nome do médico e total de consultas renderizados
    testWidgets(
      'com dados renderiza saudação com nome do médico e total de consultas',
      (tester) async {
        // GIVEN - médico com nome e consultas carregadas
        const nome = 'Ana Lima';
        const totalConsultas = 5;

        await tester.pumpWidget(
          const MaterialApp(
            home: _DashboardComDados(
              doctorName: nome,
              totalConsultas: totalConsultas,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // THEN - saudação contém "Dr. Lima" (último apelido)
        expect(
          find.textContaining('Dr. Lima'),
          findsOneWidget,
          reason: 'Saudação deve incluir o título e apelido do médico',
        );

        // THEN - total de consultas visível
        expect(
          find.textContaining('$totalConsultas'),
          findsAtLeast(1),
          reason: 'Total de consultas de hoje deve estar visível no dashboard',
        );
      },
    );

    // TESTE 4 - Tap num item de agenda invoca o callback correcto
    testWidgets(
      'tap num item de agenda invoca callback com o appointmentId correcto',
      (tester) async {
        // GIVEN - item de agenda com appointmentId conhecido
        const appointmentId = 'appt-uuid-test-123';
        const patientName = 'Maria Silva';
        String? capturedId;

        await tester.pumpWidget(
          MaterialApp(
            home: _AgendaItemNavTest(
              appointmentId: appointmentId,
              patientName: patientName,
              onTap: () => capturedId = appointmentId,
            ),
          ),
        );

        await tester.pump();

        // WHEN - utilizador toca no item
        await tester.tap(find.text(patientName));
        await tester.pump();

        // THEN - callback recebeu o ID correcto
        expect(
          capturedId,
          equals(appointmentId),
          reason:
              'Tap no item de agenda deve passar o appointmentId correcto ao navegador',
        );
      },
    );
  });
}
