import 'package:saude_app/paginas_portal_medico/portal_medico.dart';

//  Modelo
class _BloqueioItem {
  final int id;
  final DateTime startDt;
  final DateTime endDt;
  final String? reason;

  const _BloqueioItem({
    required this.id,
    required this.startDt,
    required this.endDt,
    this.reason,
  });
}

//  Página
class BlockSchedule extends StatefulWidget {
  const BlockSchedule({super.key});

  @override
  State<BlockSchedule> createState() => _BlockScheduleState();
}

class _BlockScheduleState extends State<BlockSchedule> {
  // Form state
  DateTime? _dataInicio;
  DateTime? _dataFim;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFim;
  bool _apenasEsteDia = true;
  final TextEditingController _motivoCtrl = TextEditingController();

  // Lista de bloqueios existentes
  List<_BloqueioItem> _bloqueios = [];
  bool _loadingList = false;
  bool _saving = false;
  String? _error;

  static const List<String> _weekdayPt = [
    '',
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sáb',
    'Dom',
  ];
  static const List<String> _monthPt = [
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

  @override
  void initState() {
    super.initState();
    // Defaults: hoje, hora actual arredondada à hora
    final now = DateTime.now();
    _dataInicio = DateTime(now.year, now.month, now.day);
    _dataFim = _dataInicio;
    _horaInicio = TimeOfDay(hour: now.hour, minute: 0);
    _horaFim = TimeOfDay(hour: (now.hour + 1).clamp(0, 23), minute: 0);
    _loadBloqueios();
  }

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  // Formatadores
  String _fmtDate(DateTime? d) {
    if (d == null) return '-';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _fmtTime(TimeOfDay? t) {
    if (t == null) return '-';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  String _fmtPreview(DateTime? d, TimeOfDay? inicio, TimeOfDay? fim) {
    if (d == null || inicio == null || fim == null) return '-';
    final wd = _weekdayPt[d.weekday];
    return '$wd, ${d.day} ${_monthPt[d.month]} • ${_fmtTime(inicio)}-${_fmtTime(fim)}';
  }

  String _previewLabel() {
    if (_apenasEsteDia) {
      return _fmtPreview(_dataInicio, _horaInicio, _horaFim);
    }
    // intervalo de datas
    if (_dataInicio == null || _dataFim == null) return '-';
    return '${_fmtDate(_dataInicio)} → ${_fmtDate(_dataFim)} • ${_fmtTime(_horaInicio)}-${_fmtTime(_horaFim)}';
  }

  // Converte DateTime + TimeOfDay - DateTime completo em UTC (Supabase TIMESTAMPTZ)
  DateTime _toUtc(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    ).toUtc();
  }

  // Carrega bloqueios existentes do médico
  Future<void> _loadBloqueios() async {
    final doctorId = db.auth.currentUser?.id;
    if (doctorId == null) return;

    setState(() {
      _loadingList = true;
      _error = null;
    });

    try {
      final rows = await db
          .from('blocked_slots')
          .select('id, start_datetime, end_datetime, reason')
          .eq('doctor_id', doctorId)
          .gte('end_datetime', DateTime.now().toUtc().toIso8601String())
          .order('start_datetime', ascending: true);

      final List<_BloqueioItem> items = [];
      for (final r in rows as List) {
        items.add(
          _BloqueioItem(
            id: r['id'] as int,
            startDt: DateTime.parse(r['start_datetime'] as String).toLocal(),
            endDt: DateTime.parse(r['end_datetime'] as String).toLocal(),
            reason: r['reason'] as String?,
          ),
        );
      }
      setState(() => _bloqueios = items);
    } catch (e) {
      setState(() => _error = 'Erro ao carregar bloqueios: $e');
    } finally {
      setState(() => _loadingList = false);
    }
  }

  // Eliminar bloqueio
  Future<void> _eliminar(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Eliminar bloqueio',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Tem a certeza que pretende remover este bloqueio de horário?',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF3DBDAD)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFFC62828),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await db.from('blocked_slots').delete().eq('id', id);
      await _loadBloqueios();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bloqueio removido')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  // Gravar novo bloqueio
  Future<void> _confirmarBloqueio() async {
    // Validações
    if (_dataInicio == null || _horaInicio == null || _horaFim == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos obrigatórios.')),
      );
      return;
    }

    final dataFimEfetiva = _apenasEsteDia
        ? _dataInicio!
        : (_dataFim ?? _dataInicio!);
    final startUtc = _toUtc(_dataInicio!, _horaInicio!);
    final endUtc = _toUtc(dataFimEfetiva, _horaFim!);

    if (!endUtc.isAfter(startUtc)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A hora/data de fim tem de ser posterior ao início.'),
        ),
      );
      return;
    }

    final doctorId = db.auth.currentUser?.id;
    if (doctorId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sem sessão ativa.')));
      return;
    }

    setState(() => _saving = true);

    try {
      await db.from('blocked_slots').insert({
        'doctor_id': doctorId,
        'start_datetime': startUtc.toIso8601String(),
        'end_datetime': endUtc.toIso8601String(),
        'reason': _motivoCtrl.text.trim().isEmpty
            ? null
            : _motivoCtrl.text.trim(),
      });

      _motivoCtrl.clear();
      await _loadBloqueios();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bloqueio criado com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao gravar: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // Pickers
  Future<void> _pickDate({required bool isInicio}) async {
    final initial = isInicio
        ? (_dataInicio ?? DateTime.now())
        : (_dataFim ?? _dataInicio ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'PT'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF3DBDAD),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isInicio) {
        _dataInicio = picked;
        // Se data de fim for antes, ajustar
        if (_dataFim != null && _dataFim!.isBefore(picked)) {
          _dataFim = picked;
        }
      } else {
        _dataFim = picked;
      }
    });
  }

  Future<void> _pickTime({required bool isInicio}) async {
    final initial = isInicio
        ? (_horaInicio ?? const TimeOfDay(hour: 9, minute: 0))
        : (_horaFim ?? const TimeOfDay(hour: 10, minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF3DBDAD),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isInicio) {
        _horaInicio = picked;
      } else {
        _horaFim = picked;
      }
    });
  }

  // Formata para lista de bloqueios existentes
  String _fmtBloqueioLabel(_BloqueioItem b) {
    final startDate = _fmtDate(b.startDt);
    final endDate = _fmtDate(b.endDt);
    final startTime =
        '${b.startDt.hour.toString().padLeft(2, '0')}:${b.startDt.minute.toString().padLeft(2, '0')}';
    final endTime =
        '${b.endDt.hour.toString().padLeft(2, '0')}:${b.endDt.minute.toString().padLeft(2, '0')}';

    if (startDate == endDate) {
      return '$startDate • $startTime-$endTime';
    }
    return '$startDate $startTime → $endDate $endTime';
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePortalMedico(
      currentIndex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Voltar
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text(
              '< Voltar atrás',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF50C4A5),
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF50C4A5),
                fontFamily: 'Poppins',
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Título
          const Text(
            'Bloquear Horário',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              fontFamily: 'Poppins',
            ),
          ),

          const SizedBox(height: 24),

          // Erro global
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: Text(
                _error!,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Color(0xFFC62828),
                ),
              ),
            ),

          // Campos
          _CampoData(
            icon: Icons.calendar_month_outlined,
            iconColor: const Color(0xFF3DBDAD),
            texto: 'Data de início: ${_fmtDate(_dataInicio)}',
            onTap: () => _pickDate(isInicio: true),
          ),

          // Data de fim (só mostra se não for "apenas este dia")
          if (!_apenasEsteDia)
            _CampoData(
              icon: Icons.calendar_month_outlined,
              iconColor: const Color(0xFFE65100),
              texto: 'Data de fim: ${_fmtDate(_dataFim)}',
              onTap: () => _pickDate(isInicio: false),
            ),

          // Toggle "Apenas este dia"
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _apenasEsteDia = !_apenasEsteDia;
                  if (_apenasEsteDia) _dataFim = _dataInicio;
                });
              },
              child: Row(
                children: [
                  Container(
                    width: 27,
                    height: 27,
                    decoration: BoxDecoration(
                      color: _apenasEsteDia
                          ? const Color(0xFF3DBDAD)
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF3DBDAD),
                        width: 2,
                      ),
                    ),
                    child: _apenasEsteDia
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Apenas este dia',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),

          _CampoData(
            icon: Icons.access_time_outlined,
            iconColor: const Color(0xFF3DBDAD),
            texto: 'Hora início: ${_fmtTime(_horaInicio)}',
            onTap: () => _pickTime(isInicio: true),
          ),
          _CampoData(
            icon: Icons.access_time_outlined,
            iconColor: const Color(0xFFE65100),
            texto: 'Hora fim: ${_fmtTime(_horaFim)}',
            onTap: () => _pickTime(isInicio: false),
          ),

          // Motivo (texto livre)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                const Icon(
                  Icons.edit_document,
                  color: Color(0xFF3DBDAD),
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _motivoCtrl,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black.withValues(alpha: 0.7),
                      fontFamily: 'Poppins',
                    ),
                    decoration: InputDecoration(
                      hintText: 'Motivo (opcional)',
                      hintStyle: TextStyle(
                        fontSize: 15,
                        color: Colors.black.withValues(alpha: 0.26),
                        fontFamily: 'Poppins',
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: const Color(0xFF3DBDAD).withValues(alpha: 0.40),
            height: 1,
          ),

          const SizedBox(height: 24),

          // Pré-visualização
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFC5EDE8),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: const Color(0xFF9FDFD7), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PRÉ-VISUALIZAÇÃO',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A8070),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: const Border(
                      left: BorderSide(color: Color(0xFFA8A8A8), width: 4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_previewLabel()}${_motivoCtrl.text.trim().isNotEmpty ? ' • ${_motivoCtrl.text.trim()}' : ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFA8A8A8),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.lock_outline,
                        size: 18,
                        color: Color(0xFFA8A8A8),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Botão Confirmar
          GestureDetector(
            onTap: _saving ? null : _confirmarBloqueio,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _saving
                    ? const Color(0xFF3DBDAD).withValues(alpha: 0.6)
                    : const Color(0xFF3DBDAD),
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 20,
                    offset: Offset(0, 3),
                  ),
                ],
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
                  : const Text(
                      'Confirmar Bloqueio',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Cancelar
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF50C4A5),
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFF50C4A5),
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Bloqueios existentes
          const Text(
            'BLOQUEIOS ACTIVOS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3DBDAD),
              fontFamily: 'Poppins',
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),

          if (_loadingList)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(color: Color(0xFF3DBDAD)),
              ),
            )
          else if (_bloqueios.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Sem bloqueios futuros',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFA8A8A8),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _bloqueios.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final b = _bloqueios[i];
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: const Border(
                      left: BorderSide(color: Color(0xFFA8A8A8), width: 4),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: Color(0xFFA8A8A8),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _fmtBloqueioLabel(b),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF444444),
                                fontFamily: 'Poppins',
                              ),
                            ),
                            if (b.reason != null && b.reason!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                b.reason!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFA8A8A8),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _eliminar(b.id),
                        child: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Color(0xFFE57373),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}


// Widget auxiliar reutilizável
class _CampoData extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String texto;
  final VoidCallback onTap;

  const _CampoData({
    required this.icon,
    required this.iconColor,
    required this.texto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(width: 16),
                Text(
                  texto,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black.withValues(alpha: 0.55),
                    fontFamily: 'Poppins',
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: Colors.black.withValues(alpha: 0.20),
                  size: 20,
                ),
              ],
            ),
          ),
          Divider(
            color: const Color(0xFF3DBDAD).withValues(alpha: 0.40),
            height: 1,
          ),
        ],
      ),
    );
  }
}
