//  US10 - accessControlLevel: admin altera o nível de acesso de um utilizador e a alteração persiste em `users.role`.
//  US12 - exportInsuranceReport: admin configura a exportação no formato standard (CSV) para seguradoras.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:saude_app/paginas_portal_admin/user_profile_page.dart';
import 'package:saude_app/paginas_portal_admin/export_reports_page.dart';

import 'support/acceptance_common.dart';

// Utilizador-alvo seed que vamos promover e repor (evita mexer em insert/delete
// de utilizadores; só exercita o UPDATE de role, que é a funcionalidade em teste).
const _kAlvoId = '55555555-5555-5555-5555-555555555553'; // Marta (patient)

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Portal Admin - gestão de permissões', () {
    late SupabaseClient db;

    setUp(() async {
      db = await loginComo(kAdminEmail, expectId: kAdminId);
      // Estado inicial conhecido: paciente e sem registo em `doctors`.
      await db.from('users').update({'role': 'patient'}).eq('id', _kAlvoId);
      await db.from('doctors').delete().eq('user_id', _kAlvoId);
    });

    tearDown(() async {
      // Repõe sempre o estado original, mesmo que o teste falhe a meio.
      // (Promover a médico cria uma linha em `doctors` - limpamo-la.)
      await db.from('users').update({'role': 'patient'}).eq('id', _kAlvoId);
      await db.from('doctors').delete().eq('user_id', _kAlvoId);
      await db.auth.signOut();
    });

    testWidgets(
      'US10 - admin promove utilizador a Médico e a mudança persiste em users.role',
      (tester) async {
        await usarJanelaAlta(tester);
        await tester.pumpWidget(
          const AcceptanceApp(home: UserProfilePage(userId: _kAlvoId)),
        );
        // Espera o perfil carregar - sinal: o botão "Alterar" das permissões.
        // (Não usamos pumpAndSettle por causa do spinner do avatar do template.)
        final abriu = await pumpUntilFound(tester, find.text('Alterar'));
        expect(abriu, isTrue, reason: 'O perfil do utilizador deve carregar.');

        // Abrir o ecrã de alteração de permissões.
        await tapTexto(tester, 'Alterar');
        final abriuPermissoes = await pumpUntilFound(
          tester,
          find.text('Alterar Permissões'),
        );
        expect(
          abriuPermissoes,
          isTrue,
          reason: 'Deve abrir o ecrã de alteração de permissões.',
        );

        // Selecionar o nível "Médico" - passa a exigir uma especialidade.
        await tapTexto(tester, 'Médico');
        await tester.pump(const Duration(milliseconds: 300));

        // Escolher uma especialidade no dropdown que aparece.
        await tester.tap(find.text('Selecione uma especialidade'));
        await pumpUntilFound(tester, find.text('Cardiologia'));
        await tester.tap(find.text('Cardiologia').last);
        await tester.pump(const Duration(milliseconds: 400));

        await tapTexto(tester, 'Guardar Permissões');

        // Confirmar persistência (poll à BD enquanto a UI processa o UPDATE).
        String? role;
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 250));
          final r = await db
              .from('users')
              .select('role')
              .eq('id', _kAlvoId)
              .maybeSingle();
          role = r?['role'] as String?;
          if (role == 'doctor') break;
        }

        expect(
          role,
          'doctor',
          reason: 'Após guardar, o role do utilizador deve ser "doctor" na BD.',
        );
      },
    );

    testWidgets(
      'US12 - admin configura exportação no formato CSV (standard de seguradoras)',
      (tester) async {
        await usarJanelaAlta(tester);
        await tester.pumpWidget(const AcceptanceApp(home: ExportReportsPage()));

        final abriu = await pumpUntilFound(
          tester,
          find.text('Exportar Relatórios'),
        );
        expect(abriu, isTrue, reason: 'A página de exportação deve carregar.');

        // O preview de dados deve renderizar.
        final temPreview = await pumpUntilFound(tester, find.text('Registos'));
        expect(
          temPreview,
          isTrue,
          reason: 'A pré-visualização dos dados deve aparecer.',
        );

        // Escolher o formato CSV (standard exigido pelas seguradoras).
        await tapTexto(tester, 'Formato: PDF');
        await pumpUntilFound(tester, find.text('CSV'));
        await tester.tap(find.text('CSV'));
        await tester.pump(const Duration(milliseconds: 500));

        final ficouCsv = await pumpUntilFound(
          tester,
          find.text('Formato: CSV'),
        );
        expect(
          ficouCsv,
          isTrue,
          reason: 'Deve ser possível exportar no formato CSV.',
        );
      },
    );
  });
}
