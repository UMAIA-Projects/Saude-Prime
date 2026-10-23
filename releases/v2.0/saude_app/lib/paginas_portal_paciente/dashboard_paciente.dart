import 'package:saude_app/paginas_portal_paciente/portal_paciente.dart';

const Color _kPrimary     = Color(0xFF1A8070);
const Color _kSubtitle    = Color(0xFF6A9890);
const Color _kCardBg      = Colors.white;
const Color _kSenhaBg     = Color(0x233DBDAD);
const Color _kSenhaBorder = Color(0x473DBDAD);

const TextStyle _kSectionTitle = TextStyle(
  color: _kPrimary,
  fontSize: 12,
  fontFamily: 'Poppins',
  fontWeight: FontWeight.w700,
  letterSpacing: 0.5,
);

const TextStyle _kSubtitleStyle = TextStyle(
  color: _kSubtitle,
  fontSize: 12,
  fontFamily: 'Poppins',
  fontWeight: FontWeight.w400,
);

// MODELS

class _ProximaConsultaData {
  final String dataHora;      // ex: "Qui, 3 Apr • 14:30"
  final String medicoEspec;   // ex: "Dr. Carlos Menezes • Clínica Geral"
  final String status;        // ex: "scheduled"
  final String appointmentId;
  final String doctorId;      // necessário para RescheduleAppointmentPage

  const _ProximaConsultaData({
    required this.dataHora,
    required this.medicoEspec,
    required this.status,
    required this.appointmentId,
    required this.doctorId,
  });
}

class _SenhaData {
  final String ticketNumber;   // ex: "A-67"
  final String status;         // queue_status: 'waiting' | 'called' | 'attended' | 'absent'
  final int queuePosition;
  final String? currentTicket; // ticket que está a ser atendido agora

  const _SenhaData({
    required this.ticketNumber,
    required this.status,
    required this.queuePosition,
    this.currentTicket,
  });
}

class _NotificacaoData {
  final String id;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  const _NotificacaoData({
    required this.id,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  String get tempoRelativo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24)   return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

// SUPABASE SERVICE

class _DashboardService {
  static final _supabase = Supabase.instance.client;

  /// Devolve o UUID do paciente autenticado
  static String get _userId => _supabase.auth.currentUser!.id;

  static Future<String> fetchNome() async {
    final data = await _supabase
        .from('users')
        .select('name')
        .eq('id', _userId)
        .single();
    return data['name'] as String;
  }

  static Future<_ProximaConsultaData?> fetchProximaConsulta() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final rows = await _supabase
        .from('appointments')
        .select('''
          id,
          doctor_id,
          scheduled_date,
          scheduled_time,
          status,
          doctors!inner(
            users!inner(name),
            specialties!inner(name)
          )
        ''')
        .eq('patient_id', _userId)
        .eq('status', 'scheduled')
        .gte('scheduled_date', today)
        .order('scheduled_date', ascending: true)
        .order('scheduled_time', ascending: true)
        .limit(1);

    if (rows.isEmpty) return null;

    final row  = rows.first;
    final date = DateTime.parse(row['scheduled_date'] as String);
    final time = row['scheduled_time'] as String; // "HH:MM:SS"
    final hhmm = time.substring(0, 5);

    final weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    final months   = ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'];
    final dataFormatada =
        '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} • $hhmm';

    final doctorName  = row['doctors']['users']['name'] as String;
    final specialty   = row['doctors']['specialties']['name'] as String;
    final medicoEspec = '$doctorName • $specialty';

    return _ProximaConsultaData(
      dataHora:      dataFormatada,
      medicoEspec:   medicoEspec,
      status:        row['status'] as String,
      appointmentId: row['id'] as String,
      doctorId:      row['doctor_id'] as String? ?? '',
    );
  }

  static Future<_SenhaData?> fetchSenha() async {
    // Senha ativa do paciente (waiting ou called)
    final rows = await _supabase
        .from('virtual_queue')
        .select('id, ticket_number, status, queue_position, doctor_id')
        .eq('patient_id', _userId)
        .inFilter('status', ['waiting', 'called'])
        .order('issued_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) return null;

    final row      = rows.first;
    final doctorId = row['doctor_id'] as String;
    final myPos    = row['queue_position'] as int;

    // Ticket que está a ser atendido agora (called) para o mesmo médico
    final calledRows = await _supabase
        .from('virtual_queue')
        .select('ticket_number')
        .eq('doctor_id', doctorId)
        .eq('status', 'called')
        .order('queue_position', ascending: false)
        .limit(1);

    // Quantas senhas à frente (waiting com posição menor)
    final aFrente = await _supabase
        .from('virtual_queue')
        .select('id')
        .eq('doctor_id', doctorId)
        .eq('status', 'waiting')
        .lt('queue_position', myPos)
        .count(CountOption.exact);

    return _SenhaData(
      ticketNumber:  row['ticket_number'] as String,
      status:        row['status'] as String,
      queuePosition: myPos,
      currentTicket: calledRows.isNotEmpty
          ? calledRows.first['ticket_number'] as String
          : null,
    );
  }

  static Future<List<_NotificacaoData>> fetchNotificacoes({int limit = 5}) async {
    final rows = await _supabase
        .from('notifications')
        .select('id, message, created_at, is_read')
        .eq('user_id', _userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return rows.map((r) => _NotificacaoData(
      id:        r['id'] as String,
      message:   r['message'] as String,
      createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
      isRead:    r['is_read'] as bool,
    )).toList();
  }

  static Future<void> marcarNotificacaoLida(String id) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id)
        .eq('user_id', _userId);
  }
}

// STATE HOLDER  (InheritedWidget simples)

class _DashboardState {
  final String nome;
  final _ProximaConsultaData? consulta;
  final _SenhaData? senha;
  final List<_NotificacaoData> notificacoes;

  const _DashboardState({
    required this.nome,
    this.consulta,
    this.senha,
    required this.notificacoes,
  });
}

// PAGE

class DashboardPaciente extends StatefulWidget {
  const DashboardPaciente({super.key});

  @override
  State<DashboardPaciente> createState() => _DashboardPacienteState();
}

class _DashboardPacienteState extends State<DashboardPaciente> {
  late Future<_DashboardState> _futureDashboard;

  @override
  void initState() {
    super.initState();
    _futureDashboard = _carregarDados();
  }

  Future<_DashboardState> _carregarDados() async {
    final results = await Future.wait([
      _DashboardService.fetchNome(),
      _DashboardService.fetchProximaConsulta(),
      _DashboardService.fetchSenha(),
      _DashboardService.fetchNotificacoes(),
    ]);

    return _DashboardState(
      nome:          results[0] as String,
      consulta:      results[1] as _ProximaConsultaData?,
      senha:         results[2] as _SenhaData?,
      notificacoes:  results[3] as List<_NotificacaoData>,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _futureDashboard = _carregarDados();
    });
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePortalPaciente(
      currentIndex: 0,
      child: FutureBuilder<_DashboardState>(
        future: _futureDashboard,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _kPrimary),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded, color: _kSubtitle, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'Erro ao carregar dados.\nVerifica a tua ligação.',
                    textAlign: TextAlign.center,
                    style: _kSubtitleStyle,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _refresh,
                    child: const Text('Tentar novamente',
                        style: TextStyle(color: _kPrimary)),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;

          return RefreshIndicator(
            color: _kPrimary,
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DashboardHeader(nome: data.nome),
                  const SizedBox(height: 20),
                  _ProximaConsultaSection(consulta: data.consulta, onRefresh: _refresh),
                  if (data.senha != null) ...[
                    const SizedBox(height: 20),
                    _TuaSenha(senha: data.senha!),
                  ],
                  const SizedBox(height: 20),
                  const _AcessoRapido(),
                  if (data.notificacoes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _NotificacoesRecentes(
                      notificacoes: data.notificacoes,
                      onMarcarLida: (id) async {
                        await _DashboardService.marcarNotificacaoLida(id);
                        _refresh();
                      },
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// HEADER — Saudação e data

class _DashboardHeader extends StatelessWidget {
  final String nome;
  const _DashboardHeader({required this.nome});

  String get _dataHoje {
    final now = DateTime.now();
    const weekdays = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
    const months   = ['Janeiro','Fevereiro','Março','Abril','Maio','Junho',
                       'Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'];
    return '${weekdays[now.weekday - 1]}, ${now.day} de ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = nome.split(' ').first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Olá, $firstName!',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(_dataHoje, style: _kSubtitleStyle),
      ],
    );
  }
}

// PRÓXIMA CONSULTA

class _ProximaConsultaSection extends StatelessWidget {
  final _ProximaConsultaData? consulta;
  final VoidCallback onRefresh;
  const _ProximaConsultaSection({required this.consulta, required this.onRefresh});

  // Mapeia o status da BD para o badge visual
  ({String label, Color bg, Color text}) get _badgeInfo {
    switch (consulta?.status) {
      case 'scheduled':
        return (
          label: 'Agendada',
          bg: const Color(0xFFD5EAFF),
          text: const Color(0xFF1A3B8B),
        );
      case 'completed':
        return (
          label: 'Concluída',
          bg: const Color(0xFFD5FFE4),
          text: const Color(0xFF0D5C2B),
        );
      case 'canceled':
        return (
          label: 'Cancelada',
          bg: const Color(0xFFFFD5D5),
          text: const Color(0xFF8B1A1A),
        );
      default:
        return (
          label: 'Agendada',
          bg: const Color(0xFFD5EAFF),
          text: const Color(0xFF1A3B8B),
        );
    }
  }

  Future<void> _confirmarDesmarcar(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text(
          'Desmarcar consulta',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: const Text(
          'Tens a certeza que queres desmarcar esta consulta?',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Color(0xFF555555), height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _kPrimary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Cancelar', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: _kPrimary)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: const Text('Desmarcar', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ]),
        ],
      ),
    );

    if (confirm != true || consulta == null) return;

    try {
      await Supabase.instance.client
          .from('appointments')
          .update({
            'status':     'canceled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', consulta!.appointmentId);
      onRefresh();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao desmarcar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('PRÓXIMA CONSULTA', style: _kSectionTitle),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyAppointmentsPage()),
              ),
              child: const Text(
                'VER CONSULTAS',
                style: TextStyle(
                  color: _kPrimary,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w700,
                  decorationColor: _kPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (consulta == null)
          // Estado vazio
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 20,
                  offset: Offset(0, 2),
                  spreadRadius: -10,
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(Icons.event_available_outlined, color: _kSubtitle, size: 36),
                const SizedBox(height: 8),
                const Text(
                  'Sem consultas agendadas',
                  style: _kSubtitleStyle,
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScheduleAppointment1Page()),
                  ),
                  child: const Text(
                    'Marcar consulta',
                    style: TextStyle(
                      color: _kPrimary,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: _kPrimary,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(20),
              border: const Border(
                left: BorderSide(color: _kPrimary, width: 4),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 20,
                  offset: Offset(0, 2),
                  spreadRadius: -10,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      consulta!.dataHora,
                      style: const TextStyle(
                        color: _kPrimary,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    _StatusBadge(
                      label: _badgeInfo.label,
                      bgColor: _badgeInfo.bg,
                      textColor: _badgeInfo.text,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(consulta!.medicoEspec, style: _kSubtitleStyle),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _LinkText(
                      label: 'Ver detalhes',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AppointmentDetailsPage(
                            appointmentId: consulta!.appointmentId,
                          ),
                        ),
                      ).then((_) => onRefresh()),
                    ),
                    const SizedBox(width: 16),
                    _LinkText(
                      label: 'Remarcar',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RescheduleAppointmentPage(
                            appointmentId: consulta!.appointmentId,
                            doctorId:      consulta!.doctorId,
                            data:          consulta!.dataHora,
                            hora:          consulta!.dataHora.contains('•')
                                ? consulta!.dataHora.split('•').last.trim()
                                : '',
                          ),
                        ),
                      ).then((_) => onRefresh()),
                    ),
                    const SizedBox(width: 16),
                    _LinkText(
                      label: 'Desmarcar',
                      onTap: () => _confirmarDesmarcar(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// A TUA SENHA

class _TuaSenha extends StatelessWidget {
  final _SenhaData senha;
  const _TuaSenha({required this.senha});

  ({String label, Color bg, Color text}) get _badgeInfo {
    switch (senha.status) {
      case 'called':
        return (
          label: 'Chamado!',
          bg: const Color(0xFFD5EAFF),
          text: const Color(0xFF1A3B8B),
        );
      case 'waiting':
      default:
        return (
          label: 'À espera',
          bg: const Color(0xFFFFFAD5),
          text: const Color(0xFF6B5A00),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('A TUA SENHA', style: _kSectionTitle),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _kSenhaBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kSenhaBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 20,
                offset: Offset(0, 2),
                spreadRadius: -10,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    senha.ticketNumber,
                    style: const TextStyle(
                      color: _kPrimary,
                      fontSize: 28,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                  _StatusBadge(
                    label: _badgeInfo.label,
                    bgColor: _badgeInfo.bg,
                    textColor: _badgeInfo.text,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (senha.currentTicket != null)
                Text(
                  'A ser atendido: ${senha.currentTicket}',
                  style: _kSubtitleStyle,
                ),
              const SizedBox(height: 2),
              Text(
                '${senha.queuePosition} à frente na fila',
                style: _kSubtitleStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ACESSO RÁPIDO

class _AcessoRapido extends StatelessWidget {
  const _AcessoRapido();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ACESSO RÁPIDO', style: _kSectionTitle),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _QuickAccessCard(
                svgAsset: 'assets/imagens_portal_paciente/calendar.svg',
                label: 'Marcar Consulta',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScheduleAppointment1Page()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAccessCard(
                svgAsset: 'assets/imagens_portal_paciente/documents.svg',
                label: 'Consultar Documentos',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DocumentsScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickAccessCard(
                fallbackIcon: Icons.menu_book_outlined,
                label: 'Histórico Clínico',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClinicHistoryScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAccessCard(
                fallbackIcon: Icons.notifications_outlined,
                label: 'Notificações',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// NOTIFICAÇÕES RECENTES

class _NotificacoesRecentes extends StatelessWidget {
  final List<_NotificacaoData> notificacoes;
  final Future<void> Function(String id) onMarcarLida;

  const _NotificacoesRecentes({
    required this.notificacoes,
    required this.onMarcarLida,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('NOTIFICAÇÕES RECENTES', style: _kSectionTitle),
        const SizedBox(height: 10),
        ...notificacoes.asMap().entries.map((entry) {
          final idx   = entry.key;
          final notif = entry.value;
          return Column(
            children: [
              GestureDetector(
                onTap: notif.isRead ? null : () => onMarcarLida(notif.id),
                child: _NotificacaoItem(
                  texto: notif.message,
                  tempo: notif.tempoRelativo,
                  isRead: notif.isRead,
                ),
              ),
              if (idx < notificacoes.length - 1)
                const Divider(color: _kPrimary, thickness: 0.5, height: 16),
            ],
          );
        }),
      ],
    );
  }
}

// REUSABLE SUB-WIDGETS

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;

  const _StatusBadge({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 8,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LinkText extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LinkText({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          color: _kPrimary,
          fontSize: 12,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
          decorationColor: _kPrimary,
        ),
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final String? svgAsset;
  final IconData? fallbackIcon;
  final String label;
  final VoidCallback onTap;

  const _QuickAccessCard({
    this.svgAsset,
    this.fallbackIcon,
    required this.label,
    required this.onTap,
  }) : assert(svgAsset != null || fallbackIcon != null,
            'Fornece svgAsset ou fallbackIcon');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 20,
              offset: Offset(0, 2),
              spreadRadius: -10,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (svgAsset != null)
              SvgPicture.asset(
                svgAsset!,
                width: 34,
                height: 34,
                colorFilter: const ColorFilter.mode(_kPrimary, BlendMode.srcIn),
              )
            else
              Icon(fallbackIcon, color: _kPrimary, size: 34),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _kPrimary,
                fontSize: 10,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificacaoItem extends StatelessWidget {
  final String texto;
  final String tempo;
  final bool isRead;

  const _NotificacaoItem({
    required this.texto,
    required this.tempo,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Bullet point (opaco se lida)
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isRead ? _kSubtitle.withOpacity(0.4) : _kPrimary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isRead
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x3F000000),
                      blurRadius: 20,
                      offset: Offset(0, 2),
                      spreadRadius: -10,
                    ),
                  ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texto,
            style: _kSubtitleStyle.copyWith(
              color: isRead ? _kSubtitle.withOpacity(0.6) : _kSubtitle,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(tempo, style: _kSubtitleStyle),
      ],
    );
  }
}
