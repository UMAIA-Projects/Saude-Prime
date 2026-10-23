import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// TIPOS

class PacienteEspera {
  final String patientId;
  final String nome;
  final DateTime horaChegada;
  final int duracaoEstimadaMin; // duração estimada da consulta em minutos

  const PacienteEspera({
    required this.patientId,
    required this.nome,
    required this.horaChegada,
    required this.duracaoEstimadaMin,
  });
}

class Fatura {
  final String faturaId;
  final String patientId;
  final double valor;
  final String estado; // 'pago' | 'pendente'
  final DateTime data;

  const Fatura({
    required this.faturaId,
    required this.patientId,
    required this.valor,
    required this.estado,
    required this.data,
  });
}

/// Replica de `_calcularTempoEsperaMinutos`:
/// dado a lista de pacientes antes do paciente alvo (ou a lista completa),
/// calcula o tempo de espera estimado em minutos.
int calcularTempoEspera(List<PacienteEspera> filaAntesDoAlvo) {
  return filaAntesDoAlvo.fold(0, (acc, p) => acc + p.duracaoEstimadaMin);
}

/// Replica de `_ordenarFila`:
/// ordena a fila de espera por hora de chegada (FIFO).
List<PacienteEspera> ordenarFila(List<PacienteEspera> fila) {
  final ordenada = List<PacienteEspera>.from(fila);
  ordenada.sort((a, b) => a.horaChegada.compareTo(b.horaChegada));
  return ordenada;
}

/// Replica de `_posicaoNaFila`:
/// devolve a posição (1-based) de um paciente na fila ordenada.
/// Retorna null se o paciente não estiver na fila.
int? posicaoNaFila(List<PacienteEspera> filaOrdenada, String patientId) {
  final idx = filaOrdenada.indexWhere((p) => p.patientId == patientId);
  return idx == -1 ? null : idx + 1;
}

/// Replica de `_filtrarFaturas`:
/// aplica filtros opcionais por patientId e por estado.
List<Fatura> filtrarFaturas(
  List<Fatura> todas, {
  String? patientId,
  String? estado,
}) {
  return todas.where((f) {
    if (patientId != null && f.patientId != patientId) return false;
    if (estado != null && f.estado != estado) return false;
    return true;
  }).toList();
}

/// Replica de `_totalPendente`:
/// soma os valores das faturas com estado 'pendente'.
double totalPendente(List<Fatura> faturas) {
  return faturas
      .where((f) => f.estado == 'pendente')
      .fold(0.0, (acc, f) => acc + f.valor);
}

// WIDGET STANDALONE - estado de loading para lista de faturas

class _FaturasLoading extends StatelessWidget {
  const _FaturasLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Color(0xFF3DBDAD))),
    );
  }
}

// WIDGET STANDALONE - lista vazia de faturas

class _FaturasVazio extends StatelessWidget {
  const _FaturasVazio();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Sem faturas para mostrar.')),
    );
  }
}

//  TESTES

void main() {
  group('tempo_espera - cálculo do tempo de espera estimado', () {
    // TESTE 1 - Fila vazia → tempo de espera é 0 minutos
    // Rececionista informa o próximo paciente que pode entrar imediatamente.
    test('fila vazia retorna tempo de espera de 0 minutos', () {
      // GIVEN - nenhum paciente à espera
      // WHEN
      final tempo = calcularTempoEspera([]);

      // THEN
      expect(
        tempo,
        equals(0),
        reason: 'Sem pacientes em espera, o tempo estimado deve ser zero',
      );
    });

    // TESTE 2 - Fila com múltiplos pacientes: soma das durações estimadas
    test('fila com 3 pacientes retorna soma das durações estimadas', () {
      // GIVEN - 3 pacientes antes do alvo, com durações distintas
      final base = DateTime(2025, 11, 10, 9, 0);
      final fila = [
        PacienteEspera(
          patientId: 'p1',
          nome: 'Ana',
          horaChegada: base,
          duracaoEstimadaMin: 20,
        ),
        PacienteEspera(
          patientId: 'p2',
          nome: 'Bruno',
          horaChegada: base.add(const Duration(minutes: 5)),
          duracaoEstimadaMin: 15,
        ),
        PacienteEspera(
          patientId: 'p3',
          nome: 'Carla',
          horaChegada: base.add(const Duration(minutes: 10)),
          duracaoEstimadaMin: 30,
        ),
      ];
      // WHEN
      final tempo = calcularTempoEspera(fila);
      // THEN - 20 + 15 + 30 = 65 minutos
      expect(
        tempo,
        equals(65),
        reason:
            'Tempo de espera deve ser a soma das durações de todos os anteriores',
      );
    });

    // TESTE 3 - Ordenação da fila por hora de chegada (FIFO)
    // Garante que o paciente que chegou primeiro é atendido primeiro.
    test('ordenarFila coloca os pacientes por ordem de chegada', () {
      // GIVEN - pacientes chegados fora de ordem
      final base = DateTime(2025, 11, 10, 9, 0);
      final filaDesordenada = [
        PacienteEspera(
          patientId: 'p3',
          nome: 'Carla',
          horaChegada: base.add(const Duration(minutes: 20)),
          duracaoEstimadaMin: 15,
        ),
        PacienteEspera(
          patientId: 'p1',
          nome: 'Ana',
          horaChegada: base,
          duracaoEstimadaMin: 20,
        ),
        PacienteEspera(
          patientId: 'p2',
          nome: 'Bruno',
          horaChegada: base.add(const Duration(minutes: 10)),
          duracaoEstimadaMin: 20,
        ),
      ];
      // WHEN
      final ordenada = ordenarFila(filaDesordenada);
      // THEN - Ana (chegou primeiro) deve ser a primeira
      expect(
        ordenada.first.patientId,
        equals('p1'),
        reason:
            'Paciente com hora de chegada mais cedo deve estar em primeiro na fila',
      );
      expect(
        ordenada.last.patientId,
        equals('p3'),
        reason:
            'Paciente com hora de chegada mais tarde deve estar no fim da fila',
      );
    });

    // TESTE 4 - posicaoNaFila devolve posição correcta (1-based)
    test(
      'posicaoNaFila devolve a posição correcta para um patientId conhecido',
      () {
        // GIVEN - fila já ordenada com 3 pacientes
        final base = DateTime(2025, 11, 10, 9, 0);
        final fila = [
          PacienteEspera(
            patientId: 'p1',
            nome: 'Ana',
            horaChegada: base,
            duracaoEstimadaMin: 20,
          ),
          PacienteEspera(
            patientId: 'p2',
            nome: 'Bruno',
            horaChegada: base.add(const Duration(minutes: 5)),
            duracaoEstimadaMin: 15,
          ),
          PacienteEspera(
            patientId: 'p3',
            nome: 'Carla',
            horaChegada: base.add(const Duration(minutes: 10)),
            duracaoEstimadaMin: 30,
          ),
        ];
        // WHEN / THEN - Bruno está em 2.º lugar
        expect(
          posicaoNaFila(fila, 'p2'),
          equals(2),
          reason: 'Bruno deve estar na posição 2 da fila',
        );
        // patientId desconhecido → null
        expect(
          posicaoNaFila(fila, 'desconhecido'),
          isNull,
          reason: 'patientId não presente na fila deve retornar null',
        );
      },
    );
  });

  // ===========================================================================
  group('faturas_recibos - filtragem de faturas', () {
    // lista de faturas de teste
    final todasFaturas = [
      Fatura(
        faturaId: 'f1',
        patientId: 'pA',
        valor: 50.0,
        estado: 'pago',
        data: DateTime(2025, 1, 10),
      ),
      Fatura(
        faturaId: 'f2',
        patientId: 'pA',
        valor: 75.0,
        estado: 'pendente',
        data: DateTime(2025, 2, 15),
      ),
      Fatura(
        faturaId: 'f3',
        patientId: 'pB',
        valor: 120.0,
        estado: 'pago',
        data: DateTime(2025, 3, 5),
      ),
      Fatura(
        faturaId: 'f4',
        patientId: 'pB',
        valor: 30.0,
        estado: 'pendente',
        data: DateTime(2025, 4, 20),
      ),
      Fatura(
        faturaId: 'f5',
        patientId: 'pC',
        valor: 200.0,
        estado: 'pendente',
        data: DateTime(2025, 5, 1),
      ),
    ];

    // TESTE 5 - Filtro por patientId devolve apenas faturas desse paciente
    test('filtro por patientId "pA" devolve apenas 2 faturas', () {
      // WHEN
      final resultado = filtrarFaturas(todasFaturas, patientId: 'pA');

      // THEN
      expect(
        resultado.length,
        equals(2),
        reason: 'Paciente pA tem exactamente 2 faturas na fixture',
      );
      expect(
        resultado.every((f) => f.patientId == 'pA'),
        isTrue,
        reason: 'Todas as faturas devolvidas devem pertencer ao paciente pA',
      );
    });

    // TESTE 6 - Filtro por estado 'pendente' devolve apenas faturas por pagar
    test('filtro por estado "pendente" devolve apenas faturas pendentes', () {
      // WHEN
      final resultado = filtrarFaturas(todasFaturas, estado: 'pendente');

      // THEN - f2, f4, f5
      expect(
        resultado.length,
        equals(3),
        reason: 'Devem existir 3 faturas pendentes na fixture',
      );
      expect(
        resultado.every((f) => f.estado == 'pendente'),
        isTrue,
        reason: 'Nenhuma fatura paga deve aparecer no filtro de pendentes',
      );
    });

    // TESTE 7 - Filtro combinado: patientId + estado
    test('filtro combinado (pB + pendente) devolve exactamente 1 fatura', () {
      // WHEN
      final resultado = filtrarFaturas(
        todasFaturas,
        patientId: 'pB',
        estado: 'pendente',
      );
      // THEN - apenas f4
      expect(
        resultado.length,
        equals(1),
        reason: 'Paciente pB tem apenas 1 fatura pendente',
      );
      expect(resultado.first.faturaId, equals('f4'));
    });
    // TESTE 8 - Lista vazia → resultado vazio sem crash
    test('filtrarFaturas com lista vazia retorna lista vazia sem crash', () {
      // GIVEN - nenhuma fatura registada ainda
      // WHEN
      final resultado = filtrarFaturas(
        [],
        patientId: 'qualquer',
        estado: 'pendente',
      );
      // THEN - sem exception, resultado vazio
      expect(
        resultado,
        isEmpty,
        reason: 'Lista vazia deve ser devolvida sem lançar excepções',
      );
    });
    // TESTE 9 - totalPendente calcula a soma correcta dos valores em aberto
    // O rececionista usa este valor para confirmar o pagamento.
    test(
      'totalPendente soma correctamente os valores das faturas pendentes',
      () {
        // GIVEN - faturas da fixture (f2=75, f4=30, f5=200)
        // WHEN
        final total = totalPendente(todasFaturas);
        // THEN - 75 + 30 + 200 = 305
        expect(
          total,
          closeTo(305.0, 0.01),
          reason: 'Soma das faturas pendentes deve ser 305€',
        );
      },
    );

    // TESTE 10 - totalPendente com todas pagas retorna 0
    test('totalPendente sem faturas pendentes retorna 0.0', () {
      // GIVEN - todas as faturas pagas
      final todasPagas = [
        Fatura(
          faturaId: 'x1',
          patientId: 'pX',
          valor: 50.0,
          estado: 'pago',
          data: DateTime(2025, 1, 1),
        ),
        Fatura(
          faturaId: 'x2',
          patientId: 'pX',
          valor: 100.0,
          estado: 'pago',
          data: DateTime(2025, 1, 2),
        ),
      ];
      // WHEN
      final total = totalPendente(todasPagas);
      // THEN
      expect(
        total,
        equals(0.0),
        reason: 'Sem faturas pendentes o total deve ser zero',
      );
    });
  });

  group('faturas_recibos - estados de UI', () {
    // TESTE 11 - Estado loading: indicador visível ao carregar faturas
    testWidgets('estado loading mostra CircularProgressIndicator', (
      tester,
    ) async {
      // GIVEN - faturas ainda a carregar do Supabase
      await tester.pumpWidget(const MaterialApp(home: _FaturasLoading()));
      await tester.pump();
      // THEN
      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
        reason:
            'Indicador de carregamento deve estar visível enquanto as faturas carregam',
      );
    });

    // TESTE 12 - Estado vazio: mensagem informativa visível
    testWidgets('estado vazio mostra mensagem "Sem faturas para mostrar."', (
      tester,
    ) async {
      // GIVEN - paciente sem histórico de faturas
      await tester.pumpWidget(const MaterialApp(home: _FaturasVazio()));
      await tester.pump();
      // THEN - mensagem amigável em vez de ecrã em branco
      expect(
        find.text('Sem faturas para mostrar.'),
        findsOneWidget,
        reason:
            'Estado vazio deve mostrar mensagem informativa, não ecrã em branco',
      );
    });
  });
}
