//  US #4  - scheduleAppointment      : paciente marca consulta (sem sobreposições).
//  US #7  - updateProfileData        : paciente atualiza o contacto e persiste na BD.
//  US #8  - viewMedicalHistory       : paciente vê o histórico clínico.
//  US #9  - rescheduleAppointment    : paciente reagenda consulta para slot disponível.
//  US #10 - cancelAppointment        : cancelamento com +24h persiste na BD.
//  US #11 - searchDoctorBySpecialty  : filtrar médicos por especialidade.
//  US #15 - newsletterSubscription   : toggle newsletter persiste na BD.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:saude_app/paginas_portal_paciente/patient_edit_profile_page.dart';
import 'package:saude_app/paginas_portal_paciente/patient_profile_page.dart';
import 'package:saude_app/paginas_portal_paciente/history_page.dart';
import 'package:saude_app/paginas_portal_paciente/my_appointments_page.dart';
import 'package:saude_app/paginas_portal_paciente/schedule_appointment_1_page.dart';

import 'support/acceptance_common.dart';

// Dias suficientemente distantes para que o teste nunca fique perto do limite
// de 24h conforme os dias vão passando.
const int _diasMarcacao = 90; // US #4  - marcar consulta
const int _diasReagendar = 90; // US #9  - reagendar (inserção seed)
const int _diasCancelar = 90; // US #10 - cancelar com +24h (inserção seed)

// Helper: seleciona uma especialidade no showMenu() de forma robusta.
Future<void> _selecionarEspecialidade(
  WidgetTester tester,
  String nomeEspecialidade,
) async {
  await tester.tap(find.text('- - - - -'));

  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.byType(PopupMenuItem<int>).evaluate().isNotEmpty) break;
  }

  final itemFinder = find.widgetWithText(PopupMenuItem<int>, nomeEspecialidade);

  await tester.scrollUntilVisible(
    itemFinder,
    -50.0,
    scrollable: find.byType(Scrollable).last,
    maxScrolls: 20,
  );

  await tester.pump(const Duration(milliseconds: 150));
  await tester.tap(itemFinder);
  await tester.pumpAndSettle(const Duration(milliseconds: 600));
}

// Helper: tenta selecionar o primeiro slot de hora disponível de uma lista.
Future<String?> _selecionarPrimeiroSlot(WidgetTester tester) async {
  const slots = [
    '08:00',
    '08:30',
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
  ];
  for (final slot in slots) {
    final f = find.text(slot);
    if (f.evaluate().isNotEmpty) {
      await tester.tap(f.first);
      await tester.pump(const Duration(milliseconds: 300));
      return slot;
    }
  }
  return null;
}

// Helper: insere uma consulta diretamente na BD (sem UI) e devolve o id.
Future<String> _inserirConsultaFutura(
  SupabaseClient db, {
  required String doctorId,
  required int diasFuturo,
}) async {
  final user = db.auth.currentUser!;
  final data = dataFutura(offsetDias: diasFuturo);
  final id = uuidV4();
  await db.from('appointments').insert({
    'id': id,
    'patient_id': user.id,
    'doctor_id': doctorId,
    'scheduled_date': fmtDate(data),
    'scheduled_time': '10:00:00',
    'type': 'normal',
    'status': 'scheduled',
    'created_by': user.id,
  });
  return id;
}

// Helper: apaga uma consulta da BD (limpeza após teste).
Future<void> _apagarConsulta(SupabaseClient db, String id) async {
  await db.from('appointments').delete().eq('id', id);
}

// US #9 - ISOLAMENTO SEM CANCELAR
Future<List<String>> _esconderOutrasConsultas(
  SupabaseClient db,
  String excetoId,
) async {
  final rows = await db
      .from('appointments')
      .select('id')
      .eq('patient_id', kPacienteId)
      .eq('status', 'scheduled')
      .neq('id', excetoId)
      .isFilter('deleted_at', null);

  final ids = (rows as List<dynamic>).map((r) => r['id'] as String).toList();

  if (ids.isNotEmpty) {
    await db
        .from('appointments')
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .inFilter('id', ids);
  }

  return ids;
}

// Restaura o deleted_at a NULL nas linhas escondidas por _esconderOutrasConsultas.
Future<void> _restaurarConsultasEscondidas(
  SupabaseClient db,
  List<String> ids,
) async {
  if (ids.isEmpty) return;
  await db
      .from('appointments')
      .update({'deleted_at': null})
      .inFilter('id', ids);
}

// US #10 - ISOLAMENTO CANCELANDO
Future<void> _cancelarOutrasConsultas(
  SupabaseClient db,
  String excetoId,
) async {
  await db
      .from('appointments')
      .update({'status': 'canceled'})
      .eq('patient_id', kPacienteId)
      .eq('status', 'scheduled')
      .neq('id', excetoId);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Portal do Paciente - Testes de Aceitação Completos', () {
    late SupabaseClient db;

    setUp(() async {
      db = await loginComo(kPacienteEmail, expectId: kPacienteId);
    });

    tearDown(() async {
      await db.auth.signOut();
    });

    // US #4 - scheduleAppointment
    testWidgets(
      'US #4 - Marcar Consulta: paciente marca consulta e aparece na BD sem sobreposições',
      (tester) async {
        await usarJanelaAlta(tester);
        await tester.pumpWidget(
          const AcceptanceApp(home: ScheduleAppointment1Page()),
        );

        final carregou = await pumpUntilFound(
          tester,
          find.textContaining('João Silva'),
        );
        expect(
          carregou,
          isTrue,
          reason: 'A lista de médicos deve carregar da BD.',
        );

        final btnAgendar = find.text('Agendar');
        expect(
          btnAgendar,
          findsWidgets,
          reason: 'Deve existir pelo menos um botão "Agendar".',
        );
        await tester.tap(btnAgendar.first);
        await tester.pumpAndSettle(const Duration(milliseconds: 600));

        final passo2 = await pumpUntilFound(
          tester,
          find.textContaining('Marcar Consulta - Horário'),
        );
        expect(
          passo2,
          isTrue,
          reason: 'Deve navegar para o calendário (passo 2).',
        );

        final dataAlvo = DateTime.now().add(Duration(days: _diasMarcacao));
        final mesesAvancar =
            (dataAlvo.year - DateTime.now().year) * 12 +
            (dataAlvo.month - DateTime.now().month);
        for (var m = 0; m < mesesAvancar; m++) {
          final seta = find.byIcon(Icons.chevron_right);
          if (seta.evaluate().isNotEmpty) {
            await tester.tap(seta.first);
            await tester.pump(const Duration(milliseconds: 200));
          }
        }

        bool diaEscolhido = false;
        for (var offset = 0; offset <= 7; offset++) {
          final d = dataAlvo.add(Duration(days: offset));
          if (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday)
            continue;
          final diaFinder = find.text('${d.day}');
          if (diaFinder.evaluate().isNotEmpty) {
            await tester.tap(diaFinder.first);
            await tester.pump(const Duration(milliseconds: 300));
            diaEscolhido = true;
            break;
          }
        }
        expect(
          diaEscolhido,
          isTrue,
          reason: 'Deve ser possível selecionar um dia útil futuro.',
        );

        final slotsApareceram = await pumpUntilFound(
          tester,
          find.text('HORÁRIOS DISPONÍVEIS'),
          timeout: const Duration(seconds: 10),
        );
        expect(
          slotsApareceram,
          isTrue,
          reason: 'Os slots disponíveis devem carregar após selecionar o dia.',
        );

        final slotEscolhido = await _selecionarPrimeiroSlot(tester);
        expect(
          slotEscolhido,
          isNotNull,
          reason: 'Deve existir pelo menos um slot horário disponível.',
        );

        final continuar = find.text('Continuar →');
        await tester.ensureVisible(continuar);
        await tester.tap(continuar);
        await tester.pumpAndSettle(const Duration(milliseconds: 600));

        final passo3 = await pumpUntilFound(
          tester,
          find.textContaining('Marcar Consulta - Confirmar'),
        );
        expect(passo3, isTrue, reason: 'Deve navegar para o passo 3.');

        final btnConfirmar = find.text('Confirmar Marcação');
        await tester.ensureVisible(btnConfirmar);
        await tester.tap(btnConfirmar);

        final confirmado = await pumpUntilFound(
          tester,
          find.textContaining('As Minhas Consultas'),
          timeout: const Duration(seconds: 15),
        );
        expect(
          confirmado,
          isTrue,
          reason: 'Após confirmar, deve navegar para As Minhas Consultas.',
        );

        final rows = await db
            .from('appointments')
            .select('id, status')
            .eq('patient_id', kPacienteId)
            .eq('status', 'scheduled')
            .order('created_at', ascending: false)
            .limit(1);
        expect(
          (rows as List).isNotEmpty,
          isTrue,
          reason: 'A consulta marcada deve estar na BD com status scheduled.',
        );

        if ((rows as List).isNotEmpty) {
          await _apagarConsulta(db, rows.first['id'] as String);
        }
      },
    );

    // US #7 - updateProfileData
    testWidgets(
      'US #7 - Edição de Dados Pessoais: paciente atualiza o telemóvel e persiste na BD',
      (tester) async {
        final original = await db
            .from('users')
            .select('phone')
            .eq('id', kPacienteId)
            .single();
        final telOriginal = original['phone'] as String?;
        final novoTel =
            '+351 911 ${DateTime.now().millisecondsSinceEpoch % 1000000}';

        try {
          await abrirPagina(tester, (_) => const PatientEditProfileScreen());
          await pumpUntilFound(tester, find.text('Editar Perfil'));

          final campoTel = find.byWidgetPredicate(
            (w) => w is TextField && w.decoration?.hintText == 'Telemóvel',
          );
          await tester.ensureVisible(campoTel);
          await tester.tap(campoTel);
          await tester.pump();
          await tester.enterText(campoTel, novoTel);
          await tester.pump();

          await tapTexto(tester, 'Guardar Alterações');

          final ok = await pumpUntilFound(
            tester,
            find.textContaining('Perfil atualizado'),
            timeout: const Duration(seconds: 15),
          );
          expect(
            ok,
            isTrue,
            reason: 'A app deve mostrar confirmação de atualização do perfil.',
          );

          await Future<void>.delayed(const Duration(milliseconds: 300));

          final atual = await db
              .from('users')
              .select('phone')
              .eq('id', kPacienteId)
              .single();
          expect(
            atual['phone'],
            novoTel,
            reason:
                'O novo telemóvel deve estar persistido na BD imediatamente.',
          );
        } finally {
          await db
              .from('users')
              .update({'phone': telOriginal})
              .eq('id', kPacienteId);
        }
      },
    );

    // US #8 - viewMedicalHistory
    testWidgets(
      'US #8 - Consulta de Histórico Médico: lista consultas concluídas com médico e especialidade',
      (tester) async {
        await usarJanelaAlta(tester);
        await tester.pumpWidget(
          const AcceptanceApp(home: ClinicHistoryScreen()),
        );

        final temRegisto = await pumpUntilFound(
          tester,
          find.textContaining('João Silva'),
        );
        expect(
          temRegisto,
          isTrue,
          reason:
              'O histórico deve listar a consulta concluída com o nome '
              'do médico consultado.',
        );
      },
    );

    // US #9 - rescheduleAppointment - com delay prepositado
    testWidgets(
      'US #9 - Alteração de Horário: paciente reagenda consulta para slot disponível',
      (tester) async {
        final consultaId = await _inserirConsultaFutura(
          db,
          doctorId: kMedicoId,
          diasFuturo: _diasReagendar,
        );

        // Esconde outras consultas agendadas via deleted_at (não cancela).
        final escondidas = await _esconderOutrasConsultas(db, consultaId);

        try {
          await usarJanelaAlta(tester);
          await tester.pumpWidget(
            const AcceptanceApp(home: MyAppointmentsPage()),
          );

          final carregou = await pumpUntilFound(
            tester,
            find.text('Reagendar'),
            timeout: const Duration(seconds: 15),
          );
          expect(
            carregou,
            isTrue,
            reason: 'Deve existir um botão "Reagendar" na lista de próximas.',
          );

          await tester.tap(find.text('Reagendar').first);
          await tester.pumpAndSettle(const Duration(milliseconds: 600));

          final emReagendar = await pumpUntilFound(
            tester,
            find.textContaining('Reagendar'),
          );
          expect(
            emReagendar,
            isTrue,
            reason: 'Deve navegar para a página de reagendamento.',
          );

          final dataAlvo = DateTime.now().add(
            Duration(days: _diasReagendar + 30),
          );
          final mesesAvancar =
              (dataAlvo.year - DateTime.now().year) * 12 +
              (dataAlvo.month - DateTime.now().month);
          for (var m = 0; m < mesesAvancar; m++) {
            final seta = find.byIcon(Icons.chevron_right);
            if (seta.evaluate().isNotEmpty) {
              await tester.tap(seta.first);
              await tester.pumpAndSettle(const Duration(milliseconds: 200));
            }
          }

          bool diaSeleccionado = false;
          for (var offset = 0; offset <= 7; offset++) {
            final d = dataAlvo.add(Duration(days: offset));
            if (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday)
              continue;
            // Usa find.text igual ao US #4 - mais robusto que byWidgetPredicate
            final diaFinder = find.text('${d.day}');
            if (diaFinder.evaluate().isNotEmpty) {
              await tester.tap(diaFinder.first);
              await tester.pumpAndSettle(const Duration(seconds: 10));
              diaSeleccionado = true;
              break;
            }
          }
          expect(
            diaSeleccionado,
            isTrue,
            reason: 'Deve ser possível selecionar um dia útil no calendário.',
          );

          final slotEscolhido = await _selecionarPrimeiroSlot(tester);
          expect(
            slotEscolhido,
            isNotNull,
            reason:
                'Deve existir pelo menos um slot disponível para reagendar.',
          );

          final btnConfirmar = find.text('Confirmar Novo Horário');
          await tester.ensureVisible(btnConfirmar);
          await tester.tap(btnConfirmar);
          await tester.pumpAndSettle(const Duration(seconds: 10));

          final updated = await db
              .from('appointments')
              .select('scheduled_time')
              .eq('id', consultaId)
              .single();
          expect(
            updated['scheduled_time'] as String != '10:00:00',
            isTrue,
            reason:
                'O horário da consulta deve ter mudado do valor original (10:00).',
          );
        } finally {
          // Restaura consultas escondidas (deleted_at → NULL) antes de apagar a seed.
          await _restaurarConsultasEscondidas(db, escondidas);
          await _apagarConsulta(db, consultaId);
        }
      },
    );

    // US #10 - cancelAppointment
    testWidgets(
      'US #10 - Cancelamento de Consulta: permite cancelar com mais de 24h e persiste na BD',
      (tester) async {
        final consultaId = await _inserirConsultaFutura(
          db,
          doctorId: kMedicoId,
          diasFuturo: _diasCancelar,
        );

        await _cancelarOutrasConsultas(db, consultaId);

        try {
          await usarJanelaAlta(tester);
          await tester.pumpWidget(
            const AcceptanceApp(home: MyAppointmentsPage()),
          );

          final carregou = await pumpUntilFound(
            tester,
            find.text('Cancelar'),
            timeout: const Duration(seconds: 15),
          );
          expect(
            carregou,
            isTrue,
            reason: 'Deve existir um botão "Cancelar" na lista de próximas.',
          );

          await tester.tap(find.text('Cancelar').first);
          await tester.pumpAndSettle(const Duration(milliseconds: 400));

          final dialogo = await pumpUntilFound(
            tester,
            find.text('Sim, cancelar'),
          );
          expect(
            dialogo,
            isTrue,
            reason:
                'O diálogo de confirmação deve aparecer para consultas com +24h.',
          );

          await tester.tap(find.text('Sim, cancelar'));
          await tester.pumpAndSettle(const Duration(milliseconds: 1000));

          final row = await db
              .from('appointments')
              .select('status')
              .eq('id', consultaId)
              .single();
          expect(
            row['status'],
            'canceled',
            reason: 'O status da consulta deve ser "canceled" na BD.',
          );
        } finally {
          await _apagarConsulta(db, consultaId);
        }
      },
    );

    testWidgets(
      'US #10 - Cancelamento de Consulta: sistema bloqueia cancelamento com menos de 24h',
      (tester) async {
        final user = db.auth.currentUser!;
        final agora = DateTime.now().add(const Duration(hours: 1));
        final id = uuidV4();
        await db.from('appointments').insert({
          'id': id,
          'patient_id': user.id,
          'doctor_id': kMedicoId,
          'scheduled_date': fmtDate(agora),
          'scheduled_time': fmtTime(TimeOfDay(hour: agora.hour, minute: 0)),
          'type': 'normal',
          'status': 'scheduled',
          'created_by': user.id,
        });

        await _cancelarOutrasConsultas(db, id);

        try {
          await usarJanelaAlta(tester);
          await tester.pumpWidget(
            const AcceptanceApp(home: MyAppointmentsPage()),
          );

          final carregou = await pumpUntilFound(
            tester,
            find.text('Cancelar'),
            timeout: const Duration(seconds: 15),
          );
          expect(carregou, isTrue);

          await tester.tap(find.text('Cancelar').first);
          await tester.pumpAndSettle(const Duration(milliseconds: 400));

          final erroApareceu = await pumpUntilFound(
            tester,
            find.textContaining('24h'),
          );
          expect(
            erroApareceu,
            isTrue,
            reason:
                'Deve mostrar erro a indicar que o cancelamento requer 24h de antecedência.',
          );

          final row = await db
              .from('appointments')
              .select('status')
              .eq('id', id)
              .single();
          expect(
            row['status'],
            'scheduled',
            reason: 'A consulta não deve ter sido cancelada.',
          );
        } finally {
          await _apagarConsulta(db, id);
        }
      },
    );

    // US #11 - searchDoctorBySpecialty
    testWidgets(
      'US #11 - Pesquisa de Médicos por Especialidade: filtra corretamente por especialidade',
      (tester) async {
        await usarJanelaAlta(tester);
        await tester.pumpWidget(
          const AcceptanceApp(home: ScheduleAppointment1Page()),
        );

        final carregou = await pumpUntilFound(
          tester,
          find.textContaining('João Silva'),
        );
        expect(
          carregou,
          isTrue,
          reason: 'A lista de médicos deve carregar antes de filtrar.',
        );

        await _selecionarEspecialidade(tester, 'Cardiologia');

        final filtroAtualizado = await pumpUntilGone(
          tester,
          find.text('- - - - -'),
        );
        expect(
          filtroAtualizado,
          isTrue,
          reason:
              'O campo de filtro deve deixar de mostrar "- - - - -" e '
              'passar a mostrar "Cardiologia".',
        );

        final silvaDesapareceu = await pumpUntilGone(
          tester,
          find.textContaining('João Silva'),
        );
        expect(
          silvaDesapareceu,
          isTrue,
          reason:
              'Após filtrar por Cardiologia, Dr. João Silva '
              '(Medicina Geral) não deve aparecer na lista.',
        );

        expect(
          find.textContaining('Carla Mendes'),
          findsWidgets,
          reason:
              'A Dra. Carla Mendes (Cardiologia) deve continuar visível '
              'após o filtro ser aplicado.',
        );
      },
    );

    // US #15 - newsletterSubscription
    testWidgets(
      'US #15 - Subscrição da Newsletter: toggle persiste na BD e pode ser desativado',
      (tester) async {
        final prefsBefore = await db
            .from('user_preferences')
            .select('newsletter_optin')
            .eq('user_id', kPacienteId)
            .maybeSingle();
        final initialValue = prefsBefore?['newsletter_optin'] as bool? ?? false;

        try {
          await usarJanelaAlta(tester);
          await abrirPagina(tester, (_) => const ProfileScreen());
          await pumpUntilFound(tester, find.textContaining('Newsletter'));

          final switchFinder = find.byWidgetPredicate((w) => w is Switch);
          final switches = switchFinder.evaluate().toList();
          expect(
            switches.isNotEmpty,
            isTrue,
            reason: 'Deve existir pelo menos um Switch na página de perfil.',
          );

          final newsletterSwitch = switchFinder.last;
          final valorAntes = (tester.widget(newsletterSwitch) as Switch).value;

          await tester.tap(newsletterSwitch);
          await tester.pump(const Duration(milliseconds: 500));

          final prefsAfter = await db
              .from('user_preferences')
              .select('newsletter_optin')
              .eq('user_id', kPacienteId)
              .maybeSingle();
          final novoValor = prefsAfter?['newsletter_optin'] as bool? ?? false;
          expect(
            novoValor,
            !valorAntes,
            reason:
                'O toggle de newsletter deve ter persistido o novo valor na BD.',
          );

          await tester.tap(newsletterSwitch);
          await tester.pump(const Duration(milliseconds: 500));

          final prefsRestored = await db
              .from('user_preferences')
              .select('newsletter_optin')
              .eq('user_id', kPacienteId)
              .maybeSingle();
          final valorRestaurado =
              prefsRestored?['newsletter_optin'] as bool? ?? false;
          expect(
            valorRestaurado,
            valorAntes,
            reason: 'O toggle deve poder ser revertido ao valor original.',
          );
        } finally {
          await db.from('user_preferences').upsert({
            'user_id': kPacienteId,
            'newsletter_optin': initialValue,
          }, onConflict: 'user_id');
        }
      },
    );
  });
}
