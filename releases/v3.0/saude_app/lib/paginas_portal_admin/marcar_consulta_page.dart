import 'package:saude_app/paginas_portal_admin/portal_admin.dart';

//  Marcar consulta (médico)
class MarcarConsultaPage extends StatefulWidget {
  final String doctorId;
  final String? doctorName;
  final String? patientId;
  final String? nomePaciente;
  final DateTime? initialDate;

  const MarcarConsultaPage({
    super.key,
    required this.doctorId,
    this.doctorName,
    this.patientId,
    this.nomePaciente,
    this.initialDate,
  });

  @override
  State<MarcarConsultaPage> createState() => _MarcarConsultaPageState();
}

class _PacienteOpcao {
  final String id;
  final String nome;

  const _PacienteOpcao({required this.id, required this.nome});
}

class _MarcarConsultaPageState extends State<MarcarConsultaPage> {
  final TextEditingController _notasCtrl = TextEditingController();

  List<_PacienteOpcao> _pacientes = [];
  String? _patientId;
  String _patientLabel = '';

  DateTime? _data;
  TimeOfDay? _hora;
  String _tipo = 'normal';
  int _duracaoMin = 30;

  bool _loadingPatients = false;
  bool _saving = false;
  String? _error;

  static const _tipos = <({String value, String label})>[
    (value: 'normal', label: 'Normal'),
    (value: 'urgent', label: 'Urgente'),
    (value: 'follow_up', label: 'Seguimento'),
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _data = widget.initialDate ?? DateTime(now.year, now.month, now.day);
    _hora = TimeOfDay(hour: now.hour + 1, minute: 0);

    if (widget.patientId != null) {
      _patientId = widget.patientId;
      _patientLabel = widget.nomePaciente ?? 'Paciente';
    } else {
      _loadPacientes();
    }
    _loadDuracaoPadrao();
  }

  @override
  void dispose() {
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDuracaoPadrao() async {
    final doctorId = widget.doctorId;
    try {
      final row = await db
          .from('doctors')
          .select('default_slot_duration_min')
          .eq('user_id', doctorId)
          .maybeSingle();
      if (!mounted || row == null) return;
      setState(() {
        _duracaoMin = (row['default_slot_duration_min'] as num?)?.toInt() ?? 30;
      });
    } catch (_) {}
  }

  Future<void> _loadPacientes() async {
    setState(() {
      _loadingPatients = true;
      _error = null;
    });
    try {
      final rows = await db
          .from('users')
          .select('id, name')
          .eq('role', 'patient')
          .isFilter('deleted_at', null)
          .order('name');

      if (!mounted) return;
      setState(() {
        _pacientes = [
          for (final r in rows)
            _PacienteOpcao(
              id: r['id'] as String,
              nome: r['name'] as String? ?? 'Paciente',
            ),
        ];
        _loadingPatients = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao carregar pacientes: $e';
        _loadingPatients = false;
      });
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  String _fmtDateUi(DateTime? d) {
    if (d == null) return 'Selecionar data';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _fmtTimeUi(TimeOfDay? t) {
    if (t == null) return 'Selecionar hora';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _data ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'PT'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFD4537E)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _data = picked);
  }

  Future<void> _pickHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _hora ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFD4537E)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _hora = picked);
  }

  Future<bool> _horarioOcupado(String doctorId, String dateStr, String timeStr) async {
    final appt = await db
        .from('appointments')
        .select('id')
        .eq('doctor_id', doctorId)
        .eq('scheduled_date', dateStr)
        .eq('scheduled_time', timeStr)
        .neq('status', 'canceled')
        .isFilter('deleted_at', null)
        .maybeSingle();
    return appt != null;
  }

  Future<bool> _horarioBloqueado(
    String doctorId,
    DateTime slotStart,
    DateTime slotEnd,
  ) async {
    final startIso = slotStart.toUtc().toIso8601String();
    final endIso = slotEnd.toUtc().toIso8601String();
    final rows = await db
        .from('blocked_slots')
        .select('id')
        .eq('doctor_id', doctorId)
        .lte('start_datetime', endIso)
        .gte('end_datetime', startIso)
        .limit(1);
    return (rows as List).isNotEmpty;
  }

  Future<void> _confirmar() async {
    if (_patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um paciente.')),
      );
      return;
    }
    if (_data == null || _hora == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indique data e hora.')),
      );
      return;
    }

    final doctorId = widget.doctorId;
    final adminId = db.auth.currentUser?.id;

    final dateStr = _fmtDate(_data!);
    final timeStr = _fmtTime(_hora!);
    final slotStart = DateTime(
      _data!.year,
      _data!.month,
      _data!.day,
      _hora!.hour,
      _hora!.minute,
    );
    final slotEnd = slotStart.add(Duration(minutes: _duracaoMin));

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      if (await _horarioOcupado(doctorId, dateStr, timeStr)) {
        throw Exception('Já existe uma consulta neste horário.');
      }
      if (await _horarioBloqueado(doctorId, slotStart, slotEnd)) {
        throw Exception('Este horário está bloqueado na agenda.');
      }

      await db.from('appointments').insert({
        'id': _novoIdConsulta(),
        'patient_id': _patientId,
        'doctor_id': doctorId,
        'scheduled_date': dateStr,
        'scheduled_time': timeStr,
        'duration_min': _duracaoMin,
        'type': _tipo,
        'status': 'scheduled',
        'patient_notes': _notasCtrl.text.trim().isEmpty
            ? null
            : _notasCtrl.text.trim(),
        'created_by': adminId ?? doctorId,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Consulta marcada com sucesso!',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Color(0xFFD4537E),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePortalAdmin(
      currentIndex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text(
              '< Voltar atrás',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD4537E),
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFFD4537E),
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Marcar Consulta',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              fontFamily: 'Poppins',
            ),
          ),
          if (widget.doctorName != null) ...[
            const SizedBox(height: 6),
            Text(
              'Médico: ${widget.doctorName}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF616161),
                fontFamily: 'Poppins',
              ),
            ),
          ],
          const SizedBox(height: 20),

          if (_error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _error!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFCC3A44),
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Paciente
          if (widget.patientId != null)
            _Campo(
              icon: Icons.person_outline,
              child: Text(
                _patientLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            )
          else if (_loadingPatients)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFD4537E)),
              ),
            )
          else
            _Campo(
              icon: Icons.person_search_outlined,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text(
                    'Selecionar paciente',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 15),
                  ),
                  value: _patientId,
                  items: _pacientes
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(
                            p.nome,
                            style: const TextStyle(fontFamily: 'Poppins'),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (id) {
                    if (id == null) return;
                    final p = _pacientes.firstWhere((x) => x.id == id);
                    setState(() {
                      _patientId = id;
                      _patientLabel = p.nome;
                    });
                  },
                ),
              ),
            ),

          _Campo(
            icon: Icons.calendar_month_outlined,
            onTap: _pickData,
            child: Text(
              _fmtDateUi(_data),
              style: const TextStyle(fontSize: 15, fontFamily: 'Poppins'),
            ),
          ),
          _Campo(
            icon: Icons.access_time,
            onTap: _pickHora,
            child: Text(
              _fmtTimeUi(_hora),
              style: const TextStyle(fontSize: 15, fontFamily: 'Poppins'),
            ),
          ),
          _Campo(
            icon: Icons.medical_services_outlined,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _tipo,
                items: _tipos
                    .map(
                      (t) => DropdownMenuItem(
                        value: t.value,
                        child: Text(
                          t.label,
                          style: const TextStyle(fontFamily: 'Poppins'),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _tipo = v);
                },
              ),
            ),
          ),
          _Campo(
            icon: Icons.notes_outlined,
            alignIconTop: true,
            child: TextField(
              controller: _notasCtrl,
              minLines: 1,
              maxLines: 3,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                fontSize: 15,
                height: 1.35,
                fontFamily: 'Poppins',
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Motivo / notas (opcional)',
                hintStyle: TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  color: Colors.black.withValues(alpha: 0.30),
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
          Text(
            'Duração: $_duracaoMin min',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withValues(alpha: 0.45),
              fontFamily: 'Poppins',
            ),
          ),

          const SizedBox(height: 24),

          GestureDetector(
            onTap: _saving ? null : _confirmar,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _saving
                    ? const Color(0xFFD4537E).withValues(alpha: 0.50)
                    : const Color(0xFFD4537E),
                borderRadius: BorderRadius.circular(25),
              ),
              child: _saving
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Confirmar Marcação',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  final IconData icon;
  final Widget child;
  final VoidCallback? onTap;
  final bool alignIconTop;

  const _Campo({
    required this.icon,
    required this.child,
    this.onTap,
    this.alignIconTop = false,
  });

  @override
  Widget build(BuildContext context) {
    final rowAlign = alignIconTop
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.center;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                crossAxisAlignment: rowAlign,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: alignIconTop ? 2 : 0),
                    child: Icon(icon, size: 22, color: const Color(0xFFD4537E)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: child),
                  if (onTap != null)
                    const Icon(Icons.chevron_right, color: Color(0xFFD4537E)),
                ],
              ),
            ),
          ),
        ),
        Divider(
          color: const Color(0xFFD4537E).withValues(alpha: 0.40),
          height: 1,
        ),
      ],
    );
  }
}

/// ID único para novo registo em `appointments` (coluna UUID no Postgres).
String _novoIdConsulta() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
      '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20, 32)}';
}
