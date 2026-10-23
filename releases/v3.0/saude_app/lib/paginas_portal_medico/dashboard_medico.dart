import 'package:saude_app/paginas_portal_medico/portal_medico.dart';

//  Modelo local leve (só o que o dashboard usa)
class _AppointmentSummary {
  final String id;
  final String time; // "HH:MM"
  final String patientName;
  final String patientNif;
  final String type; // 'normal' | 'urgent' | 'follow_up'
  final String status; // 'scheduled' | 'completed' | ...

  const _AppointmentSummary({
    required this.id,
    required this.time,
    required this.patientName,
    required this.patientNif,
    required this.type,
    required this.status,
  });
}

class _QueueSummary {
  final String ticketNumber;
  final String nextPatientName;
  final int waitingCount;

  const _QueueSummary({
    required this.ticketNumber,
    required this.nextPatientName,
    required this.waitingCount,
  });
}

//  Dashboard principal - StatefulWidget
class DashboardMedico extends StatefulWidget {
  const DashboardMedico({super.key});

  @override
  State<DashboardMedico> createState() => _DashboardMedicoState();
}

class _DashboardMedicoState extends State<DashboardMedico> {
  // Dados do médico autenticado
  String _doctorName = '';
  String _doctorInitials = '';

  // Dados dinâmicos
  int _totalConsultasHoje = 0;
  _AppointmentSummary? _proximaConsulta;
  _QueueSummary? _queueSummary;
  List<_AppointmentSummary> _agendaHoje = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  // helpers
  String _formatTime(String timeStr) {
    // timeStr vem como "HH:MM:SS" ou "HH:MM" - mostrar só "HH:MM"
    return timeStr.substring(0, 5);
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'urgent':
        return 'Urgente';
      case 'follow_up':
        return 'Seguimento';
      default:
        return 'Normal';
    }
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  // carregamento de dados
  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1. Utilizador autenticado
      final userId = db.auth.currentUser?.id;
      if (userId == null) throw Exception('Sem sessão ativa');

      // 2. Nome do médico
      final userRow = await db
          .from('users')
          .select('name')
          .eq('id', userId)
          .single();
      final name = userRow['name'] as String? ?? '';
      final initials = _initials(name);

      // 3. Consultas de hoje
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final rows = await db
          .from('appointments')
          .select('''
            id,
            scheduled_time,
            type,
            status,
            patients!inner(
              user_id,
              health_number,
              users!inner(name, nif)
            )
          ''')
          .eq('doctor_id', userId)
          .eq('scheduled_date', todayStr)
          .neq('status', 'canceled')
          .isFilter('deleted_at', null)
          .order('scheduled_time', ascending: true);

      final List<_AppointmentSummary> agenda = [];
      for (final r in rows) {
        final patUser = r['patients']['users'];
        final nif = patUser['nif'] as String? ?? '---';
        final maskedNif = nif.length > 6
            ? '${nif.substring(0, 6)}-***'
            : '$nif-***';

        agenda.add(
          _AppointmentSummary(
            id: r['id'] as String,
            time: _formatTime(r['scheduled_time'] as String),
            patientName: patUser['name'] as String? ?? 'Desconhecido',
            patientNif: maskedNif,
            type: r['type'] as String? ?? 'normal',
            status: r['status'] as String? ?? 'scheduled',
          ),
        );
      }

      // Próxima consulta = primeira com status 'scheduled'
      final now = TimeOfDay.now();
      _AppointmentSummary? proxima;
      for (final a in agenda) {
        if (a.status == 'scheduled') {
          final parts = a.time.split(':');
          final apptTod = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
          // Compara minutos desde meia-noite
          final nowMins = now.hour * 60 + now.minute;
          final apptMins = apptTod.hour * 60 + apptTod.minute;
          if (apptMins >= nowMins) {
            proxima = a;
            break;
          }
        }
      }
      // Se não encontrou nenhuma futura, pega a última scheduled do dia
      proxima ??= agenda.where((a) => a.status == 'scheduled').lastOrNull;

      // 4. Fila virtual - entradas 'waiting' para este médico hoje
      final queueRows = await db
          .from('virtual_queue')
          .select('''
            ticket_number,
            queue_position,
            status,
            patients!inner(
              users!inner(name)
            )
          ''')
          .eq('doctor_id', userId)
          .eq('status', 'waiting')
          .order('queue_position', ascending: true);

      _QueueSummary? queue;
      if (queueRows.isNotEmpty) {
        final first = queueRows.first;
        queue = _QueueSummary(
          ticketNumber: first['ticket_number'] as String,
          nextPatientName:
              first['patients']['users']['name'] as String? ?? 'Desconhecido',
          waitingCount: queueRows.length,
        );
      }

      // 5. Atualiza estado
      if (!mounted) return;
      setState(() {
        _doctorName = name;
        _doctorInitials = initials;
        _totalConsultasHoje = agenda.length;
        _proximaConsulta = proxima;
        _queueSummary = queue;
        _agendaHoje = agenda;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  //  Build
  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final weekdays = [
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
      'Domingo',
    ];
    final months = [
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
    final dateLabel =
        '${weekdays[today.weekday - 1]}, ${today.day} ${months[today.month - 1]}';

    return TemplatePortalMedico(
      currentIndex: 0,
      userInitials: _doctorInitials.isEmpty ? '?' : _doctorInitials,
      child: _loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: CircularProgressIndicator(color: Color(0xFF3DBDAD)),
              ),
            )
          : _error != null
          ? _ErrorState(message: _error!, onRetry: _loadDashboard)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Saudação
                Text(
                  _greeting(_doctorName),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    fontFamily: 'Poppins',
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _totalConsultasHoje == 0
                      ? 'Sem consultas hoje'
                      : _totalConsultasHoje == 1
                      ? 'Tens 1 consulta hoje'
                      : 'Tens $_totalConsultasHoje consultas hoje',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6A9890),
                    fontFamily: 'Poppins',
                  ),
                ),

                const SizedBox(height: 22),

                // Próxima Consulta
                _SectionLabel(label: 'PRÓXIMA CONSULTA'),
                const SizedBox(height: 10),
                _proximaConsulta != null
                    ? _ProximaConsultaCard(
                        appt: _proximaConsulta!,
                        onRefresh: _loadDashboard,
                      )
                    : _EmptyCard(message: 'Sem consultas pendentes hoje'),

                const SizedBox(height: 22),

                // Fila Virtual
                _SectionLabel(label: 'FILA  VIRTUAL'),
                const SizedBox(height: 10),
                _queueSummary != null
                    ? _FilaVirtualCard(
                        queue: _queueSummary!,
                        onRefresh: _loadDashboard,
                      )
                    : _EmptyCard(message: 'Fila virtual vazia'),

                const SizedBox(height: 22),

                // Agenda Hoje
                _SectionLabel(label: 'AGENDA HOJE'),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6A9890),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const Schedule()),
                      ),
                      child: const Text(
                        'Ver completa →',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF50C4A5),
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFF50C4A5),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (_agendaHoje.isEmpty)
                  _EmptyCard(message: 'Agenda vazia hoje')
                else
                  ..._agendaHoje.map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ConsultaCard(
                        hora: a.time,
                        nome: a.patientName,
                        tipo: _typeLabel(a.type),
                        isUrgent: a.type == 'urgent',
                        isDone: a.status == 'completed',
                      ),
                    ),
                  ),

                const SizedBox(height: 28),

                // Ações Rápidas
                _SectionLabel(label: 'AÇÕES RÁPIDAS'),
                const SizedBox(height: 12),
                _AcoesRapidasGrid(onRefresh: _loadDashboard),

                const SizedBox(height: 10),
              ],
            ),
    );
  }

  String _greeting(String name) {
    final hour = DateTime.now().hour;
    String saudacao;
    if (hour < 12) {
      saudacao = 'Bom dia';
    } else if (hour < 19) {
      saudacao = 'Boa tarde';
    } else {
      saudacao = 'Boa noite';
    }
    // Pega apenas o primeiro apelido depois do primeiro nome
    final parts = name.trim().split(' ');
    final displayName = parts.length >= 2
        ? 'Dr. ${parts.last}'
        : name.isNotEmpty
        ? 'Dr. $name'
        : 'Doutor';
    return '$saudacao, $displayName!';
  }
}

//  Widgets auxiliares
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A8070),
        fontFamily: 'Poppins',
        letterSpacing: 0.5,
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF6A9890),
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFE65100), size: 40),
            const SizedBox(height: 12),
            Text(
              'Erro ao carregar dados:\n$message',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3DBDAD),
              ),
              child: const Text(
                'Tentar novamente',
                style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Próxima Consulta Card
class _ProximaConsultaCard extends StatelessWidget {
  final _AppointmentSummary appt;
  final VoidCallback onRefresh;
  const _ProximaConsultaCard({required this.appt, required this.onRefresh});

  String _typeLabel(String type) {
    switch (type) {
      case 'urgent':
        return 'Urgente';
      case 'follow_up':
        return 'Seguimento';
      default:
        return 'Normal';
    }
  }

  Color _badgeBg(String type) {
    switch (type) {
      case 'urgent':
        return const Color(0xFFFFE0CC);
      case 'follow_up':
        return const Color(0xFFE8F5E9);
      default:
        return const Color(0xFFD5EAFF);
    }
  }

  Color _badgeText(String type) {
    switch (type) {
      case 'urgent':
        return const Color(0xFFE65100);
      case 'follow_up':
        return const Color(0xFF2E7D32);
      default:
        return const Color(0xFF1A3B8B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0x233DBDAD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFbce6e1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appt.time,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A8070),
                        fontFamily: 'Poppins',
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${appt.patientName} - NIF ${appt.patientNif}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6A9890),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _badgeBg(appt.type),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 12,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _typeLabel(appt.type),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _badgeText(appt.type),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Consulta(appointmentId: appt.id),
                    ),
                  ).then((_) => onRefresh());
                },
                child: const Text(
                  'Ver detalhes',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF50C4A5),
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF50C4A5),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.check, size: 15, color: Color(0xFF50C4A5)),
              const SizedBox(width: 2),
              GestureDetector(
                onTap: () async {
                  // Marcar consulta como realizada
                  await db
                      .from('appointments')
                      .update({'status': 'completed'})
                      .eq('id', appt.id);
                  // Não temos acesso direto ao setState aqui - navegar ou
                  // usar um callback seria a solução. Por ora, mostra snackbar.
                  if (context.mounted) {
                    onRefresh();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Consulta marcada como realizada'),
                        backgroundColor: Color(0xFF3DBDAD),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Realizada',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF50C4A5),
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF50C4A5),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Fila Virtual Card
class _FilaVirtualCard extends StatelessWidget {
  final _QueueSummary queue;
  final VoidCallback onRefresh;
  const _FilaVirtualCard({required this.queue, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            queue.ticketNumber,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A8070),
              fontFamily: 'Poppins',
              height: 1,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Próxima:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6A9890),
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  queue.nextPatientName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6A9890),
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  'Em espera: ${queue.waitingCount} ${queue.waitingCount == 1 ? 'pessoa' : 'pessoas'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6A9890),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VirtualQueue()),
            ).then((_) => onRefresh()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF4DB0A0),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 16,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Text(
                'Ir →',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Consulta Card
class _ConsultaCard extends StatelessWidget {
  final String hora;
  final String nome;
  final String tipo;
  final bool isUrgent;
  final bool isDone;

  const _ConsultaCard({
    required this.hora,
    required this.nome,
    required this.tipo,
    required this.isUrgent,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final Color accentColor = isUrgent
        ? const Color(0xFFE65100)
        : const Color(0xFF3DBDAD);
    final Color textColor = isUrgent
        ? const Color(0xFFE65100)
        : Colors.black.withValues(alpha: 0.70);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xE5DAFDF9),
        borderRadius: BorderRadius.circular(15),
        border: Border(left: BorderSide(color: accentColor, width: 5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hora,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      nome,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      ' • ',
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      tipo,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isDone)
            const Icon(Icons.check, size: 18, color: Color(0xFF3DBDAD)),
        ],
      ),
    );
  }
}

// Ações Rápidas Grid
class _AcoesRapidasGrid extends StatelessWidget {
  final VoidCallback onRefresh;
  const _AcoesRapidasGrid({required this.onRefresh});

  static const List<_AcaoItem> _acoes = [
    _AcaoItem(label: 'Marcar Consulta', icon: Icons.event_available_outlined),
    _AcaoItem(label: 'Ver Agenda', icon: Icons.calendar_today_outlined),
    _AcaoItem(label: 'Fila Virtual', icon: Icons.confirmation_number_outlined),
    _AcaoItem(label: 'Pesquisar Paciente', icon: Icons.person_search_outlined),
    _AcaoItem(label: 'Bloquear Horário', icon: Icons.block_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.3,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: _acoes
          .map((a) => _AcaoCard(item: a, onRefresh: onRefresh))
          .toList(),
    );
  }
}

class _AcaoItem {
  final String label;
  final IconData icon;
  const _AcaoItem({required this.label, required this.icon});
}

class _AcaoCard extends StatelessWidget {
  final _AcaoItem item;
  final VoidCallback onRefresh;
  const _AcaoCard({required this.item, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Widget destination = const Schedule();
        if (item.label == 'Marcar Consulta') {
          destination = const MarcarConsulta();
        } else if (item.label == 'Ver Agenda') {
          destination = const Schedule();
        } else if (item.label == 'Fila Virtual') {
          destination = const VirtualQueue();
        } else if (item.label == 'Pesquisar Paciente') {
          destination = const Search();
        } else if (item.label == 'Bloquear Horário') {
          destination = const BlockSchedule();
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => destination),
        ).then((_) => onRefresh());
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 20,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 26, color: const Color(0xFF3DBDAD)),
            const SizedBox(height: 6),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A8070),
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
