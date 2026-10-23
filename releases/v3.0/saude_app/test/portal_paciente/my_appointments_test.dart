import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Replica `_AppointmentRow._formatarData`.
String formatarData(String iso) {
  if (iso.isEmpty) return '';
  try {
    final dt = DateTime.parse(iso);
    const dias = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    const meses = [
      '',
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return '${dias[dt.weekday % 7]}, ${dt.day} ${meses[dt.month]}';
  } catch (_) {
    return iso;
  }
}

/// Replica o cálculo de iniciais em `_AppointmentRow.fromSupabase`.
String calcularIniciaisMedico(String nomeCompleto) {
  if (nomeCompleto.trim().isEmpty) return '??';
  return nomeCompleto
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();
}

/// Replica o `statusMap` de `_AppointmentRow.fromSupabase`.
const Map<String, String> _statusMap = {
  'scheduled': 'Agendada',
  'completed': 'Realizada',
  'canceled': 'Cancelada',
  'no_show': 'Falta',
};
String mapearStatus(String rawStatus) => _statusMap[rawStatus] ?? rawStatus;

/// Replica o `tipoMap` de `_AppointmentRow.fromSupabase`.
const Map<String, String> _tipoMap = {
  'normal': 'Consulta Normal',
  'urgent': 'Urgente',
  'follow_up': 'Seguimento',
};
String mapearTipo(String rawType) => _tipoMap[rawType] ?? rawType;

/// Replica `_filter` de `_MyAppointmentsPageState`.
/// tab 0 = Próximas (Agendada), tab 1 = Passadas (Realizada|Falta), tab 2 = Canceladas.
List<String> filtrarConsultas({
  required List<String> statuses,
  required int tab,
}) {
  switch (tab) {
    case 0:
      return statuses.where((s) => s == 'Agendada').toList();
    case 1:
      return statuses.where((s) => s == 'Realizada' || s == 'Falta').toList();
    case 2:
      return statuses.where((s) => s == 'Cancelada').toList();
    default:
      return statuses;
  }
}

/// Replica a regra das 24 horas em `_cancelar`.
/// Retorna true se o cancelamento é permitido (>= 24h antes da consulta).
bool canCancelar({required DateTime dataConsulta}) {
  final horasFaltam = dataConsulta.difference(DateTime.now()).inHours;
  return horasFaltam >= 24;
}

/// Replica `_badgeBgColor` de `_MyAppointmentsPageState`.
Color badgeBgColor(String status) {
  switch (status) {
    case 'Realizada':
      return const Color(0xFFDFF5E3);
    case 'Cancelada':
      return const Color(0xFFFFE5E5);
    case 'Falta':
      return const Color(0xFFFFF3CD);
    default:
      return const Color(0xFFD5EAFF); // Agendada
  }
}

/// Replica `_badgeTextColor` de `_MyAppointmentsPageState`.
Color badgeTextColor(String status) {
  switch (status) {
    case 'Realizada':
      return const Color(0xFF1A7A3C);
    case 'Cancelada':
      return const Color(0xFF8B1A1A);
    case 'Falta':
      return const Color(0xFF856404);
    default:
      return const Color(0xFF1A3B8B); // Agendada
  }
}

//  TESTES

void main() {
  group('_AppointmentRow - formatação de data ISO para display', () {
    // TESTE 1 - Data válida formata corretamente
    // Exibida no card de cada consulta. Um bug aqui afecta todas as consultas.
    test('2025-12-15 formata para "Seg, 15 Dez"', () {
      expect(formatarData('2025-12-15'), equals('Seg, 15 Dez'));
    });

    test('2025-06-04 (quarta-feira) formata para "Qua, 4 Jun"', () {
      expect(formatarData('2025-06-04'), equals('Qua, 4 Jun'));
    });

    // TESTE 2 - String vazia → string vazia (sem crash)
    test('string vazia devolve string vazia', () {
      expect(formatarData(''), equals(''));
    });

    // TESTE 3 - Data inválida → devolve o valor original (fallback seguro)
    test('data inválida devolve o valor original sem lançar exceção', () {
      expect(formatarData('not-a-date'), equals('not-a-date'));
    });
  });

  group('_AppointmentRow - cálculo de iniciais do médico', () {
    // TESTE 4 - Nome e apelido → duas iniciais
    test('nome e apelido devolvem duas iniciais em maiúscula', () {
      expect(calcularIniciaisMedico('Carlos Ferreira'), equals('CF'));
    });

    // TESTE 5 - Nome composto: usa apenas os dois primeiros tokens
    test('nome com três palavras usa as duas primeiras iniciais', () {
      expect(calcularIniciaisMedico('Ana Maria Santos'), equals('AM'));
    });

    // TESTE 6 - Nome vazio → fallback '??'
    // Evita crash no widget de avatar quando o médico não tem nome na BD.
    test('nome vazio devolve fallback "??"', () {
      expect(calcularIniciaisMedico(''), equals('??'));
    });
  });

  group('_AppointmentRow - mapeamento de status e tipo da BD', () {
    // TESTE 7 - Todos os status conhecidos mapeados corretamente
    // Se 'scheduled' → 'Agendada' falhar, a tab "Próximas" fica sempre vazia.
    test('"scheduled" mapeia para "Agendada"', () {
      expect(mapearStatus('scheduled'), equals('Agendada'));
    });

    test('"completed" mapeia para "Realizada"', () {
      expect(mapearStatus('completed'), equals('Realizada'));
    });

    test('"canceled" mapeia para "Cancelada"', () {
      expect(mapearStatus('canceled'), equals('Cancelada'));
    });

    test('"no_show" mapeia para "Falta"', () {
      expect(mapearStatus('no_show'), equals('Falta'));
    });

    // TESTE 8 - Status desconhecido → devolve o valor raw (não crash)
    test('status desconhecido devolve o valor original', () {
      expect(mapearStatus('pending'), equals('pending'));
    });

    // TESTE 9 - Todos os tipos de consulta mapeados corretamente
    test('"normal" mapeia para "Consulta Normal"', () {
      expect(mapearTipo('normal'), equals('Consulta Normal'));
    });

    test('"urgent" mapeia para "Urgente"', () {
      expect(mapearTipo('urgent'), equals('Urgente'));
    });

    test('"follow_up" mapeia para "Seguimento"', () {
      expect(mapearTipo('follow_up'), equals('Seguimento'));
    });
  });

  group('_filter - distribuição de consultas pelas tabs', () {
    // Stub: lista mista de consultas com diferentes statuses
    final statuses = [
      'Agendada',
      'Agendada',
      'Realizada',
      'Cancelada',
      'Falta',
    ];

    // TESTE 10 - Tab "Próximas" (0) inclui apenas Agendadas
    // Crítico: tab vazia em produção com consultas ativas seria um bug grave.
    test('tab Próximas devolve apenas consultas "Agendada"', () {
      final resultado = filtrarConsultas(statuses: statuses, tab: 0);
      expect(resultado.length, equals(2));
      expect(resultado.every((s) => s == 'Agendada'), isTrue);
    });

    // TESTE 11 - Tab "Passadas" (1) inclui Realizadas e Faltas
    test('tab Passadas devolve consultas "Realizada" e "Falta"', () {
      final resultado = filtrarConsultas(statuses: statuses, tab: 1);
      expect(resultado.length, equals(2));
      expect(resultado.every((s) => s == 'Realizada' || s == 'Falta'), isTrue);
    });

    // TESTE 12 - Tab "Canceladas" (2) inclui apenas Canceladas
    test('tab Canceladas devolve apenas consultas "Cancelada"', () {
      final resultado = filtrarConsultas(statuses: statuses, tab: 2);
      expect(resultado.length, equals(1));
      expect(resultado.first, equals('Cancelada'));
    });

    // TESTE 13 - Tab sem resultados devolve lista vazia (não null)
    test('tab sem resultados devolve lista vazia sem crash', () {
      final resultado = filtrarConsultas(
        statuses: ['Realizada', 'Cancelada'],
        tab: 0, // Próximas
      );
      expect(resultado, isEmpty);
    });
  });

  group('Cancelamento - regra das 24 horas', () {
 
    // TESTE 14 - Consulta mais de 24h no futuro → cancelamento permitido
 
    // Caso normal: paciente cancela com antecedência suficiente.
    test('consulta a mais de 24h permite cancelamento', () {
      final consulta = DateTime.now().add(const Duration(hours: 25));

      expect(
        canCancelar(dataConsulta: consulta),
        isTrue,
        reason:
            'Cancelamento deve ser permitido com mais de 24h de antecedência',
      );
    });

    // TESTE 15 - Consulta a menos de 24h → cancelamento bloqueado
    // Regra de negócio da política de cancelamento exibida na Page 3.
    test('consulta a menos de 24h bloqueia o cancelamento', () {
      final consulta = DateTime.now().add(const Duration(hours: 12));

      expect(
        canCancelar(dataConsulta: consulta),
        isFalse,
        reason:
            'Cancelamento deve ser bloqueado com menos de 24h de antecedência',
      );
    });

    // TESTE 16 - Consulta no passado → cancelamento bloqueado
    test('consulta no passado bloqueia o cancelamento', () {
      final consulta = DateTime.now().subtract(const Duration(hours: 2));

      expect(
        canCancelar(dataConsulta: consulta),
        isFalse,
        reason: 'Não é possível cancelar uma consulta que já passou',
      );
    });

    // TESTE 17 - Exactamente 24h no futuro → limite da fronteira
    // A regra usa inHours: 23h59m → 23 horas → bloqueado.
    // 24h00m → 24 horas → permitido.
    test('exactamente 24h no futuro (inHours=24) está no limite permitido', () {
      final consulta = DateTime.now().add(
        const Duration(hours: 24, minutes: 1),
      );

      expect(
        canCancelar(dataConsulta: consulta),
        isTrue,
        reason: 'Exatamente 24h de antecedência deve ser permitido',
      );
    });
  });

  group('Badges - cores de status das consultas', () {
    // TESTE 18 - Cada status tem a cor de fundo correta
    // Erros de cor são silenciosos mas criam confusão visual para o paciente.
    test('"Agendada" usa fundo azul claro', () {
      expect(badgeBgColor('Agendada'), equals(const Color(0xFFD5EAFF)));
    });

    test('"Realizada" usa fundo verde claro', () {
      expect(badgeBgColor('Realizada'), equals(const Color(0xFFDFF5E3)));
    });

    test('"Cancelada" usa fundo vermelho claro', () {
      expect(badgeBgColor('Cancelada'), equals(const Color(0xFFFFE5E5)));
    });

    test('"Falta" usa fundo amarelo claro', () {
      expect(badgeBgColor('Falta'), equals(const Color(0xFFFFF3CD)));
    });

    // TESTE 19 - Cores de texto distintas para "Cancelada" e "Realizada"
    test('"Cancelada" usa cor de texto vermelho escuro', () {
      expect(badgeTextColor('Cancelada'), equals(const Color(0xFF8B1A1A)));
    });

    test('"Realizada" usa cor de texto verde escuro', () {
      expect(badgeTextColor('Realizada'), equals(const Color(0xFF1A7A3C)));
    });
  });
}
