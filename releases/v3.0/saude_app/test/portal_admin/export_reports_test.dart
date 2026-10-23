import 'package:flutter_test/flutter_test.dart';

/// Replica de `_ExportReportsPageState._parseDate`
DateTime parseDate(String dmy) {
  final p = dmy.split('/');
  return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
}

/// Replica de `_ExportReportsPageState._formatDate`
String formatDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

/// Replica de `_ExportReportsPageState._toIso`
String toIso(String dmy) {
  final p = dmy.split('/');
  return '${p[2]}-${p[1].padLeft(2, '0')}-${p[0].padLeft(2, '0')}';
}

/// Replica do cálculo de meses no intervalo (usado em `_loadStats`)
int calcularMesesIntervalo(String dataInicio, String dataFim) {
  final start = parseDate(dataInicio);
  final end = parseDate(dataFim);
  return (end.year - start.year) * 12 + (end.month - start.month) + 1;
}

//  TESTES

void main() {

  //  _parseDate / _formatDate / _toIso
  group('export_reports - conversão de datas', () {
    // TESTE 1 - dd/mm/yyyy - DateTime com dia, mês e ano corretos
    test('parseDate converte "dd/mm/yyyy" para DateTime correto', () {
      final dt = parseDate('15/03/2026');
      expect(dt.day, 15);
      expect(dt.month, 3);
      expect(dt.year, 2026);
    });

    // TESTE 2 - zero-padding em dia e mês de 1 dígito na UI
    // Garante que "5/1/2026" não é exibido - deve mostrar "05/01/2026".
    test(
      'formatDate formata com zeros à esquerda para dia e mês de 1 dígito',
      () {
        expect(formatDate(DateTime(2026, 1, 5)), '05/01/2026');
        expect(formatDate(DateTime(2026, 12, 31)), '31/12/2026');
      },
    );

    // TESTE 3 - dd/mm/yyyy - yyyy-mm-dd para queries Supabase
    // Um formato errado produziria queries com datas erradas sem qualquer erro visível.
    test(
      'toIso converte "dd/mm/yyyy" para "yyyy-mm-dd" com padding correto',
      () {
        expect(toIso('05/01/2026'), '2026-01-05');
        expect(toIso('31/12/2025'), '2025-12-31');
        expect(toIso('01/06/2026'), '2026-06-01');
      },
    );

    // TESTE 4 - round-trip parseDate - formatDate é idempotente
    test('round-trip parseDate→formatDate é idempotente', () {
      const original = '15/03/2026';
      expect(formatDate(parseDate(original)), original);
    });
  });


  //  calcularMesesIntervalo

  group('export_reports - calcularMesesIntervalo', () {
    // TESTE 5 - mesmo mês = 1 mês
    test('intervalo de mesmo mês conta como 1 mês', () {
      expect(calcularMesesIntervalo('01/01/2026', '31/01/2026'), 1);
    });

    // TESTE 6 - trimestre = 3 meses (filtro padrão da página: 01/01 -> 31/03)
    test('intervalo de trimestre conta 3 meses', () {
      expect(calcularMesesIntervalo('01/01/2026', '31/03/2026'), 3);
    });

    // TESTE 7 - ano completo = 12 meses
    test('intervalo de ano completo conta 12 meses', () {
      expect(calcularMesesIntervalo('01/01/2026', '31/12/2026'), 12);
    });

    // TESTE 8 - intervalo multi-ano
    test('intervalo de dois anos conta corretamente', () {
      expect(calcularMesesIntervalo('01/07/2025', '30/06/2026'), 12);
    });
  });
}
