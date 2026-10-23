//  AC-01 - A rececionista inicia uma marcação de consulta e o formulário carrega utentes e médicos reais da BD (e permite selecionar um utente).


import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:saude_app/paginas_portal_recepcao/agendamentos_page.dart';

import 'support/acceptance_common.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Portal da Receção - marcação de consulta', () {
    late SupabaseClient db;

    setUp(() async {
      db = await loginComo(kRecepcaoEmail, expectId: kRecepcaoId);
    });

    tearDown(() async {
      await db.auth.signOut();
    });

    testWidgets(
      'AC-01 - formulário de marcação carrega utentes e médicos reais da BD',
      (tester) async {
        await usarJanelaAlta(tester);
        await tester.pumpWidget(const AcceptanceApp(home: AgendamentosPage()));
        await pumpUntilFound(tester, find.text('Agendar'));

        // Abrir o diálogo "Nova Consulta".
        await tapTexto(tester, 'Agendar');
        final abriu = await pumpUntilFound(tester, find.text('Nova Consulta'));
        expect(
          abriu,
          isTrue,
          reason: 'Deve abrir o formulário de nova consulta.',
        );

        // Abrir o dropdown de Utente e confirmar que os pacientes carregaram.
        await tester.tap(find.byType(DropdownButtonFormField<String>).at(0));
        final temPaciente = await pumpUntilFound(
          tester,
          find.text(kPacienteNome),
        );
        expect(
          temPaciente,
          isTrue,
          reason:
              'O formulário deve listar utentes reais (ex.: $kPacienteNome).',
        );

        // Selecionar o utente.
        final itemPaciente = find.text(kPacienteNome).last;
        await tester.ensureVisible(itemPaciente);
        await tester.tap(itemPaciente);
        await tester.pump(const Duration(milliseconds: 400));

        // Abrir o dropdown de Médico e confirmar que os médicos carregaram.
        await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
        final temMedico = await pumpUntilFound(
          tester,
          find.textContaining('João Silva'),
        );
        expect(
          temMedico,
          isTrue,
          reason:
              'O formulário deve listar médicos reais (ex.: Dr. João Silva).',
        );
      },
    );
  });
}
