import 'package:saude_app/paginas_portal_admin/portal_admin.dart';

enum _DayMark { livre, consultas, bloqueado, ambos }

class _AgendaEntry {
  final String id;
  final String hora;
  final String patientName;
  final String patientId;
  final String type;
  final String status;
  final bool isBlocked;
  final String? reason;
  final String? doctorName;

  const _AgendaEntry({
    required this.id,
    required this.hora,
    required this.patientName,
    required this.patientId,
    required this.type,
    required this.status,
    this.isBlocked = false,
    this.reason,
    this.doctorName,
  });
}

class SchedulesPage extends StatefulWidget {
  const SchedulesPage({super.key});

  @override
  State<SchedulesPage> createState() => _SchedulesPageState();
}

class _SchedulesPageState extends State<SchedulesPage> {
  late DateTime _monthAnchor;
  late DateTime _selectedDate;

  Map<String, _DayMark> _marks = {};
  List<_AgendaEntry> _dayEntries = [];

  bool _loadingMarks = false;
  bool _loadingList = false;
  bool _loadingDoctors = true;
  String? _error;

  static const String _allDoctorsId = 'todos';

  String? _doctorId;
  String _doctorLabel = '';
  List<Map<String, String>> _doctors = [];

  bool get _viewingAll => _doctorId == _allDoctorsId;

  static const _dayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  static const _monthNames = [
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
  static const _monthShort = [
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
  static const _weekdayNames = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo',
  ];

  static const Color _cConsulta = Color(0xFFB9124A);
  static const Color _cConsultaBg = Color(0xFFFFE4EC);
  static const Color _cUrgencia = Color(0xFFE65100);
  static const Color _cUrgenciaBg = Color(0xFFFFF3E0);
  static const Color _cBloqueio = Color(0xFF8E8E8E);
  static const Color _cBloqueioBg = Color(0xFFF3E8EB);
  static const Color _cActive = Color(0xFFD4537E);
  static const Color _cLink = Color(0xFFB9124A);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _monthAnchor = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() => _loadingDoctors = true);
    try {
      final rows = await db
          .from('doctors')
          .select('user_id, users!doctors_user_id_fkey(name, deleted_at)')
          .eq('suspended', false);

      final list = <Map<String, String>>[];
      for (final r in rows as List) {
        final id = r['user_id'] as String?;
        final name = r['users']?['name'] as String?;
        final deletedAt = r['users']?['deleted_at'];
        if (id != null && name != null && deletedAt == null) {
          list.add({'id': id, 'label': name});
        }
      }

      list.sort((a, b) => a['label']!.compareTo(b['label']!));
      final withAll = [
        {'id': _allDoctorsId, 'label': 'Todos os médicos'},
        ...list,
      ];

      if (!mounted) return;
      setState(() {
        _doctors = withAll;
        _loadingDoctors = false;
        if (_doctorId == null) {
          _doctorId = _allDoctorsId;
          _doctorLabel = 'Todos os médicos';
          _refreshAll();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao carregar médicos: $e';
        _loadingDoctors = false;
      });
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _markKey(DateTime d) => _fmtDate(d);

  String? _nomeMedico(dynamic row) {
    if (row is! Map) return null;
    final doctors = row['doctors'];
    if (doctors is! Map) return null;
    final users = doctors['users'];
    if (users is! Map) return null;
    return users['name'] as String?;
  }

  void _refreshAll() {
    if (_doctorId == null) return;
    _loadMonthMarks(_monthAnchor);
    _loadDay(_selectedDate);
  }

  Future<void> _loadMonthMarks(DateTime month) async {
    setState(() => _loadingMarks = true);
    try {
      if (_doctorId == null) throw Exception('Selecione um médico');

      final first = DateTime(month.year, month.month, 1);
      final last = DateTime(month.year, month.month + 1, 0);
      final marks = <String, _DayMark>{};

      var apptsQuery = db
          .from('appointments')
          .select('scheduled_date')
          .gte('scheduled_date', _fmtDate(first))
          .lte('scheduled_date', _fmtDate(last))
          .neq('status', 'canceled')
          .isFilter('deleted_at', null);
      if (!_viewingAll) {
        apptsQuery = apptsQuery.eq('doctor_id', _doctorId!);
      }
      final appts = await apptsQuery;

      for (final r in appts as List) {
        final k = r['scheduled_date'] as String;
        marks[k] = _mergeMark(marks[k], hasConsulta: true);
      }

      var blocksQuery = db
          .from('blocked_slots')
          .select('start_datetime, end_datetime')
          .lte('start_datetime', '${_fmtDate(last)}T23:59:59')
          .gte('end_datetime', '${_fmtDate(first)}T00:00:00');
      if (!_viewingAll) {
        blocksQuery = blocksQuery.eq('doctor_id', _doctorId!);
      }
      final blocks = await blocksQuery;

      for (final b in blocks as List) {
        final start = DateTime.parse(b['start_datetime'] as String).toLocal();
        final end = DateTime.parse(b['end_datetime'] as String).toLocal();
        var d = DateTime(start.year, start.month, start.day);
        final endDay = DateTime(end.year, end.month, end.day);
        while (!d.isAfter(endDay)) {
          if (!d.isBefore(first) && !d.isAfter(last)) {
            marks[_markKey(d)] = _mergeMark(marks[_markKey(d)], hasBlock: true);
          }
          d = d.add(const Duration(days: 1));
        }
      }

      if (!mounted) return;
      setState(() {
        _marks = marks;
        _loadingMarks = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingMarks = false;
      });
    }
  }

  _DayMark _mergeMark(
    _DayMark? cur, {
    bool hasConsulta = false,
    bool hasBlock = false,
  }) {
    final c = cur == _DayMark.consultas || cur == _DayMark.ambos || hasConsulta;
    final b = cur == _DayMark.bloqueado || cur == _DayMark.ambos || hasBlock;
    if (c && b) return _DayMark.ambos;
    if (c) return _DayMark.consultas;
    if (b) return _DayMark.bloqueado;
    return _DayMark.livre;
  }

  Future<List<_AgendaEntry>> _fetchDayEntries(DateTime date) async {
    final dateStr = _fmtDate(date);

    var apptsQuery = db
        .from('appointments')
        .select('''
          id, scheduled_time, type, status,
          patients!inner(user_id, users!inner(name)),
          doctors!appointments_doctor_id_fkey(
            users!doctors_user_id_fkey(name)
          )
        ''')
        .eq('scheduled_date', dateStr)
        .neq('status', 'canceled')
        .isFilter('deleted_at', null);
    if (!_viewingAll) {
      apptsQuery = apptsQuery.eq('doctor_id', _doctorId!);
    }
    final rows = await apptsQuery.order('scheduled_time', ascending: true);

    final entries = <_AgendaEntry>[];
    for (final r in rows as List) {
      entries.add(
        _AgendaEntry(
          id: r['id'] as String,
          hora: (r['scheduled_time'] as String).substring(0, 5),
          patientName:
              r['patients']['users']['name'] as String? ?? 'Desconhecido',
          patientId: r['patients']['user_id'] as String,
          type: r['type'] as String? ?? 'normal',
          status: r['status'] as String? ?? 'scheduled',
          doctorName: _viewingAll ? _nomeMedico(r) : null,
        ),
      );
    }

    var blocksQuery = db
        .from('blocked_slots')
        .select('''
          id, start_datetime, end_datetime, reason,
          doctors!blocked_slots_doctor_id_fkey(
            users!doctors_user_id_fkey(name)
          )
        ''')
        .lte('start_datetime', '${dateStr}T23:59:59')
        .gte('end_datetime', '${dateStr}T00:00:00');
    if (!_viewingAll) {
      blocksQuery = blocksQuery.eq('doctor_id', _doctorId!);
    }
    final blocked = await blocksQuery.order('start_datetime', ascending: true);

    for (final b in blocked as List) {
      final start = DateTime.parse(b['start_datetime'] as String).toLocal();
      entries.add(
        _AgendaEntry(
          id: b['id'].toString(),
          hora:
              '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
          patientName: b['reason'] as String? ?? 'Horário bloqueado',
          patientId: '',
          type: 'blocked',
          status: 'blocked',
          isBlocked: true,
          reason: b['reason'] as String?,
          doctorName: _viewingAll ? _nomeMedico(b) : null,
        ),
      );
    }
    entries.sort((a, b) => a.hora.compareTo(b.hora));
    return entries;
  }

  Future<void> _loadDay(DateTime date) async {
    setState(() {
      _loadingList = true;
      _error = null;
    });
    try {
      if (_doctorId == null) throw Exception('Selecione um médico');
      final entries = await _fetchDayEntries(date);
      if (!mounted) return;
      setState(() {
        _dayEntries = entries;
        _loadingList = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingList = false;
      });
    }
  }

  Future<void> _markCompleted(String appointmentId) async {
    await db
        .from('appointments')
        .update({'status': 'completed'})
        .eq('id', appointmentId);
    _refreshAll();
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
      _monthAnchor = DateTime(date.year, date.month, 1);
    });
    _loadDay(_selectedDate);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _monthAnchor = DateTime(_monthAnchor.year, _monthAnchor.month + delta, 1);
    });
    _loadMonthMarks(_monthAnchor);
  }

  String _selectedDateLabel() {
    final d = _selectedDate;
    return '${_weekdayNames[d.weekday - 1]}, ${d.day} de ${_monthShort[d.month - 1]}';
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

  Color _markBg(_DayMark m, {required bool selected}) {
    if (selected) return _cActive;
    switch (m) {
      case _DayMark.consultas:
        return _cConsultaBg;
      case _DayMark.bloqueado:
        return _cUrgenciaBg;
      case _DayMark.ambos:
        return _cBloqueioBg;
      case _DayMark.livre:
        return const Color(0xCCF2FBFA);
    }
  }

  Color _markFg(_DayMark m, {required bool selected}) {
    if (selected) return Colors.white;
    switch (m) {
      case _DayMark.consultas:
        return _cConsulta;
      case _DayMark.bloqueado:
        return _cUrgencia;
      case _DayMark.ambos:
        return _cBloqueio;
      case _DayMark.livre:
        return Colors.black.withValues(alpha: 0.45);
    }
  }

  Widget _legend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendDot(_cConsultaBg, _cConsulta, 'Consultas'),
        const SizedBox(width: 12),
        _legendDot(_cUrgenciaBg, _cUrgencia, 'Urgente'),
        const SizedBox(width: 12),
        _legendDot(_cBloqueioBg, _cBloqueio, 'Bloqueado'),
      ],
    );
  }

  Widget _legendDot(Color bg, Color fg, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: fg),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 9, color: fg, fontFamily: 'Poppins'),
        ),
      ],
    );
  }

  Widget _monthGrid() {
    final first = DateTime(_monthAnchor.year, _monthAnchor.month, 1);
    final daysInMonth = DateTime(
      _monthAnchor.year,
      _monthAnchor.month + 1,
      0,
    ).day;
    final startPad = first.weekday - 1;
    final cells = <Widget>[];

    for (final lbl in _dayLabels) {
      cells.add(
        Center(
          child: Text(
            lbl,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.35),
              fontFamily: 'Poppins',
            ),
          ),
        ),
      );
    }

    for (var i = 0; i < startPad; i++) {
      cells.add(const SizedBox());
    }

    final today = DateTime.now();
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_monthAnchor.year, _monthAnchor.month, day);
      final mark = _marks[_markKey(date)] ?? _DayMark.livre;
      final isSelected = _fmtDate(date) == _fmtDate(_selectedDate);
      final isToday =
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;

      cells.add(
        GestureDetector(
          onTap: () => _selectDate(date),
          child: Container(
            height: 40,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: _markBg(mark, selected: isSelected),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isToday && !isSelected
                    ? _cActive
                    : const Color(0xFFE1E9E7),
                width: isToday && !isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _markFg(mark, selected: isSelected),
                    fontFamily: 'Poppins',
                  ),
                ),
                if (mark != _DayMark.livre)
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: _markFg(mark, selected: isSelected),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.05,
      children: cells,
    );
  }

  Widget _entriesList() {
    if (_loadingList) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFD4537E)),
        ),
      );
    }
    if (_error != null) {
      return _ErrorBanner(message: _error!, onRetry: _refreshAll);
    }
    if (_dayEntries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Sem consultas nem bloqueios neste dia.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black.withValues(alpha: 0.40),
              fontFamily: 'Poppins',
            ),
          ),
        ),
      );
    }

    return Column(children: _dayEntries.map(_entryTile).toList());
  }

  Widget _entryTile(_AgendaEntry e) {
    return GestureDetector(
      onTap: e.isBlocked || e.status == 'completed'
          ? null
          : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ConsultaPage(appointmentId: e.id),
              ),
            ).then((_) => _refreshAll()),
      child: _AgendaItem(
        hora: e.hora,
        nome: e.isBlocked ? (e.reason ?? 'Bloqueado') : e.patientName,
        medico: e.doctorName,
        tipo: e.isBlocked ? '' : _typeLabel(e.type),
        tipoConsulta: e.isBlocked
            ? _TipoConsulta.bloqueado
            : e.type == 'urgent'
            ? _TipoConsulta.urgente
            : _TipoConsulta.normal,
        isDone: e.status == 'completed',
        onMarkDone: (!e.isBlocked && e.status == 'scheduled')
            ? () => _markCompleted(e.id)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final consultasCount = _dayEntries.where((e) => !e.isBlocked).length;
    final bloqueiosCount = _dayEntries.where((e) => e.isBlocked).length;

    return TemplatePortalAdmin(
      currentIndex: 2,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Agendas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 12),
            if (_loadingDoctors)
              const LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFFD4537E),
                backgroundColor: Color(0xFFFFE4EC),
              )
            else if (_doctors.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Nenhum médico encontrado.',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFD4537E), width: 1.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.medical_services_outlined,
                      color: Colors.black38,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _doctorId,
                          isExpanded: true,
                          items: _doctors
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d['id'],
                                  child: Text(
                                    d['label']!,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (id) {
                            if (id == null) return;
                            final doc = _doctors.firstWhere(
                              (d) => d['id'] == id,
                            );
                            setState(() {
                              _doctorId = id;
                              _doctorLabel = doc['label']!;
                            });
                            _loadMonthMarks(_monthAnchor);
                            _loadDay(_selectedDate);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => _shiftMonth(-1),
                  child: const Text(
                    '< Ant.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _cLink,
                      decoration: TextDecoration.underline,
                      decorationColor: _cLink,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Text(
                  '${_monthNames[_monthAnchor.month - 1]} ${_monthAnchor.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    fontFamily: 'Poppins',
                  ),
                ),
                GestureDetector(
                  onTap: () => _shiftMonth(1),
                  child: const Text(
                    'Próx. >',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _cLink,
                      decoration: TextDecoration.underline,
                      decorationColor: _cLink,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loadingMarks)
              const LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFFD4537E),
                backgroundColor: Color(0xFFFFE4EC),
              ),
            _monthGrid(),
            const SizedBox(height: 10),
            _legend(),
            const SizedBox(height: 16),
            Text(
              _loadingList
                  ? '${_selectedDateLabel()} - a carregar...'
                  : '${_selectedDateLabel()} - $consultasCount consultas'
                        '${bloqueiosCount > 0 ? ', $bloqueiosCount bloqueio(s)' : ''}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black.withValues(alpha: 0.50),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 12),
            _entriesList(),
            const SizedBox(height: 24),
            _actionButtons(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _pedirMedicoEspecifico() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Selecione um médico específico para marcar consulta.',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
      ),
    );
  }

  Widget _actionButtons() {
    final canManage = _doctorId != null && !_viewingAll;

    return Column(
      children: [
        GestureDetector(
          onTap: canManage
              ? () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MarcarConsultaPage(
                          doctorId: _doctorId!,
                          doctorName: _doctorLabel,
                          initialDate: _selectedDate,
                        ),
                      ),
                    ).then((ok) {
                      if (ok == true) _refreshAll();
                    })
              : _pedirMedicoEspecifico,
          child: Opacity(
            opacity: canManage ? 1 : 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _cConsulta,
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 16,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Marcar Consulta',
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
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            //Mostrar feedback imediato
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'A processar lembretes para amanhã...',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                duration: Duration(seconds: 2),
              ),
            );

            try {
              //Chamar a Edge Function
              final res = await db.functions.invoke('send-reminders');

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      res.data['message'] ?? 'Lembretes enviados!',
                      style: const TextStyle(fontFamily: 'Poppins'),
                    ),
                    backgroundColor: const Color(0xFFB9124A),
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Erro ao enviar: $e',
                      style: const TextStyle(fontFamily: 'Poppins'),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF5C6BC0),
              borderRadius: BorderRadius.circular(25),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 16,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.send_time_extension_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Disparar Lembretes',
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
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontFamily: 'Poppins'),
        ),
        TextButton(
          onPressed: onRetry,
          child: const Text(
            'Tentar novamente',
            style: TextStyle(color: Color(0xFFD4537E), fontFamily: 'Poppins'),
          ),
        ),
      ],
    );
  }
}

enum _TipoConsulta { normal, urgente, bloqueado }

class _AgendaItem extends StatelessWidget {
  final String hora;
  final String nome;
  final String? medico;
  final String tipo;
  final _TipoConsulta tipoConsulta;
  final bool isDone;
  final VoidCallback? onMarkDone;

  const _AgendaItem({
    required this.hora,
    required this.nome,
    this.medico,
    required this.tipo,
    required this.tipoConsulta,
    required this.isDone,
    this.onMarkDone,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = switch (tipoConsulta) {
      _TipoConsulta.urgente => const Color(0xFFE65100),
      _TipoConsulta.bloqueado => const Color(0xFFB0BEC5),
      _TipoConsulta.normal => const Color(0xFFD4537E),
    };
    final textColor = switch (tipoConsulta) {
      _TipoConsulta.urgente => const Color(0xFFE65100),
      _TipoConsulta.bloqueado => const Color(0xFF78909C),
      _TipoConsulta.normal => Colors.black.withValues(alpha: 0.70),
    };

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 42,
              child: Text(
                hora,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withValues(alpha: 0.26),
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 46),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    left: BorderSide(color: accentColor, width: 4),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (medico != null && medico!.isNotEmpty)
                            Text(
                              medico!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.black.withValues(alpha: 0.45),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          tipo.isEmpty
                              ? Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        nome,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: textColor,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.lock_outline,
                                      size: 14,
                                      color: accentColor,
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        nome,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: textColor,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                    Text(
                                      ' • ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textColor,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    Text(
                                      tipo,
                                      style: TextStyle(
                                        fontSize: 12,
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
                      const Icon(
                        Icons.check,
                        size: 15,
                        color: Color(0xFFD4537E),
                      )
                    else if (onMarkDone != null)
                      GestureDetector(
                        onTap: onMarkDone,
                        child: const Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: Color(0xFFD4537E),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
