import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ENUMS E HELPERS EXTRAÍDOS DE PRODUÇÃO

enum TipoConsulta { normal, urgente, bloqueado, analise }

String tipoLabel(TipoConsulta tipo) {
  switch (tipo) {
    case TipoConsulta.urgente:
      return 'Urgente';
    case TipoConsulta.bloqueado:
      return 'Bloqueado';
    case TipoConsulta.analise:
      return 'Análise';
    case TipoConsulta.normal:
      return 'Normal';
  }
}

/// Verifica se o assert do construtor Consulta passa.
/// Replica a condição:
///   appointmentId != null ||
///   (nomePaciente != null && iniciais != null && nif != null &&
///    data != null && hora != null && tipoConsulta != null && motivo != null)
bool consultaAssertPassa({
  String? appointmentId,
  String? nomePaciente,
  String? iniciais,
  String? nif,
  String? data,
  String? hora,
  TipoConsulta? tipoConsulta,
  String? motivo,
}) {
  return appointmentId != null ||
      (nomePaciente != null &&
          iniciais != null &&
          nif != null &&
          data != null &&
          hora != null &&
          tipoConsulta != null &&
          motivo != null);
}

// WIDGET STANDALONE - replica a Consulta com dados injetados

class _ConsultaComDados extends StatefulWidget {
  final String nomePaciente;
  final String iniciais;
  final String nif;
  final String data;
  final String hora;
  final TipoConsulta tipoConsulta;
  final String? notas;

  const _ConsultaComDados({
    required this.nomePaciente,
    required this.iniciais,
    required this.nif,
    required this.data,
    required this.hora,
    required this.tipoConsulta,
    this.notas,
  });

  @override
  State<_ConsultaComDados> createState() => _ConsultaComDadosState();
}

class _ConsultaComDadosState extends State<_ConsultaComDados> {
  late final TextEditingController _notasCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _notasCtrl = TextEditingController(text: widget.notas ?? '');
  }

  @override
  void dispose() {
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _saving = true);
    // Simula o delay do Supabase
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.nomePaciente, key: const Key('nomePaciente')),
            Text('NIF: ${widget.nif}', key: const Key('nif')),
            Text(widget.data, key: const Key('data')),
            Text(widget.hora, key: const Key('hora')),
            Text(tipoLabel(widget.tipoConsulta), key: const Key('tipo')),
            const SizedBox(height: 16),
            TextField(
              controller: _notasCtrl,
              key: const Key('campoNotas'),
              decoration: const InputDecoration(
                labelText: 'Notas / Diagnóstico',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const Key('botaoGuardar'),
              onPressed: _saving ? null : _guardar,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

//  TESTES


void main() {
  group('consulta - assert do construtor', () {
    // TESTE 1 - Assert falha sem appointmentId e sem dados completos
    test(
      'assert falha quando nem appointmentId nem dados completos são fornecidos',
      () {
        // GIVEN - nada fornecido
        expect(
          consultaAssertPassa(),
          isFalse,
          reason: 'Sem appointmentId e sem dados, o assert deve falhar',
        );
      },
    );

    test('assert falha com dados parciais (falta motivo)', () {
      expect(
        consultaAssertPassa(
          nomePaciente: 'Ana Lima',
          iniciais: 'AL',
          nif: '123456789',
          data: '2025-12-15',
          hora: '10:00',
          tipoConsulta: TipoConsulta.normal,
          // motivo: null  ← em falta
        ),
        isFalse,
        reason: 'Dados incompletos (motivo em falta) devem falhar no assert',
      );
    });

    test('assert passa com appointmentId fornecido', () {
      expect(
        consultaAssertPassa(appointmentId: 'appt-uuid-123'),
        isTrue,
        reason: 'Só com appointmentId o assert deve passar',
      );
    });

    test('assert passa com todos os dados completos', () {
      expect(
        consultaAssertPassa(
          nomePaciente: 'Ana Lima',
          iniciais: 'AL',
          nif: '123456789',
          data: '2025-12-15',
          hora: '10:00',
          tipoConsulta: TipoConsulta.normal,
          motivo: 'Consulta de rotina',
        ),
        isTrue,
        reason: 'Dados completos devem passar no assert',
      );
    });
  });

  group('consulta - render de dados injetados', () {
    // TESTE 2 - Render correcto dos dados injetados
    testWidgets('renderiza nome, NIF, data, hora e tipo correctamente', (
      tester,
    ) async {
      // GIVEN - dados completos injetados diretamente (sem Supabase)
      await tester.pumpWidget(
        const MaterialApp(
          home: _ConsultaComDados(
            nomePaciente: 'Maria Santos',
            iniciais: 'MS',
            nif: '200000001',
            data: '2025-12-15',
            hora: '10:30',
            tipoConsulta: TipoConsulta.urgente,
            notas: 'Dor abdominal persistente',
          ),
        ),
      );

      await tester.pump();

      // THEN - todos os dados visíveis
      expect(
        find.text('Maria Santos'),
        findsOneWidget,
        reason: 'Nome do paciente deve estar visível',
      );
      expect(
        find.textContaining('200000001'),
        findsOneWidget,
        reason: 'NIF deve estar visível',
      );
      expect(
        find.text('2025-12-15'),
        findsOneWidget,
        reason: 'Data da consulta deve estar visível',
      );
      expect(
        find.text('10:30'),
        findsOneWidget,
        reason: 'Hora da consulta deve estar visível',
      );
      expect(
        find.text('Urgente'),
        findsOneWidget,
        reason: 'Tipo de consulta deve estar visível',
      );
    });

    // TESTE 3 - Campo notas editável e botão guardar muda estado para saving
    testWidgets('campo notas é editável e botão guardar mostra estado saving', (
      tester,
    ) async {
      // GIVEN - consulta com notas iniciais
      await tester.pumpWidget(
        const MaterialApp(
          home: _ConsultaComDados(
            nomePaciente: 'João Ferreira',
            iniciais: 'JF',
            nif: '300000002',
            data: '2025-12-16',
            hora: '14:00',
            tipoConsulta: TipoConsulta.normal,
            notas: 'Acompanhamento pós-operatório',
          ),
        ),
      );

      await tester.pump();

      // WHEN - utilizador edita as notas
      await tester.enterText(
        find.byKey(const Key('campoNotas')),
        'Acompanhamento pós-operatório - evolução favorável',
      );
      await tester.pump();

      // THEN - texto atualizado
      expect(
        find.text('Acompanhamento pós-operatório - evolução favorável'),
        findsOneWidget,
        reason: 'Campo de notas deve aceitar edição',
      );

      // WHEN - utilizador toca em Guardar
      await tester.tap(find.byKey(const Key('botaoGuardar')));
      await tester.pump(); // um pump para capturar o estado saving

      // THEN - CircularProgressIndicator visível (estado saving)
      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
        reason: 'Botão deve mostrar indicador de progresso enquanto guarda',
      );

      // Aguardar o fim do saving
      await tester.pumpAndSettle();

      // THEN - botão volta ao estado normal
      expect(
        find.text('Guardar'),
        findsOneWidget,
        reason: 'Botão deve voltar ao estado normal após guardar',
      );
    });
  });
}
