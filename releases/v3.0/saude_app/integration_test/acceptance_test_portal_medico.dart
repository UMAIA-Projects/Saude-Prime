//  AC-01  - Médico marca consulta com sucesso; fica persistida no Supabase e visível na agenda.
//  AC-02a - Não deixa marcar num horário já ocupado por consulta ativa.
//  AC-02b - Não deixa marcar num horário bloqueado (blocked_slots).
//  AC-03a - Pesquisa por nome parcial retorna os pacientes esperados.
//  AC-03b - Pesquisa por NIF exato retorna só o paciente correto.
//  AC-03c - Pesquisa sem resultados mostra estado empty.
//  AC-03d - Tap num resultado navega para PatientData com o patientId correto.


import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:saude_app/paginas_portal_medico/marcarconsulta.dart';
import 'package:saude_app/paginas_portal_medico/patientdata.dart';
import 'package:saude_app/paginas_portal_medico/schedule.dart';
import 'package:saude_app/paginas_portal_medico/search.dart';

import 'support/acceptance_common.dart';

// NIF do paciente seed Maria Santos (kPacienteId / kPacienteNome)
const _kPacienteMariaNif = '200000001';

// Segundo paciente seed cujo nome começa por "Mar" (seed_public.sql)
const _kPacienteMartaNome = 'Marta';

const _kAbrirMarcacao = Key('acc_abrir_marcar_consulta');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Grupo 1 - Marcação de consulta
  group('Portal do Médico - marcação de consulta', () {
    late SupabaseClient db;

    setUp(() async {
      db = await loginComo(kMedicoEmail, expectId: kMedicoId);
    });

    tearDown(() async {
      await db.auth.signOut();
    });

    testWidgets(
      'AC-01 - marca consulta com sucesso, persiste no Supabase e aparece na agenda',
      (tester) async {
        final data = dataFutura(offsetDias: 2);
        final hora = horaInicial();
        final dateStr = fmtDate(data);

        await _limparSlot(db, data, hora);
        await _abrirFormulario(tester, data);
        await _selecionarPaciente(tester, kPacienteNome);
        await _confirmar(tester);

        expect(
          find.text('Consulta marcada com sucesso!'),
          findsWidgets,
          reason:
              'O portal deve confirmar ao médico que a consulta foi marcada.',
        );

        final rows = await db
            .from('appointments')
            .select('id')
            .eq('doctor_id', kMedicoId)
            .eq('patient_id', kPacienteId)
            .eq('scheduled_date', dateStr)
            .neq('status', 'canceled');
        expect(
          (rows as List).length,
          greaterThanOrEqualTo(1),
          reason:
              'A marcação aceite deve criar uma consulta ativa no Supabase.',
        );

        await _abrirAgenda(tester);
        await _selecionarDataAgenda(tester, data);
        final visivel = await pumpUntilFound(
          tester,
          find.textContaining(kPacienteNome),
        );
        expect(
          visivel,
          isTrue,
          reason: 'A agenda do médico deve renderizar a consulta persistida.',
        );

        await _cancelarSlot(db, data, hora);
      },
    );

    testWidgets('AC-02a - não marca consulta num horário já ocupado', (
      tester,
    ) async {
      final data = dataFutura(offsetDias: 4);
      final hora = horaInicial();
      final dateStr = fmtDate(data);
      final timeStr = fmtTime(hora);

      await _limparSlot(db, data, hora);
      await _criarConsultaSeed(db, data, hora);

      await _abrirFormulario(tester, data);
      await _selecionarPaciente(tester, kPacienteNome);
      await _confirmar(tester);

      expect(
        find.textContaining('Já existe uma consulta neste horário'),
        findsWidgets,
        reason: 'O portal deve bloquear slots já ocupados por consulta ativa.',
      );

      final rows = await db
          .from('appointments')
          .select('id')
          .eq('doctor_id', kMedicoId)
          .eq('scheduled_date', dateStr)
          .eq('scheduled_time', timeStr)
          .neq('status', 'canceled');
      expect(
        (rows as List).length,
        1,
        reason: 'Não deve ser criada consulta duplicada no mesmo slot.',
      );

      await _cancelarSlot(db, data, hora);
    });

    testWidgets('AC-02b - não marca consulta num horário bloqueado', (
      tester,
    ) async {
      final data = dataFutura(offsetDias: 6);
      final hora = horaInicial();
      final dateStr = fmtDate(data);
      final timeStr = fmtTime(hora);

      await _limparSlot(db, data, hora);
      final blockId = await _criarBloqueioSeed(db, data, hora);

      await _abrirFormulario(tester, data);
      await _selecionarPaciente(tester, kPacienteNome);
      await _confirmar(tester);

      expect(
        find.textContaining('Este horário está bloqueado na agenda'),
        findsWidgets,
        reason: 'O portal deve bloquear slots inseridos em blocked_slots.',
      );

      final rows = await db
          .from('appointments')
          .select('id')
          .eq('doctor_id', kMedicoId)
          .eq('scheduled_date', dateStr)
          .eq('scheduled_time', timeStr)
          .neq('status', 'canceled');
      expect(
        (rows as List).length,
        0,
        reason:
            'Nenhuma consulta deve ser criada quando o slot está bloqueado.',
      );

      await db.from('blocked_slots').delete().eq('id', blockId);
    });
  });

  // Grupo 2 - Pesquisa de paciente
  group('Portal do Médico - pesquisa de paciente', () {
    late SupabaseClient db;

    setUp(() async {
      db = await loginComo(kMedicoEmail, expectId: kMedicoId);
    });

    tearDown(() async {
      await db.auth.signOut();
    });

    testWidgets(
      'AC-03a - pesquisa por nome parcial "Mar" retorna Maria Santos e Marta',
      (tester) async {
        await _abrirPesquisa(tester);

        await tester.enterText(find.byType(TextField).first, 'Mar');
        await pumpUntilFound(tester, find.text(kPacienteNome));

        expect(
          find.text(kPacienteNome),
          findsOneWidget,
          reason: 'Maria Santos deve aparecer nos resultados.',
        );
        expect(
          find.text(_kPacienteMartaNome),
          findsOneWidget,
          reason: 'Marta deve aparecer nos resultados.',
        );
      },
    );

    testWidgets(
      'AC-03b - pesquisa por NIF "$_kPacienteMariaNif" retorna apenas Maria Santos',
      (tester) async {
        await _abrirPesquisa(tester);

        await tester.enterText(
          find.byType(TextField).first,
          _kPacienteMariaNif,
        );
        await pumpUntilFound(tester, find.text(kPacienteNome));

        expect(
          find.text(kPacienteNome),
          findsOneWidget,
          reason: 'Pesquisa por NIF deve encontrar o paciente correto.',
        );
        expect(
          find.text(_kPacienteMartaNome),
          findsNothing,
          reason: 'Paciente com NIF diferente não deve aparecer.',
        );
      },
    );

    testWidgets('AC-03c - pesquisa sem resultados mostra estado empty', (
      tester,
    ) async {
      await _abrirPesquisa(tester);

      await tester.enterText(
        find.byType(TextField).first,
        'ZZZ_PacienteInexistente',
      );
      await pumpUntilFound(tester, find.text('Nenhum paciente encontrado.'));

      expect(
        find.text('Nenhum paciente encontrado.'),
        findsOneWidget,
        reason: 'Estado empty deve ser mostrado quando não há resultados.',
      );

      // Deixa o debounce timer do Search drenar completamente para evitar
      // setState() after dispose() no tearDown seguinte.
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets(
      'AC-03d - tap num resultado navega para PatientData com o patientId correto',
      (tester) async {
        await _abrirPesquisa(tester);

        await tester.enterText(find.byType(TextField).first, kPacienteNome);
        await pumpUntilFound(tester, find.text(kPacienteNome));

        // Garantir que o item está dentro de uma ListView (resultado da pesquisa,
        // não o próprio TextField que também contém o texto).
        final resultItem = find.descendant(
          of: find.byType(ListView),
          matching: find.text(kPacienteNome),
        );
        await pumpUntilFound(tester, resultItem);

        await tester.tap(resultItem.first);
        final found = await pumpUntilFound(tester, find.byType(PatientData));
        expect(
          found,
          isTrue,
          reason: 'Ecrã PatientData deve estar ativo após tap no resultado.',
        );

        final patientDataWidget = tester.widget<PatientData>(
          find.byType(PatientData),
        );
        expect(
          patientDataWidget.patientId,
          equals(kPacienteId),
          reason:
              'PatientData deve ser aberto com o patientId de Maria Santos.',
        );
      },
    );
  });
}

// Passos de UI - marcação de consulta

Future<void> _abrirFormulario(WidgetTester tester, DateTime data) async {
  await tester.pumpWidget(
    AcceptanceApp(home: _AbrirMarcacaoHost(initialDate: data)),
  );
  await pumpUntilFound(tester, find.byKey(_kAbrirMarcacao));

  await tester.tap(find.byKey(_kAbrirMarcacao));
  await pumpUntilFound(tester, find.text('Selecionar paciente'));
}

Future<void> _selecionarPaciente(WidgetTester tester, String nome) async {
  final dropdown = find.byType(DropdownButton<String>).first;
  await tester.tap(dropdown);
  await tester.pumpAndSettle();

  final item = find.text(nome).last;
  await tester.ensureVisible(item);
  await tester.tap(item);
  await tester.pumpAndSettle();
}

Future<void> _confirmar(WidgetTester tester) async {
  final confirmar = find.text('Confirmar Marcação');
  await tester.ensureVisible(confirmar);
  await tester.tap(confirmar);

  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 200));
    final sucesso = find
        .text('Consulta marcada com sucesso!')
        .evaluate()
        .isNotEmpty;
    final erro =
        find
            .textContaining('Já existe uma consulta neste horário')
            .evaluate()
            .isNotEmpty ||
        find
            .textContaining('Este horário está bloqueado na agenda')
            .evaluate()
            .isNotEmpty;
    if (sucesso || erro) break;
  }
}

Future<void> _abrirAgenda(WidgetTester tester) async {
  await tester.pumpWidget(const AcceptanceApp(home: Schedule()));
  await pumpUntilFound(tester, find.text('Próx. >'));
}

Future<void> _selecionarDataAgenda(WidgetTester tester, DateTime data) async {
  final now = DateTime.now();
  final meses = (data.year - now.year) * 12 + (data.month - now.month);
  for (var i = 0; i < meses; i++) {
    await tester.tap(find.text('Próx. >'));
    await pumpUntilFound(tester, find.text('Próx. >'));
  }
  await tester.tap(find.text('${data.day}').first);
  await tester.pump(const Duration(seconds: 1));
}

// Passos de UI - pesquisa de paciente

Future<void> _abrirPesquisa(WidgetTester tester) async {
  await tester.pumpWidget(const AcceptanceApp(home: Search()));
  await pumpUntilFound(tester, find.text('Pesquisar Paciente'));
}

// Seed / limpeza de estado no Supabase

Future<void> _limparSlot(
  SupabaseClient db,
  DateTime data,
  TimeOfDay hora,
) async {
  await _cancelarSlot(db, data, hora);
  await _eliminarBloqueios(db, data, hora);
}

Future<void> _cancelarSlot(
  SupabaseClient db,
  DateTime data,
  TimeOfDay hora,
) async {
  final rows = await db
      .from('appointments')
      .select('id')
      .eq('doctor_id', kMedicoId)
      .eq('scheduled_date', fmtDate(data))
      .eq('scheduled_time', fmtTime(hora))
      .neq('status', 'canceled');
  for (final row in rows as List) {
    await db
        .from('appointments')
        .update({'status': 'canceled'})
        .eq('id', row['id'] as String);
  }
}

Future<void> _eliminarBloqueios(
  SupabaseClient db,
  DateTime data,
  TimeOfDay hora,
) async {
  final start = slotStart(data, hora);
  final end = start.add(const Duration(minutes: 30));
  final rows = await db
      .from('blocked_slots')
      .select('id')
      .eq('doctor_id', kMedicoId)
      .lte('start_datetime', end.toUtc().toIso8601String())
      .gte('end_datetime', start.toUtc().toIso8601String());
  for (final row in rows as List) {
    await db.from('blocked_slots').delete().eq('id', row['id']);
  }
}

Future<void> _criarConsultaSeed(
  SupabaseClient db,
  DateTime data,
  TimeOfDay hora,
) async {
  await db.from('appointments').insert({
    'id': uuidV4(),
    'patient_id': kPacienteId,
    'doctor_id': kMedicoId,
    'scheduled_date': fmtDate(data),
    'scheduled_time': fmtTime(hora),
    'duration_min': 30,
    'type': 'normal',
    'status': 'scheduled',
    'created_by': kMedicoId,
  });
}

Future<int> _criarBloqueioSeed(
  SupabaseClient db,
  DateTime data,
  TimeOfDay hora,
) async {
  final start = slotStart(data, hora);
  final end = start.add(const Duration(minutes: 30));
  final row = await db
      .from('blocked_slots')
      .insert({
        'doctor_id': kMedicoId,
        'start_datetime': start.toUtc().toIso8601String(),
        'end_datetime': end.toUtc().toIso8601String(),
        'reason': 'Bloqueio seed do acceptance test.',
      })
      .select('id')
      .single();
  return row['id'] as int;
}

// Host para abrir o MarcarConsulta numa rota (permite Navigator.pop)
class _AbrirMarcacaoHost extends StatelessWidget {
  final DateTime initialDate;
  const _AbrirMarcacaoHost({required this.initialDate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          key: _kAbrirMarcacao,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MarcarConsulta(initialDate: initialDate),
            ),
          ),
          child: const Text('Abrir marcação'),
        ),
      ),
    );
  }
}
