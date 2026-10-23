import 'package:flutter_test/flutter_test.dart';

enum DayMark { livre, consultas, bloqueado, ambos }

/// Replica de `_SchedulesPageState._mergeMark`
DayMark mergeMark(
  DayMark? cur, {
  bool hasConsulta = false,
  bool hasBlock = false,
}) {
  final c = cur == DayMark.consultas || cur == DayMark.ambos || hasConsulta;
  final b = cur == DayMark.bloqueado || cur == DayMark.ambos || hasBlock;
  if (c && b) return DayMark.ambos;
  if (c) return DayMark.consultas;
  if (b) return DayMark.bloqueado;
  return DayMark.livre;
}

/// Replica de `_SchedulesPageState._fmtDate`
String fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

//  TESTES

void main() {
  //  _mergeMark
  group('schedules - _mergeMark', () {
    // TESTE 1 - sem nada - livre
    test('sem consultas nem bloqueios devolve livre', () {
      expect(mergeMark(null), DayMark.livre);
    });

    // TESTE 2 - só consultas - consultas
    test('só com consultas devolve consultas', () {
      expect(mergeMark(null, hasConsulta: true), DayMark.consultas);
    });

    // TESTE 3 - só bloqueio - bloqueado  (#6 Alteração de Horário)
    test('só com bloqueio devolve bloqueado', () {
      expect(mergeMark(null, hasBlock: true), DayMark.bloqueado);
    });

    // TESTE 4 - consultas + bloqueio em simultâneo - ambos
    // Dia com consultas existentes e bloqueio parcial adicionado.
    test('consultas e bloqueio simultaneamente devolvem ambos', () {
      expect(mergeMark(null, hasConsulta: true, hasBlock: true), DayMark.ambos);
    });

    // TESTE 5 - acumulação: consultas + novo bloqueio - ambos
    test('estado consultas acumulado com bloqueio devolve ambos', () {
      expect(mergeMark(DayMark.consultas, hasBlock: true), DayMark.ambos);
    });

    // TESTE 6 - acumulação: bloqueado + nova consulta - ambos
    test('estado bloqueado acumulado com consulta devolve ambos', () {
      expect(mergeMark(DayMark.bloqueado, hasConsulta: true), DayMark.ambos);
    });

    // TESTE 7 - estado "ambos" mantém-se sem novos flags
    test('estado ambos mantém-se sem novos inputs', () {
      expect(mergeMark(DayMark.ambos), DayMark.ambos);
    });

    // TESTE 8 - cancelamento (#10): dia livre mantém-se livre
    // Após cancelamento sem outras consultas o dia deve voltar a livre.
    test('sem flags no estado livre mantém livre', () {
      expect(mergeMark(DayMark.livre), DayMark.livre);
    });

    // TESTE 9 - estado "ambos" acumula mais consultas sem regredir
    test('estado ambos permanece ambos ao adicionar mais consultas', () {
      expect(mergeMark(DayMark.ambos, hasConsulta: true), DayMark.ambos);
    });
  });

  //  _fmtDate
  group('schedules - _fmtDate', () {
    // TESTE 10 - formato yyyy-mm-dd com zero-padding para queries Supabase
    // Um formato errado produziria queries sem resultados silenciosamente.
    test('formata data como yyyy-mm-dd com zeros à esquerda', () {
      expect(fmtDate(DateTime(2026, 1, 5)), '2026-01-05');
      expect(fmtDate(DateTime(2026, 12, 31)), '2026-12-31');
      expect(fmtDate(DateTime(2026, 6, 9)), '2026-06-09');
    });
  });
}
