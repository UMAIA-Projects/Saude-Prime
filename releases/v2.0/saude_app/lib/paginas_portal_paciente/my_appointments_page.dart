import 'package:saude_app/paginas_portal_paciente/portal_paciente.dart';

class _AppointmentRow {
  final String id;
  final String doctorId;   // UUID do médico — necessário para RescheduleAppointmentPage
  final String datetime;   // ex: "Qui, 3 Abr • 14:30"
  final String data;       // ex: "Qui, 3 Abr"
  final String hora;       // ex: "14:30"
  final String doctor;
  final String specialty;
  final String initials;
  final String telefone;
  final String status;     // "Agendada" | "Realizada" | "Cancelada"
  final String tipo;
  final String notas;

  const _AppointmentRow({
    required this.id,
    required this.doctorId,
    required this.datetime,
    required this.data,
    required this.hora,
    required this.doctor,
    required this.specialty,
    required this.initials,
    required this.telefone,
    required this.status,
    required this.tipo,
    required this.notas,
  });

  factory _AppointmentRow.fromSupabase(Map<String, dynamic> row) {
    final doctorMap  = row['doctor']      as Map<String, dynamic>? ?? {};
    final userMap    = doctorMap['users'] as Map<String, dynamic>? ?? {};
    final specMap    = doctorMap['specialties'] as Map<String, dynamic>? ?? {};
    final nomeCompleto = userMap['name'] as String? ?? '';
    final initials = nomeCompleto.trim().isNotEmpty
        ? nomeCompleto.trim().split(RegExp(r'\s+')).take(2)
            .map((p) => p[0].toUpperCase()).join()
        : '??';

    const statusMap = {
      'scheduled': 'Agendada',
      'completed': 'Realizada',
      'canceled' : 'Cancelada',
      'no_show'  : 'Falta',
    };
    final rawStatus = row['status'] as String? ?? '';
    final status    = statusMap[rawStatus] ?? rawStatus;

    const tipoMap = {
      'normal'    : 'Consulta Normal',
      'urgent'    : 'Urgente',
      'follow_up' : 'Seguimento',
    };
    final rawType = row['type'] as String? ?? '';
    final tipo    = tipoMap[rawType] ?? rawType;

    final scheduledDate = row['scheduled_date'] as String? ?? '';
    final scheduledTime = row['scheduled_time'] as String? ?? '';
    final dataFormatada = _formatarData(scheduledDate);
    final horaFormatada = scheduledTime.length >= 5
        ? scheduledTime.substring(0, 5)
        : scheduledTime;

    return _AppointmentRow(
      id:        row['id'] as String? ?? '',
      doctorId:  row['doctor_id'] as String? ?? '',
      datetime:  '$dataFormatada • $horaFormatada',
      data:      dataFormatada,
      hora:      horaFormatada,
      doctor:    nomeCompleto.isNotEmpty ? '$nomeCompleto' : 'Médico',
      specialty: specMap['name'] as String? ?? '',
      initials:  initials,
      telefone:  userMap['phone'] as String? ?? '',
      status:    status,
      tipo:      tipo,
      notas:     row['patient_notes'] as String? ?? '',
    );
  }

  static String _formatarData(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      const dias  = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
      const meses = [
        '', 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
        'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
      ];
      return '${dias[dt.weekday % 7]}, ${dt.day} ${meses[dt.month]}';
    } catch (_) {
      return iso;
    }
  }
}

// Serviço — queries ao Supabase

class _MyAppointmentsService {
  static final _db = Supabase.instance.client;

  static const _selectFields = '''
    id,
    doctor_id,
    scheduled_date,
    scheduled_time,
    type,
    status,
    patient_notes,
    doctor:doctors!appointments_doctor_id_fkey (
      users:users!doctors_user_id_fkey ( name, phone ),
      specialties:specialties!doctors_specialty_id_fkey ( name )
    )
  ''';

  /// Busca todas as consultas do paciente autenticado.
  static Future<List<_AppointmentRow>> fetchAll() async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Utilizador não autenticado.');

    final data = await _db
        .from('appointments')
        .select(_selectFields)
        .eq('patient_id', user.id)
        .isFilter('deleted_at', null)
        .order('scheduled_date', ascending: false)
        .order('scheduled_time', ascending: false);

    return (data as List<dynamic>)
        .map((r) => _AppointmentRow.fromSupabase(r as Map<String, dynamic>))
        .toList();
  }

  /// Cancela uma consulta.
  static Future<void> cancel(String appointmentId) async {
    await _db
        .from('appointments')
        .update({
          'status'    : 'canceled',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', appointmentId);
  }
}

// Página principal

class MyAppointmentsPage extends StatefulWidget {
  /// Passado por ScheduleAppointment3Page após confirmação — força refresh.
  final Map<String, String>? novaConsulta;

  const MyAppointmentsPage({super.key, this.novaConsulta});

  @override
  State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends State<MyAppointmentsPage> {
  static const Color _primary   = Color(0xFF1A8070);
  static const Color _textSub   = Color(0xFF3DBDAD);
  static const Color _textMuted = Color(0xFF6A9890);
  static const Color _accent    = Color(0xFF7CDACF);

  int _navIndex  = 1;
  int _activeTab = 0; // 0 = Próximas | 1 = Passadas | 2 = Canceladas

  final List<String> _tabs = ['Próximas', 'Passadas', 'Canceladas'];

  late Future<List<_AppointmentRow>> _futureRows;

  @override
  void initState() {
    super.initState();
    _futureRows = _MyAppointmentsService.fetchAll();
  }

  void _reload() {
    setState(() {
      _futureRows = _MyAppointmentsService.fetchAll();
    });
  }


  List<_AppointmentRow> _filter(List<_AppointmentRow> all) {
    switch (_activeTab) {
      case 0:
        return all.where((a) => a.status == 'Agendada').toList()
          ..sort(_compareAsc); // próximas: ordem ascendente
      case 1:
        return all.where((a) => a.status == 'Realizada' || a.status == 'Falta').toList();
      case 2:
        return all.where((a) => a.status == 'Cancelada').toList();
      default:
        return all;
    }
  }

  int _compareAsc(_AppointmentRow a, _AppointmentRow b) {
    // datetime label contém "Dia, D Mês • HH:MM" — compara como string ISO via _data
    return a.data.compareTo(b.data);
  }


  Color _badgeBgColor(String s) {
    switch (s) {
      case 'Realizada': return const Color(0xFFDFF5E3);
      case 'Cancelada': return const Color(0xFFFFE5E5);
      case 'Falta'    : return const Color(0xFFFFF3CD);
      default:          return const Color(0xFFD5EAFF);
    }
  }

  Color _badgeTextColor(String s) {
    switch (s) {
      case 'Realizada': return const Color(0xFF1A7A3C);
      case 'Cancelada': return const Color(0xFF8B1A1A);
      case 'Falta'    : return const Color(0xFF856404);
      default:          return const Color(0xFF1A3B8B);
    }
  }


  Future<void> _cancelar(String appointmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar consulta', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: const Text('Tens a certeza que queres cancelar esta consulta?', style: TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Não')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sim, cancelar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _MyAppointmentsService.cancel(appointmentId);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao cancelar: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return TemplatePortalPaciente(
      currentIndex: _navIndex,
      onNavTap: (i) => setState(() => _navIndex = i),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text(
              '< Voltar atrás',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A8070),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'As Minhas Consultas',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: List.generate(_tabs.length, (i) {
              final isActive = i == _activeTab;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeTab = i),
                  child: Column(
                    children: [
                      Text(
                        _tabs[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isActive ? _textSub : _textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 2,
                        color: isActive ? _textSub : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          FutureBuilder<List<_AppointmentRow>>(
            future: _futureRows,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: CircularProgressIndicator(color: _primary),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 40),
                      const Icon(Icons.error_outline, color: Colors.red, size: 36),
                      const SizedBox(height: 12),
                      Text(
                        'Erro ao carregar consultas:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _reload,
                        child: const Text(
                          'Tentar novamente',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: _primary,
                            decoration: TextDecoration.underline,
                            decorationColor: _primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final rows = _filter(snapshot.data!);

              if (rows.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      'Sem consultas nesta categoria.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: _textMuted,
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: rows.map((appt) => _AppointmentCard(
                  appt:           appt,
                  isUpcoming:     _activeTab == 0,
                  badgeBgColor:   _badgeBgColor(appt.status),
                  badgeTextColor: _badgeTextColor(appt.status),
                  onCancelar:     () => _cancelar(appt.id),
                  onVerDetalhes: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AppointmentDetailsPage(
                        appointmentId: appt.id,
                      ),
                    ),
                  ).then((_) => _reload()), // recarrega ao voltar
                  onReagendar: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RescheduleAppointmentPage(
                        appointmentId:       appt.id,
                        doctorId:            appt.doctorId,
                        medicoInitials:      appt.initials,
                        medicoNome:          appt.doctor,
                        medicoEspecialidade: appt.specialty,
                        data:                appt.data,
                        hora:                appt.hora,
                        tipo:                appt.tipo,
                        notas:               appt.notas,
                      ),
                    ),
                  ).then((_) => _reload()),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Card de consulta

class _AppointmentCard extends StatelessWidget {
  final _AppointmentRow appt;
  final bool       isUpcoming;
  final Color      badgeBgColor;
  final Color      badgeTextColor;
  final VoidCallback onCancelar;
  final VoidCallback onVerDetalhes;
  final VoidCallback onReagendar;

  static const Color _primary   = Color(0xFF1A8070);
  static const Color _textMuted = Color(0xFF6A9890);

  const _AppointmentCard({
    required this.appt,
    required this.isUpcoming,
    required this.badgeBgColor,
    required this.badgeTextColor,
    required this.onCancelar,
    required this.onVerDetalhes,
    required this.onReagendar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _primary, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 20,
              offset: Offset(0, 2),
              spreadRadius: -10,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Data + badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    appt.datetime,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      appt.status,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: badgeTextColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${appt.doctor} • ${appt.specialty}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: _textMuted,
                ),
              ),
              const SizedBox(height: 8),

              // Acções
              if (isUpcoming)
                Row(
                  children: [
                    _Link(label: 'Ver Detalhes', onTap: onVerDetalhes),
                    const SizedBox(width: 16),
                    _Link(label: 'Reagendar',   onTap: onReagendar),
                    const SizedBox(width: 16),
                    _Link(label: 'Cancelar',     onTap: onCancelar),
                  ],
                )
              else
                _Link(label: 'Ver Detalhes', onTap: onVerDetalhes),
            ],
          ),
        ),
      ),
    );
  }
}

class _Link extends StatelessWidget {
  final String       label;
  final VoidCallback onTap;

  static const Color _primary = Color(0xFF1A8070);

  const _Link({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _primary,
          decoration: TextDecoration.underline,
          decorationColor: _primary,
        ),
      ),
    );
  }
}
