//  AC-01 — Credenciais válidas autenticam o utilizador e saem do ecrã de login.
//  AC-02 — Credenciais inválidas mostram erro e NÃO criam sessão.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:saude_app/paginas_fluxo_publico/login_page.dart';

import 'support/acceptance_common.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Fluxo Público — início de sessão', () {
    late SupabaseClient db;

    setUp(() async {
      db = await ensureAppStarted();
      await db.auth.signOut(); // começa sempre sem sessão
    });

    tearDown(() async {
      await db.auth.signOut();
    });

    testWidgets(
      'AC-01 — login com credenciais válidas cria sessão e abre o portal',
      (tester) async {
        await usarJanelaAlta(tester);
        await tester.pumpWidget(const AcceptanceApp(home: LoginScreen()));
        await pumpUntilFound(tester, find.text('Iniciar Sessão'));

        await tester.enterText(find.byType(TextField).at(0), kMedicoEmail);
        await tester.enterText(find.byType(TextField).at(1), kSeedPassword);
        await tapTexto(tester, 'Iniciar Sessão');

        // Espera que a sessão fique ativa (o login é assíncrono).
        String? uid;
        for (var i = 0; i < 60; i++) {
          await tester.pump(const Duration(milliseconds: 200));
          uid = db.auth.currentUser?.id;
          if (uid != null) break;
        }

        expect(uid, kMedicoId,
            reason: 'O login válido deve criar sessão para o utilizador seed.');

        // Depois da sessão, a página navega para o portal — esperamos que o
        // ecrã de login saia de cena.
        final saiuDoLogin =
            await pumpUntilGone(tester, find.text('Iniciar Sessão'));
        expect(saiuDoLogin, isTrue,
            reason: 'Após o login deve sair-se do ecrã de início de sessão.');
      },
    );

    testWidgets(
      'AC-02 — login com password errada mostra erro e não cria sessão',
      (tester) async {
        await usarJanelaAlta(tester);
        await tester.pumpWidget(const AcceptanceApp(home: LoginScreen()));
        await pumpUntilFound(tester, find.text('Iniciar Sessão'));

        await tester.enterText(find.byType(TextField).at(0), kMedicoEmail);
        await tester.enterText(find.byType(TextField).at(1), 'password-errada');
        await tapTexto(tester, 'Iniciar Sessão');

        final mostrouErro =
            await pumpUntilFound(tester, find.textContaining('Erro'));

        expect(mostrouErro, isTrue,
            reason: 'Credenciais inválidas devem mostrar uma mensagem de erro.');
        expect(db.auth.currentUser, isNull,
            reason: 'Não deve existir sessão após um login falhado.');
      },
    );
  });
}
