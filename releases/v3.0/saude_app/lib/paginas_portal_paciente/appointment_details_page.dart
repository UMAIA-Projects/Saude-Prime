import 'package:saude_app/paginas_portal_paciente/portal_paciente.dart';

class AppointmentDetail {
  final String id;
  final String doctorId;
  final String medicoInitials;
  final String medicoNome;
  final String medicoEspecialidade;
  final String medicoTelefone;
  final String estado;
  final String data;
  final String hora;
  final String tipo;
  final String notas;
  final List<DocumentoItem> documentos;

  const AppointmentDetail({
    required this.id,
    required this.doctorId,
    required this.medicoInitials,
    required this.medicoNome,
    required this.medicoEspecialidade,
    required this.medicoTelefone,
    required this.estado,
    required this.data,
    required this.hora,
    required this.tipo,
    required this.notas,
    required this.documentos,
  });

  /// Constrói a partir do JSON devolvido pelo Supabase.
  /// A query deve fazer join com users, specialties e documents.
  factory AppointmentDetail.fromSupabase(Map<String, dynamic> row) {
    final doctorUser = row['doctor_user'] as Map<String, dynamic>? ?? {};
    final specialty = row['specialty'] as Map<String, dynamic>? ?? {};
    final nomeMedico = doctorUser['name'] as String? ?? '';
    final initials = nomeMedico.trim().isNotEmpty
        ? nomeMedico
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((p) => p[0].toUpperCase())
              .join()
        : '??';

    final statusMap = {
      'scheduled': 'Agendada',
      'completed': 'Realizada',
      'canceled': 'Cancelada',
      'no_show': 'Falta',
    };
    final rawStatus = row['status'] as String? ?? '';
    final estado = statusMap[rawStatus] ?? rawStatus;

    final tipoMap = {
      'normal': 'Consulta Normal',
      'urgent': 'Urgente',
      'follow_up': 'Acompanhamento',
    };
    final rawType = row['type'] as String? ?? '';
    final tipo = tipoMap[rawType] ?? rawType;

    final scheduledDate = row['scheduled_date'] as String? ?? '';
    final scheduledTime = row['scheduled_time'] as String? ?? '';
    final dataFormatada = _formatarData(scheduledDate);
    final horaFormatada = scheduledTime.length >= 5
        ? scheduledTime.substring(0, 5)
        : scheduledTime;

    final rawDocs = row['documents'] as List<dynamic>? ?? [];
    final documentos = rawDocs
        .map((d) => DocumentoItem.fromSupabase(d as Map<String, dynamic>))
        .toList();

    return AppointmentDetail(
      id: row['id'] as String? ?? '',
      doctorId: row['doctor_id'] as String? ?? '',
      medicoInitials: initials,
      medicoNome: nomeMedico.isNotEmpty ? '$nomeMedico' : 'Médico desconhecido',
      medicoEspecialidade: specialty['name'] as String? ?? '',
      medicoTelefone: doctorUser['phone'] as String? ?? '',
      estado: estado,
      data: dataFormatada,
      hora: horaFormatada,
      tipo: tipo,
      notas: row['patient_notes'] as String? ?? '',
      documentos: documentos,
    );
  }

  static String _formatarData(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      const diasSemana = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
      const meses = [
        '',
        'Janeiro',
        'Fevereiro',
        'Março',
        'Abril',
        'Maio',
        'Junho',
        'Julho',
        'Agosto',
        'Setembro',
        'Outubro',
        'Novembro',
        'Dezembro',
      ];
      return '${diasSemana[dt.weekday % 7]}, ${dt.day} de ${meses[dt.month]}';
    } catch (_) {
      return iso;
    }
  }
}

class DocumentoItem {
  final String nome;
  final String data;
  final String tamanho;

  const DocumentoItem({
    required this.nome,
    required this.data,
    required this.tamanho,
  });

  factory DocumentoItem.fromSupabase(Map<String, dynamic> row) {
    final bytes = row['file_size_bytes'] as int? ?? 0;
    final tamanho = _formatarBytes(bytes);
    final createdAt = row['created_at'] as String? ?? '';
    final dataLabel = _formatarDataCurta(createdAt);
    return DocumentoItem(
      nome: row['name'] as String? ?? '',
      data: dataLabel,
      tamanho: tamanho,
    );
  }

  static String _formatarBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  static String _formatarDataCurta(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
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
      return '${dt.day} ${meses[dt.month]}';
    } catch (_) {
      return iso;
    }
  }
}

class AppointmentDetailsPage extends StatefulWidget {
  /// ID da consulta no Supabase (tabela `appointments`).
  final String appointmentId;

  const AppointmentDetailsPage({super.key, required this.appointmentId});

  @override
  State<AppointmentDetailsPage> createState() => _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
  static const Color _primary = Color(0xFF1A8070);
  static const Color _accent = Color(0xFF7CDACF);
  static const Color _textMuted = Color(0xFF6A9890);

  int _navIndex = 1;
  late Future<AppointmentDetail> _futureDetail;

  Future<Map<String, dynamic>> _fetchAppointment(String appointmentId) async {
    final response = await Supabase.instance.client
        .from('appointments')
        .select('''
          id,
          scheduled_date,
          scheduled_time,
          type,
          status,
          patient_notes,
          doctor:doctors!appointments_doctor_id_fkey (
            user_id,
            doctor_user:users!doctors_user_id_fkey ( name, phone ),
            specialty:specialties!doctors_specialty_id_fkey ( name )
          ),
          documents ( id, name, file_size_bytes, created_at )
        ''')
        .eq('id', appointmentId)
        .single();

    final flat = Map<String, dynamic>.from(response);
    final doctor = flat['doctor'] as Map<String, dynamic>? ?? {};
    flat['doctor_user'] = doctor['doctor_user'] ?? {};
    flat['specialty'] = doctor['specialty'] ?? {};
    flat['doctor_id'] = doctor['user_id'];
    return flat;
  }

  @override
  void initState() {
    super.initState();
    _futureDetail = _fetchAppointment(
      widget.appointmentId,
    ).then(AppointmentDetail.fromSupabase);
  }

  /// Recarrega os dados após uma operação (reagendamento, etc.)
  void _reload() {
    setState(() {
      _futureDetail = _fetchAppointment(
        widget.appointmentId,
      ).then(AppointmentDetail.fromSupabase);
    });
  }

  Color _badgeBgColor(String status) {
    switch (status) {
      case 'Realizada':
        return const Color(0xFFDFF5E3);
      case 'Cancelada':
        return const Color(0xFFFFE5E5);
      default:
        return const Color(0xFFD5EAFF);
    }
  }

  Color _badgeTextColor(String status) {
    switch (status) {
      case 'Realizada':
        return const Color(0xFF1A7A3C);
      case 'Cancelada':
        return const Color(0xFF8B1A1A);
      default:
        return const Color(0xFF1A3B8B);
    }
  }

  Future<void> _openReschedule(AppointmentDetail detail) async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => RescheduleAppointmentPage(
          appointmentId: widget.appointmentId,
          doctorId: detail.doctorId,
          medicoInitials: detail.medicoInitials,
          medicoNome: detail.medicoNome,
          medicoEspecialidade: detail.medicoEspecialidade,
          data: detail.data,
          hora: detail.hora,
          tipo: detail.tipo,
          notas: detail.notas,
        ),
      ),
    );

    // RescheduleAppointmentPage já persiste na BD antes de fazer pop.
    // Basta recarregar a página se o utilizador confirmou.
    if (result != null && mounted) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePortalPaciente(
      currentIndex: _navIndex,
      onNavTap: (i) => setState(() => _navIndex = i),
      child: FutureBuilder<AppointmentDetail>(
        future: _futureDetail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'Erro ao carregar consulta:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _reload,
                    style: ElevatedButton.styleFrom(backgroundColor: _primary),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          final detail = snapshot.data!;
          return _buildContent(detail);
        },
      ),
    );
  }

  Widget _buildContent(AppointmentDetail detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),

        // Botão Voltar
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
          'Consulta - Detalhes',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        _DoctorCard(detail: detail),
        const SizedBox(height: 20),

        const Text(
          'INFORMAÇÃO',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _primary,
          ),
        ),
        const SizedBox(height: 8),
        _InfoCard(
          detail: detail,
          badgeBgColor: _badgeBgColor,
          badgeTextColor: _badgeTextColor,
        ),
        const SizedBox(height: 20),

        const Text(
          'DOCUMENTOS ASSOCIADOS',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _primary,
          ),
        ),
        const SizedBox(height: 8),
        if (detail.documentos.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Sem documentos associados.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: _textMuted,
              ),
            ),
          )
        else
          ...detail.documentos.map(
            (doc) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DocumentCard(doc: doc),
            ),
          ),

        const SizedBox(height: 20),

        if (detail.estado != 'Cancelada' && detail.estado != 'Realizada')
          GestureDetector(
            onTap: () => _openReschedule(detail),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(50),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3F000000),
                    blurRadius: 20,
                    offset: Offset(0, 2),
                    spreadRadius: -10,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text(
                'Reagendar Consulta',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),

        const SizedBox(height: 12),
      ],
    );
  }
}

// Sub-widgets (sem estado próprio - extraídos para legibilidade)

class _DoctorCard extends StatelessWidget {
  final AppointmentDetail detail;

  static const Color _primary = Color(0xFF1A8070);
  static const Color _accent = Color(0xFF7CDACF);
  static const Color _accentBorder = Color(0xFF46AA9F);
  static const Color _textSub = Color(0xFF3DBDAD);
  static const Color _textMuted = Color(0xFF6A9890);

  const _DoctorCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _accent,
                shape: BoxShape.circle,
                border: Border.all(color: _accentBorder, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                detail.medicoInitials,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Info médico
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.medicoNome,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    ),
                  ),
                  Text(
                    detail.medicoEspecialidade,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: _textSub,
                    ),
                  ),
                  Text(
                    detail.medicoTelefone,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: _textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final AppointmentDetail detail;
  final Color Function(String) badgeBgColor;
  final Color Function(String) badgeTextColor;

  static const Color _primary = Color(0xFF1A8070);

  const _InfoCard({
    required this.detail,
    required this.badgeBgColor,
    required this.badgeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 20,
            offset: Offset(0, 2),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Column(
        children: [
          // Estado
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: _primary, size: 14),
                const SizedBox(width: 8),
                const SizedBox(
                  width: 60,
                  child: Text(
                    'Estado',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: _primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBgColor(detail.estado),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    detail.estado,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: badgeTextColor(detail.estado),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            indent: 12,
            endIndent: 12,
            color: Color(0xFFE0F0EE),
          ),
          // Data
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Data',
            value: detail.data,
          ),
          const Divider(
            height: 1,
            indent: 12,
            endIndent: 12,
            color: Color(0xFFE0F0EE),
          ),
          // Hora
          _InfoRow(
            icon: Icons.access_time_outlined,
            label: 'Hora',
            value: detail.hora,
          ),
          const Divider(
            height: 1,
            indent: 12,
            endIndent: 12,
            color: Color(0xFFE0F0EE),
          ),
          // Tipo
          _InfoRow(
            icon: Icons.medical_services_outlined,
            label: 'Tipo',
            value: detail.tipo,
          ),
          const Divider(
            height: 1,
            indent: 12,
            endIndent: 12,
            color: Color(0xFFE0F0EE),
          ),
          // Notas
          _InfoRow(
            icon: Icons.edit_outlined,
            label: 'Notas',
            value: detail.notas.isEmpty ? '-' : detail.notas,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  static const Color _primary = Color(0xFF1A8070);
  static const Color _textMuted = Color(0xFF6A9890);

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: _primary, size: 14),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: _primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: _textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final DocumentoItem doc;

  static const Color _primary = Color(0xFF1A8070);

  const _DocumentCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F4F1),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.description_outlined,
                color: _primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.nome,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${doc.data} • ${doc.tamanho}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: _primary,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                // TODO: download / abrir documento via Supabase Storage
              },
              child: const Icon(
                Icons.download_outlined,
                color: _primary,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
