import 'package:flutter_test/flutter_test.dart';

/// Replica de `_DashboardAdminState._relativeTime`
String relativeTime(String? isoString) {
  if (isoString == null) return '';
  final dt = DateTime.tryParse(isoString)?.toLocal();
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${dt.day}/${dt.month}';
}

/// Replica de `_DashboardAdminState._formatAtividade`
String formatAtividade(
  Map<String, dynamic> entry,
  String Function(String?) relFn,
) {
  final actor = (entry['actor'] as Map?)?['name'] as String? ?? 'Sistema';
  final desc = entry['description'] as String? ?? '';
  final time = relFn(entry['created_at'] as String?);
  final shortDesc = desc.length > 50 ? '${desc.substring(0, 50)}…' : desc;
  return '[$actor] $shortDesc - $time';
}

/// Replica da lógica de trend de pacientes em `_loadStats`
String buildTrendPacientes(int novosMes) =>
    novosMes > 0 ? '↑ + $novosMes este mês' : '- Sem novos este mês';

/// Replica da lógica de trend de consultas em `_loadStats`
String buildTrendConsultas(int consultasHoje, int consultasOntem) {
  if (consultasOntem == 0) {
    return consultasHoje > 0 ? '↑ + vs ontem' : '- Igual a ontem';
  }
  final diff = consultasHoje - consultasOntem;
  if (diff > 0) return '↑ + $diff vs ontem';
  if (diff < 0) return '↓ $diff vs ontem';
  return '- Igual a ontem';
}

//  TESTES

void main() {

  //  _relativeTime
  group('dashboard_admin - _relativeTime', () {
    // TESTE 1 - null não explode a UI
    // Garante que a UI não crasha quando audit_log tem created_at NULL.
    test('retorna string vazia para isoString null', () {
      expect(relativeTime(null), '');
    });

    // TESTE 2 - string não-ISO devolve vazio
    test('retorna string vazia para formato inválido', () {
      expect(relativeTime('nao-e-data'), '');
    });

    // TESTE 3 - menos de 60 minutos - "Xm"
    test('mostra minutos para diferença inferior a 1h', () {
      final dt = DateTime.now().subtract(const Duration(minutes: 25)).toUtc();
      final result = relativeTime(dt.toIso8601String());
      expect(result, endsWith('m'));
      expect(
        int.tryParse(result.replaceAll('m', '')),
        greaterThanOrEqualTo(24),
      );
    });

    // TESTE 4 - entre 1h e 24h - "Xh"
    test('mostra horas para diferença entre 1h e 24h', () {
      final dt = DateTime.now().subtract(const Duration(hours: 3)).toUtc();
      expect(relativeTime(dt.toIso8601String()), endsWith('h'));
    });

    // TESTE 5 - entre 1 e 6 dias - "Xd"
    test('mostra dias para diferença entre 1 e 6 dias', () {
      final dt = DateTime.now().subtract(const Duration(days: 3)).toUtc();
      expect(relativeTime(dt.toIso8601String()), endsWith('d'));
    });

    // TESTE 6 - 7+ dias - "dd/mm"
    test('mostra dd/mm para diferença superior a 7 dias', () {
      final result = relativeTime(DateTime(2026, 1, 15).toIso8601String());
      expect(result, contains('/'));
      expect(result, isNot(endsWith('d')));
    });
  });


  //  _formatAtividade
  group('dashboard_admin - _formatAtividade', () {
    String fakeRel(String? _) => '5m';

    // TESTE 7 - formato completo "[Actor] descrição - tempo"
    // Crítico: único ponto de exibição do audit_log ao administrador.
    test('formata entrada completa com actor, descrição e tempo', () {
      final entry = {
        'actor': {'name': 'Ana Silva'},
        'description': 'Utilizador criado com sucesso',
        'created_at': DateTime.now().toIso8601String(),
      };
      expect(
        formatAtividade(entry, fakeRel),
        '[Ana Silva] Utilizador criado com sucesso - 5m',
      );
    });

    // TESTE 8 - actor null - "Sistema"
    test('usa "Sistema" quando actor está ausente', () {
      final entry = {
        'actor': null,
        'description': 'Backup automático executado',
        'created_at': DateTime.now().toIso8601String(),
      };
      expect(formatAtividade(entry, fakeRel), startsWith('[Sistema]'));
    });

    // TESTE 9 - descrições longas truncadas a 50 chars + "…"
    // Garante que a UI não transborda com descrições extensas do audit_log.
    test('trunca descrição superior a 50 caracteres', () {
      final entry = {
        'actor': {'name': 'Bot'},
        'description': 'A' * 60,
        'created_at': DateTime.now().toIso8601String(),
      };
      final result = formatAtividade(entry, fakeRel);
      expect(result, contains('…'));
      final descPart = result.split('] ')[1].split(' - ')[0];
      expect(descPart.length, lessThanOrEqualTo(51)); // 50 + '…'
    });
  });


  //  Trends (pacientes e consultas)
  group('dashboard_admin - trends', () {
    // TESTE 10
    test('buildTrendPacientes mostra incremento quando novosMes > 0', () {
      expect(buildTrendPacientes(3), '↑ + 3 este mês');
    });

    // TESTE 11
    test('buildTrendPacientes mostra "Sem novos" quando novosMes == 0', () {
      expect(buildTrendPacientes(0), '- Sem novos este mês');
    });

    // TESTE 12
    test('buildTrendConsultas mostra subida vs ontem', () {
      expect(buildTrendConsultas(10, 7), '↑ + 3 vs ontem');
    });

    // TESTE 13
    test('buildTrendConsultas mostra descida vs ontem', () {
      expect(buildTrendConsultas(4, 7), '↓ -3 vs ontem');
    });

    // TESTE 14
    test('buildTrendConsultas mostra igual quando não há diferença', () {
      expect(buildTrendConsultas(5, 5), '- Igual a ontem');
    });

    // TESTE 15 - baseline zero com consultas hoje
    test('buildTrendConsultas indica subida quando ontem era zero', () {
      expect(buildTrendConsultas(3, 0), '↑ + vs ontem');
    });
  });
}
