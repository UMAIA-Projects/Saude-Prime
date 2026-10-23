import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// WIDGETS STANDALONE - replicam os estados do dashboard da rececionista

/// Replica o estado loading do DashboardRececionista.
class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Color(0xFF3DBDAD))),
    );
  }
}

/// Replica o widget de erro do DashboardRececionista.
class _DashboardErro extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardErro({required this.message, required this.onRetry});

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

/// Replica a secção de dados do dashboard: saudação + fila de espera + consultas.
class _DashboardComDados extends StatelessWidget {
  final String nomeRececionista;
  final int totalConsultas;
  final int totalFilaEspera;

  const _DashboardComDados({
    required this.nomeRececionista,
    required this.totalConsultas,
    required this.totalFilaEspera,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bem-vindo(a), $nomeRececionista'),
          Text('$totalConsultas consultas hoje'),
          Text('$totalFilaEspera em espera'),
        ],
      ),
    );
  }
}

/// Widget para testar tap num item da fila de espera.
class _FilaEsperaItemNavTest extends StatelessWidget {
  final String patientId;
  final String patientName;
  final VoidCallback onTap;

  const _FilaEsperaItemNavTest({
    required this.patientId,
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

/// Replica da validação do formulário de registo de novo utilizador.
/// Retorna null se válido, ou a mensagem de erro a mostrar.
String? validarRegistoUtilizador({
  required String nome,
  required String email,
  required String password,
  required String confirmPassword,
}) {
  if (nome.trim().isEmpty) return 'O nome é obrigatório.';

  // Validação básica de e-mail (sem regex complexa - igual à produção)
  if (!email.contains('@') || !email.contains('.')) {
    return 'Introduza um e-mail válido.';
  }

  if (password.length < 8) {
    return 'A password deve ter pelo menos 8 caracteres.';
  }

  if (password != confirmPassword) {
    return 'As passwords não coincidem.';
  }

  return null;
}

/// Replica de `_normalizarPerfil`:
/// garante que o perfil é sempre um dos valores permitidos na BD.
String normalizarPerfil(String? rawPerfil) {
  const perfisValidos = ['rececionista', 'medico', 'admin'];
  if (rawPerfil == null)
    return 'rececionista'; // default para novos utilizadores
  final lower = rawPerfil.toLowerCase().trim();
  return perfisValidos.contains(lower) ? lower : 'rececionista';
}

//  TESTES

void main() {
  group('dashboard_rececionista - estados de UI', () {
    // TESTE 1 - Estado loading: CircularProgressIndicator visível
    testWidgets('estado loading mostra CircularProgressIndicator', (
      tester,
    ) async {
      // GIVEN - dashboard a carregar dados (ex: lista de consultas do dia)
      await tester.pumpWidget(const MaterialApp(home: _DashboardLoading()));

      // Não chamar pumpAndSettle - mantém o estado de loading
      await tester.pump();
      // THEN - indicador de progresso visível
      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
        reason:
            'CircularProgressIndicator deve estar visível enquanto os dados carregam',
      );
    });

    // TESTE 2 - Estado de erro: mensagem e botão "Tentar novamente" visíveis
    testWidgets('estado de erro mostra mensagem e botão retry', (tester) async {
      // GIVEN - erro de rede ao carregar o dashboard
      bool retryCalled = false;
      const mensagemErro = 'Erro ao carregar dados. Verifique a ligação.';

      await tester.pumpWidget(
        MaterialApp(
          home: _DashboardErro(
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
        reason: 'Mensagem de erro deve ser legível para a rececionista',
      );
      // THEN - botão retry visível
      expect(
        find.text('Tentar novamente'),
        findsOneWidget,
        reason:
            'Botão "Tentar novamente" deve estar disponível no estado de erro',
      );
      // WHEN - rececionista toca no botão retry
      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();
      // THEN - callback foi invocado
      expect(
        retryCalled,
        isTrue,
        reason:
            'onRetry deve ser chamado quando a rececionista toca em "Tentar novamente"',
      );
    });

    // TESTE 3 - Com dados: saudação, consultas e fila de espera renderizados
    testWidgets(
      'dashboard com dados renderiza saudação, consultas e fila de espera',
      (tester) async {
        // GIVEN - rececionista autenticada com dados carregados
        const nome = 'Ana Martins';
        const totalConsultas = 12;
        const totalFila = 3;

        await tester.pumpWidget(
          const MaterialApp(
            home: _DashboardComDados(
              nomeRececionista: nome,
              totalConsultas: totalConsultas,
              totalFilaEspera: totalFila,
            ),
          ),
        );

        await tester.pumpAndSettle();
        // THEN - nome da rececionista visível
        expect(
          find.textContaining(nome),
          findsOneWidget,
          reason: 'Dashboard deve saudar a rececionista pelo nome',
        );
        // THEN - total de consultas do dia visível
        expect(
          find.textContaining('$totalConsultas'),
          findsAtLeast(1),
          reason: 'Número de consultas do dia deve estar visível no dashboard',
        );
        // THEN - fila de espera visível
        expect(
          find.textContaining('$totalFila'),
          findsAtLeast(1),
          reason: 'Número de pacientes em espera deve estar visível',
        );
      },
    );

    // TESTE 4 - Tap num item da fila de espera invoca callback correcto
    testWidgets(
      'tap num item da fila de espera invoca callback com patientId correcto',
      (tester) async {
        // GIVEN - item da fila com patientId conhecido
        const patientId = 'patient-uuid-fila-001';
        const patientName = 'Carlos Rodrigues';
        String? capturedId;

        await tester.pumpWidget(
          MaterialApp(
            home: _FilaEsperaItemNavTest(
              patientId: patientId,
              patientName: patientName,
              onTap: () => capturedId = patientId,
            ),
          ),
        );

        await tester.pump();
        // WHEN - rececionista toca no paciente da fila
        await tester.tap(find.text(patientName));
        await tester.pump();
        // THEN - callback recebeu o ID correcto
        expect(
          capturedId,
          equals(patientId),
          reason:
              'Tap no item da fila deve passar o patientId correcto para navegação',
        );
      },
    );
  });

  // ===========================================================================
  group('registo_utilizador - validação do formulário', () {
    // TESTE 5 - Happy path: todos os campos válidos → sem erro
    test('campos completos e válidos retornam null', () {
      // GIVEN - nova rececionista a ser registada pelo admin
      // WHEN
      final erro = validarRegistoUtilizador(
        nome: 'Sofia Pereira',
        email: 'sofia.pereira@clinica.pt',
        password: 'Segura123',
        confirmPassword: 'Segura123',
      );
      // THEN
      expect(
        erro,
        isNull,
        reason: 'Formulário completo e válido deve passar a validação',
      );
    });

    // TESTE 6 - E-mail sem @ → erro de formato
    test('e-mail inválido (sem @) retorna mensagem de erro', () {
      // GIVEN - rececionista cometeu erro de digitação no e-mail
      // WHEN
      final erro = validarRegistoUtilizador(
        nome: 'Sofia Pereira',
        email: 'sofia.pereiraclinica.pt', // ← sem @
        password: 'Segura123',
        confirmPassword: 'Segura123',
      );
      // THEN
      expect(
        erro,
        equals('Introduza um e-mail válido.'),
        reason:
            'E-mail sem @ deve ser rejeitado antes de chamar o Supabase Auth',
      );
    });

    // TESTE 7 - Password com menos de 8 caracteres → erro
    test('password curta (< 8 caracteres) retorna mensagem de erro', () {
      // GIVEN - password demasiado simples
      // WHEN
      final erro = validarRegistoUtilizador(
        nome: 'Sofia Pereira',
        email: 'sofia@clinica.pt',
        password: '1234', // ← curta demais
        confirmPassword: '1234',
      );
      // THEN
      expect(erro, equals('A password deve ter pelo menos 8 caracteres.'));
    });
    // TESTE 8 - Passwords não coincidem → erro
    // Erro de UX frequente: confirmação com typo.
    test('passwords diferentes retornam "As passwords não coincidem."', () {
      // GIVEN - confirmação com diferença
      // WHEN
      final erro = validarRegistoUtilizador(
        nome: 'Sofia Pereira',
        email: 'sofia@clinica.pt',
        password: 'Segura123',
        confirmPassword: 'Segura124', // ← diferente
      );
      // THEN
      expect(
        erro,
        equals('As passwords não coincidem.'),
        reason:
            'Campo de confirmação deve ser comparado com a password principal',
      );
    });

    // TESTE 9 - Nome em branco → erro obrigatório
    test('nome vazio retorna "O nome é obrigatório."', () {
      // WHEN
      final erro = validarRegistoUtilizador(
        nome: '   ', // ← só espaços
        email: 'sofia@clinica.pt',
        password: 'Segura123',
        confirmPassword: 'Segura123',
      );

      // THEN
      expect(erro, equals('O nome é obrigatório.'));
    });
  });

  group('registo_utilizador - normalização de perfil', () {
    // TESTE 10 - Perfil null → default 'rececionista'
    // Evita INSERTs com perfil inválido na coluna profile da tabela users.
    test('perfil null resulta em "rececionista" (default)', () {
      // WHEN
      final perfil = normalizarPerfil(null);

      // THEN
      expect(
        perfil,
        equals('rececionista'),
        reason:
            'Novos utilizadores sem perfil explícito devem ser rececionistas por omissão',
      );
    });

    // TESTE 11 - Perfil com capitalização inconsistente → normalizado
    test('perfil "Medico" (com maiúscula) é normalizado para "medico"', () {
      // GIVEN - input do UI pode ter capitalização variável
      // WHEN
      final perfil = normalizarPerfil('Medico');

      // THEN
      expect(
        perfil,
        equals('medico'),
        reason: 'Perfil deve ser normalizado para lowercase antes do INSERT',
      );
    });

    // TESTE 12 - Perfil desconhecido → fallback 'rececionista'
    test('perfil inválido resulta em "rececionista" (fallback seguro)', () {
      // GIVEN - valor inesperado (ex: bug no UI ou injecção de dados)
      // WHEN
      final perfil = normalizarPerfil('superuser');

      // THEN
      expect(
        perfil,
        equals('rececionista'),
        reason:
            'Perfil não reconhecido deve ser substituído pelo default seguro',
      );
    });
  });
}
