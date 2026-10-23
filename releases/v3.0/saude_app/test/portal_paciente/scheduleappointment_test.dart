import 'package:flutter_test/flutter_test.dart';

/// Replica de `_ScheduleAppointment1PageState._initials`
/// Extrai as iniciais do nome completo (ex: "Carlos Ferreira" → "CF").
String calcularIniciais(String nomeCompleto) {
  final partes = nomeCompleto.trim().split(' ');
  if (partes.length == 1) return partes[0][0].toUpperCase();
  return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
}

/// Replica de `_ScheduleAppointment1PageState._medicosFiltrados` getter.
/// Filtra a lista de médicos por especialidade e/ou texto de pesquisa.
List<Map<String, dynamic>> filtrarMedicos({
  required List<Map<String, dynamic>> medicos,
  required List<Map<String, dynamic>> especialidades,
  required int? especialidadeIdx,
  required String pesquisa,
}) {
  return medicos.where((m) {
    final especialidadeDoMedico =
        (m['specialties'] as Map<String, dynamic>?)?['name'] as String? ?? '';
    final nomeDoMedico =
        (m['users'] as Map<String, dynamic>?)?['name'] as String? ?? '';

    final matchEsp =
        especialidadeIdx == null ||
        especialidadeDoMedico ==
            (especialidades[especialidadeIdx]['name'] as String);
    final matchPesq =
        pesquisa.isEmpty ||
        nomeDoMedico.toLowerCase().contains(pesquisa.toLowerCase()) ||
        especialidadeDoMedico.toLowerCase().contains(pesquisa.toLowerCase());

    return matchEsp && matchPesq;
  }).toList();
}

/// Replica da verificação de dia desativado no calendário:
/// dias passados (antes de hoje) e fins-de-semana são desativados.
bool isDiaDesativado(DateTime dia) {
  final isPast = dia.isBefore(DateTime.now().subtract(const Duration(days: 1)));
  final isWeekend = dia.weekday >= 6;
  return isPast || isWeekend;
}

/// Replica de `_ScheduleAppointment2PageState._selectDay` - parte dos slots ocupados:
/// dado o resultado da query Supabase (lista de {scheduled_time: ...}),
/// constrói o Set de slots ocupados no formato "HH:MM".
Set<String> calcularSlotsOcupados(List<dynamic> appointments) {
  return appointments
      .map((r) => (r['scheduled_time'] as String).substring(0, 5))
      .toSet();
}

/// Replica da deteção de overlap com blocked_slots.
/// Dado um dia, um slot "HH:MM" e uma lista de bloqueios (com start/end em ISO 8601),
/// retorna true se o slot estiver dentro de algum bloqueio.
bool isSlotBloqueado({
  required DateTime dia,
  required String slot,
  required List<dynamic> blockedSlots,
}) {
  final partes = slot.split(':');
  final slotDt = DateTime(
    dia.year,
    dia.month,
    dia.day,
    int.parse(partes[0]),
    int.parse(partes[1]),
  );
  for (final block in blockedSlots) {
    final start = DateTime.parse(block['start_datetime'] as String);
    final end = DateTime.parse(block['end_datetime'] as String);
    if (start.year == dia.year &&
        start.month == dia.month &&
        start.day == dia.day) {
      if (!slotDt.isBefore(start) && slotDt.isBefore(end)) return true;
    }
  }
  return false;
}

/// Replica de `_prevMonth` - verifica se é possível recuar no calendário.
/// Retorna true se o mês corrente é igual ao mês atual (não pode recuar mais).
bool podeRecuarMes(DateTime currentMonth) {
  final now = DateTime.now();
  return !(currentMonth.year == now.year && currentMonth.month == now.month);
}

/// Replica de `_nextMonth` - verifica se é possível avançar no calendário.
/// Limite: 12 meses a partir do mês atual.
bool podeAvancarMes(DateTime currentMonth) {
  final limit = DateTime(DateTime.now().year, DateTime.now().month + 12);
  return !(currentMonth.isAtSameMomentAs(limit) || currentMonth.isAfter(limit));
}

/// Replica do mapeamento tipo UI → enum BD (tipoParaEnum).
const Map<String, String> _tipoParaEnum = {
  'Normal': 'normal',
  'Urgência': 'urgent',
  'Acompanhamento': 'follow_up',
};

String mapearTipoParaEnum(String tipo) => _tipoParaEnum[tipo] ?? 'normal';

/// Replica da validação de sessão antes do INSERT em `_confirmar`.
String? validarSessao(String? userId) {
  if (userId == null) return 'Utilizador não autenticado.';
  return null;
}

/// Replica da construção do payload para o INSERT na tabela 'appointments'.
/// Recebe os campos necessários e devolve o Map pronto para o Supabase.
Map<String, dynamic> construirPayload({
  required String appointmentId,
  required String patientId,
  required String doctorId,
  required DateTime scheduledDate,
  required String hora,
  required String tipo,
  required String? notas,
}) {
  final dateStr =
      '${scheduledDate.year}-'
      '${scheduledDate.month.toString().padLeft(2, '0')}-'
      '${scheduledDate.day.toString().padLeft(2, '0')}';

  return {
    'id': appointmentId,
    'patient_id': patientId,
    'doctor_id': doctorId,
    'scheduled_date': dateStr,
    'scheduled_time': '${hora}:00',
    'type': mapearTipoParaEnum(tipo),
    'status': 'scheduled',
    'patient_notes': (notas == null || notas.isEmpty) ? null : notas,
    'created_by': patientId,
  };
}

/// Replica de `fmtDate` / `fmtTime` usadas na construção dos parâmetros
/// da query Supabase de verificação de conflito.
String fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String fmtTime(String slot) => '$slot:00';

//  TESTES

void main() {

  group('Page 1 - cálculo de iniciais do médico', () {
    // TESTE 1 - Nome composto: extrai primeira letra do primeiro e último nome
    // Usado no avatar do card do médico e passado à Page 2/3 como medicoInitials.
    // Um bug aqui exibe iniciais erradas em toda a cadeia de marcação.
    test('nome composto devolve iniciais do primeiro e último segmento', () {
      // GIVEN
      const nome = 'Carlos Ferreira';
      // WHEN
      final iniciais = calcularIniciais(nome);
      // THEN
      expect(
        iniciais,
        equals('CF'),
        reason:
            'Devem ser usadas a primeira letra do primeiro e do último nome',
      );
    });
    // TESTE 2 - Nome com múltiplas palavras (apelido composto)
    test('nome com três palavras usa primeira e última letra', () {
      // GIVEN
      const nome = 'Ana Maria Santos';
      // WHEN
      final iniciais = calcularIniciais(nome);
      // THEN
      expect(iniciais, equals('AS'));
    });
    // TESTE 3 - Nome com apenas uma palavra (edge case)
    test(
      'nome de uma só palavra devolve apenas a primeira letra em maiúscula',
      () {
        // GIVEN
        const nome = 'joao';
        // WHEN
        final iniciais = calcularIniciais(nome);
        // THEN
        expect(iniciais, equals('J'));
      },
    );
  });

  group('Page 1 - filtro de médicos', () {
    // Stub data: dois médicos com especialidades diferentes
    final medicos = [
      {
        'user_id': 'doc-1',
        'users': {'name': 'Carlos Ferreira'},
        'specialties': {'name': 'Clínica Geral'},
      },
      {
        'user_id': 'doc-2',
        'users': {'name': 'Ana Costa'},
        'specialties': {'name': 'Cardiologia'},
      },
    ];
    final especialidades = [
      {'id': 1, 'name': 'Clínica Geral'},
      {'id': 2, 'name': 'Cardiologia'},
    ];
    // TESTE 4 - Sem filtros: todos os médicos devem ser devolvidos
    test('sem filtros devolve todos os médicos', () {
      // WHEN
      final resultado = filtrarMedicos(
        medicos: medicos,
        especialidades: especialidades,
        especialidadeIdx: null,
        pesquisa: '',
      );
      // THEN
      expect(resultado.length, equals(2));
    });
    // TESTE 5 - Filtro por especialidade filtra corretamente
    test('filtro de especialidade idx=0 devolve apenas Clínica Geral', () {
      // WHEN
      final resultado = filtrarMedicos(
        medicos: medicos,
        especialidades: especialidades,
        especialidadeIdx: 0, // 'Clínica Geral'
        pesquisa: '',
      );
      // THEN
      expect(resultado.length, equals(1));
      expect(
        (resultado.first['users'] as Map)['name'],
        equals('Carlos Ferreira'),
      );
    });
    // TESTE 6 - Pesquisa por nome filtra corretamente (case-insensitive)
    test('pesquisa "costa" devolve apenas Ana Costa (case-insensitive)', () {
      // WHEN
      final resultado = filtrarMedicos(
        medicos: medicos,
        especialidades: especialidades,
        especialidadeIdx: null,
        pesquisa: 'costa',
      );
      // THEN
      expect(resultado.length, equals(1));
      expect((resultado.first['users'] as Map)['name'], equals('Ana Costa'));
    });
    // TESTE 7 - Pesquisa + especialidade sem match devolve lista vazia
    test('especialidade "Cardiologia" + pesquisa "Carlos" devolve vazio', () {
      // GIVEN - Carlos é Clínica Geral, não Cardiologia
      // WHEN
      final resultado = filtrarMedicos(
        medicos: medicos,
        especialidades: especialidades,
        especialidadeIdx: 1, // 'Cardiologia'
        pesquisa: 'Carlos',
      );
      // THEN
      expect(
        resultado,
        isEmpty,
        reason: 'Nenhum médico satisfaz ambos os critérios em simultâneo',
      );
    });
  });

  group('Page 2 - desativação de dias no calendário', () {
    // TESTE 8 - Dia no passado deve estar desativado
    test('dia de anteontem está desativado', () {
      // GIVEN - a condição de produção é .isBefore(now.subtract(days:1)),
      // pelo que "ontem à hora actual" fica exactamente no limite e não passa.
      // Dois dias atrás é inequivocamente passado.
      final anteontem = DateTime.now().subtract(const Duration(days: 2));
      // WHEN / THEN
      expect(
        isDiaDesativado(anteontem),
        isTrue,
        reason: 'Paciente não pode marcar consulta no passado',
      );
    });
    // TESTE 9 - Sábado deve estar desativado
    test('sábado está desativado (weekday == 6)', () {
      // GIVEN - encontra o próximo sábado
      var dia = DateTime.now().add(const Duration(days: 1));
      while (dia.weekday != 6) {
        dia = dia.add(const Duration(days: 1));
      }
      // WHEN / THEN
      expect(isDiaDesativado(dia), isTrue);
    });
    // TESTE 10 - Domingo deve estar desativado
    test('domingo está desativado (weekday == 7)', () {
      // GIVEN - encontra o próximo domingo
      var dia = DateTime.now().add(const Duration(days: 1));
      while (dia.weekday != 7) {
        dia = dia.add(const Duration(days: 1));
      }
      // WHEN / THEN
      expect(isDiaDesativado(dia), isTrue);
    });
    // TESTE 11 - Dia útil futuro deve estar ativo
    test('próxima segunda-feira está ativa', () {
      // GIVEN - encontra a próxima segunda
      var dia = DateTime.now().add(const Duration(days: 1));
      while (dia.weekday != 1) {
        dia = dia.add(const Duration(days: 1));
      }
      // WHEN / THEN
      expect(
        isDiaDesativado(dia),
        isFalse,
        reason: 'Dias úteis futuros devem estar disponíveis para marcação',
      );
    });
  });

  group('Page 2 - slots ocupados por consultas existentes', () {
    // TESTE 12 - Supabase devolve consultas → slots correspondentes marcados
    // Caso mais crítico: impede double-booking pelo paciente.
    test('slot presente nas consultas existentes é marcado como ocupado', () {
      // GIVEN - resultado simulado da query appointments
      final stubAppointments = [
        {'scheduled_time': '09:00:00'},
        {'scheduled_time': '14:30:00'},
      ];

      // WHEN
      final taken = calcularSlotsOcupados(stubAppointments);

      // THEN
      expect(taken.contains('09:00'), isTrue);
      expect(taken.contains('14:30'), isTrue);
      expect(
        taken.contains('10:00'),
        isFalse,
        reason: 'Slot não presente na BD deve estar disponível',
      );
    });
    // TESTE 13 - Sem consultas existentes → nenhum slot ocupado
    test('lista vazia de consultas não marca nenhum slot como ocupado', () {
      // WHEN
      final taken = calcularSlotsOcupados([]);

      // THEN
      expect(taken, isEmpty);
    });
  });

  group('Page 2 - overlap com blocked_slots do médico', () {
    final dia = DateTime(2025, 12, 15);
    // TESTE 14 - Slot dentro de um bloqueio → isSlotBloqueado = true
    // Ex: médico bloqueou 09:00-12:00, slot "10:00" está dentro → bloqueado.
    test('slot dentro do intervalo bloqueado retorna true', () {
      // GIVEN - bloqueio das 09:00 às 12:00 no mesmo dia
      final stubBloqueios = [
        {
          'start_datetime': '2025-12-15T09:00:00',
          'end_datetime': '2025-12-15T12:00:00',
        },
      ];

      // WHEN
      final bloqueado = isSlotBloqueado(
        dia: dia,
        slot: '10:00',
        blockedSlots: stubBloqueios,
      );

      // THEN
      expect(
        bloqueado,
        isTrue,
        reason: '10:00 está dentro do intervalo 09:00-12:00',
      );
    });

    // TESTE 15 - Slot no limite final do bloqueio → NÃO bloqueado (exclusivo)
    test(
      'slot exatamente no fim do bloqueio não está bloqueado (fim exclusivo)',
      () {
        // GIVEN - bloqueio termina às 12:00; slot "12:00" NÃO deve ser bloqueado
        final stubBloqueios = [
          {
            'start_datetime': '2025-12-15T09:00:00',
            'end_datetime': '2025-12-15T12:00:00',
          },
        ];

        // WHEN
        final bloqueado = isSlotBloqueado(
          dia: dia,
          slot: '12:00',
          blockedSlots: stubBloqueios,
        );

        // THEN
        expect(
          bloqueado,
          isFalse,
          reason:
              'O fim do intervalo é exclusivo - 12:00 deve estar disponível',
        );
      },
    );

    // TESTE 16 - Slot em dia diferente do bloqueio → NÃO bloqueado
    test('bloqueio noutro dia não afeta o dia selecionado', () {
      // GIVEN - bloqueio em 16 de Dezembro, dia selecionado é 15
      final stubBloqueios = [
        {
          'start_datetime': '2025-12-16T09:00:00',
          'end_datetime': '2025-12-16T12:00:00',
        },
      ];
      // WHEN
      final bloqueado = isSlotBloqueado(
        dia: dia,
        slot: '10:00',
        blockedSlots: stubBloqueios,
      );
      // THEN
      expect(bloqueado, isFalse);
    });

    // TESTE 17 - Sem bloqueios → nenhum slot bloqueado
    test('lista vazia de bloqueios não bloqueia nenhum slot', () {
      // WHEN
      final bloqueado = isSlotBloqueado(
        dia: dia,
        slot: '09:00',
        blockedSlots: [],
      );

      // THEN
      expect(bloqueado, isFalse);
    });
  });

  group('Page 2 - navegação de mês no calendário', () {
    // TESTE 18 - No mês atual NÃO se pode recuar
    test('podeRecuarMes retorna false quando já está no mês atual', () {
      // GIVEN
      final now = DateTime(DateTime.now().year, DateTime.now().month);

      // WHEN / THEN
      expect(
        podeRecuarMes(now),
        isFalse,
        reason: 'Não deve permitir navegar para meses no passado',
      );
    });

    // TESTE 19 - Num mês futuro PODE-SE recuar
    test('podeRecuarMes retorna true quando está num mês futuro', () {
      // GIVEN
      final mesFuturo = DateTime(DateTime.now().year, DateTime.now().month + 1);

      // WHEN / THEN
      expect(podeRecuarMes(mesFuturo), isTrue);
    });

    // TESTE 20 - Ao atingir o limite de 12 meses NÃO se pode avançar
    test('podeAvançarMes retorna false ao atingir o limite de 12 meses', () {
      // GIVEN
      final limite = DateTime(DateTime.now().year, DateTime.now().month + 12);

      // WHEN / THEN
      expect(
        podeAvancarMes(limite),
        isFalse,
        reason: 'Limite máximo de 12 meses no futuro deve ser respeitado',
      );
    });
  });

  group('Page 3 - mapeamento de tipo de consulta para enum da BD', () {
    // TESTE 21 - Tipos válidos mapeados corretamente
    // Um erro de mapeamento insere um valor inválido na coluna `type` da BD,
    // podendo violar constraints ou quebrar filtros no back-office.
    test('"Normal" mapeia para "normal"', () {
      expect(mapearTipoParaEnum('Normal'), equals('normal'));
    });

    test('"Urgência" mapeia para "urgent"', () {
      expect(mapearTipoParaEnum('Urgência'), equals('urgent'));
    });

    test('"Acompanhamento" mapeia para "follow_up"', () {
      expect(mapearTipoParaEnum('Acompanhamento'), equals('follow_up'));
    });

    // TESTE 22 - Tipo desconhecido cai em "normal" (fallback defensivo)
    test('tipo desconhecido devolve fallback "normal"', () {
      expect(
        mapearTipoParaEnum('Outro'),
        equals('normal'),
        reason: 'Fallback defensivo evita INSERT com valor null na BD',
      );
    });
  });

  group('Page 3 - validação de sessão antes do INSERT', () {
    // TESTE 23 - userId null → erro de sessão
    test('userId null retorna mensagem de autenticação', () {
      // WHEN
      final erro = validarSessao(null);
      // THEN
      expect(erro, equals('Utilizador não autenticado.'));
    });

    // TESTE 24 - userId presente → sem erro
    test('userId presente não retorna erro', () {
      // WHEN
      final erro = validarSessao('patient-uuid-123');

      // THEN
      expect(
        erro,
        isNull,
        reason: 'Sessão válida deve permitir avançar para o INSERT',
      );
    });
  });

  group('Page 3 - construção do payload para o INSERT', () {
    // TESTE 25 - Payload completo com notas
    test('payload com notas inclui patient_notes preenchido', () {
      // GIVEN
      final data = DateTime(2025, 12, 15);

      // WHEN
      final payload = construirPayload(
        appointmentId: 'appt-uuid-001',
        patientId: 'patient-uuid-123',
        doctorId: 'doctor-uuid-456',
        scheduledDate: data,
        hora: '10:30',
        tipo: 'Normal',
        notas: 'Trazer análises recentes',
      );

      // THEN
      expect(payload['scheduled_date'], equals('2025-12-15'));
      expect(payload['scheduled_time'], equals('10:30:00'));
      expect(payload['type'], equals('normal'));
      expect(payload['status'], equals('scheduled'));
      expect(payload['patient_notes'], equals('Trazer análises recentes'));
      expect(payload['created_by'], equals('patient-uuid-123'));
    });

    // TESTE 26 - Payload sem notas → patient_notes deve ser null
    // Importante: inserir string vazia quebraria validações no back-office.
    test('notas vazias resultam em patient_notes null no payload', () {
      // GIVEN
      final data = DateTime(2025, 6, 4);

      // WHEN
      final payload = construirPayload(
        appointmentId: 'appt-uuid-002',
        patientId: 'patient-uuid-123',
        doctorId: 'doctor-uuid-456',
        scheduledDate: data,
        hora: '14:00',
        tipo: 'Urgência',
        notas: '',
      );

      // THEN
      expect(
        payload['patient_notes'],
        isNull,
        reason: 'String vazia deve ser normalizada para null antes do INSERT',
      );
      expect(payload['type'], equals('urgent'));
    });

    // TESTE 27 - Data formatada com zero-padding correto
    // Um erro de formatação (ex: "2025-6-4" em vez de "2025-06-04") faz com
    // que a query de conflito nunca encontre duplicados na BD.
    test('fmtDate aplica zero-padding a mês e dia', () {
      // GIVEN
      final data = DateTime(2025, 6, 4);

      // WHEN
      final resultado = fmtDate(data);

      // THEN
      expect(
        resultado,
        equals('2025-06-04'),
        reason: 'Formato DATE do Postgres requer zero-padding',
      );
    });

    // TESTE 28 - Hora formatada com sufixo ":00" para segundos
    test('fmtTime adiciona ":00" de segundos ao slot', () {
      // GIVEN
      const slot = '09:30';

      // WHEN
      final resultado = fmtTime(slot);

      // THEN
      expect(
        resultado,
        equals('09:30:00'),
        reason: 'Tipo TIME do Postgres espera o campo de segundos',
      );
    });
  });
}
