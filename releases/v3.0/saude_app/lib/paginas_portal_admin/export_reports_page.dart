import 'package:saude_app/paginas_portal_admin/portal_admin.dart';

class ExportReportsPage extends StatefulWidget {
  const ExportReportsPage({super.key});

  @override
  State<ExportReportsPage> createState() => _ExportReportsPageState();
}

class _ExportReportsPageState extends State<ExportReportsPage> {
  // Color palette
  static const Color _primary      = Color(0xFF1A8070);
  static const Color _accent       = Color(0xFF7CDACF);
  static const Color _accentBorder = Color(0xFF46AA9F);
  static const Color _pink         = Color(0xFFD4537E);
  static const Color _cardBg       = Color(0xFFD5E2E3);

  int _navIndex = 3;
  // Filter state
  String _tipo       = 'Atos médicos';
  String _dataInicio = '01/01/2026';
  String _dataFim    = '31/03/2026';
  String _medicoId   = 'todos';
  String _medicoLabel = 'Todos';
  String _formato    = 'PDF';

  // Dropdown options
  final List<String> _tipoOptions    = ['Atos médicos', 'Consultas', 'Urgências'];
  final List<String> _formatoOptions = ['PDF', 'Excel', 'CSV'];

  // Doctors loaded from DB
  List<Map<String, dynamic>> _medicosOptions = [
    {'id': 'todos', 'label': 'Todos'},
  ];

  // Preview stats from DB
  int  _registos   = 0;
  int  _mesesCount = 0;
  int  _medicosCount = 0;
  bool _loadingStats   = false;
  bool _loadingMedicos = false;
  bool _exporting      = false;

  @override
  void initState() {
    super.initState();
    _loadMedicos();
    _loadStats();
  }


  // Parse "dd/mm/yyyy" - DateTime
  DateTime _parseDate(String dmy) {
    final p = dmy.split('/');
    return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
  }

  // Format DateTime - "dd/mm/yyyy"
  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  // ISO date string for Supabase queries "yyyy-mm-dd"
  String _toIso(String dmy) {
    final p = dmy.split('/');
    return '${p[2]}-${p[1].padLeft(2, '0')}-${p[0].padLeft(2, '0')}';
  }

  // Load doctors list from DB
  Future<void> _loadMedicos() async {
    setState(() => _loadingMedicos = true);
    try {
      final res = await db
          .from('users')
          .select('id, name')
          .eq('role', 'doctor')
          .isFilter('deleted_at', null)
          .order('name');

      if (!mounted) return;
      final list = List<Map<String, dynamic>>.from(res as List);
      setState(() {
        _medicosOptions = [
          {'id': 'todos', 'label': 'Todos'},
          ...list.map((d) => {'id': d['id'] as String, 'label': d['name'] as String}),
        ];
        _loadingMedicos = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMedicos = false);
    }
  }

  // Load preview stats from DB based on current filters
  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final inicio = _toIso(_dataInicio);
      final fim    = _toIso(_dataFim);

      // Build appointments query
      var query = db
          .from('appointments')
          .select('id, doctor_id, type, status, scheduled_date')
          .isFilter('deleted_at', null)
          .gte('scheduled_date', inicio)
          .lte('scheduled_date', fim);

      // Filter by appointment type
      if (_tipo == 'Consultas') {
        query = query.eq('type', 'normal');
      } else if (_tipo == 'Urgências') {
        query = query.eq('type', 'urgent');
      }
      // 'Atos médicos' = all types

      // Filter by doctor
      if (_medicoId != 'todos') {
        query = query.eq('doctor_id', _medicoId);
      }

      final res = List<Map<String, dynamic>>.from(await query as List);

      // Calculate stats
      final registos = res.length;

      // Count distinct months in range
      final start   = _parseDate(_dataInicio);
      final end     = _parseDate(_dataFim);
      final meses   = (end.year - start.year) * 12 + (end.month - start.month) + 1;

      // Count distinct doctors in results
      final doctorIds = res.map((a) => a['doctor_id']).toSet();
      final medicos   = doctorIds.length;

      if (!mounted) return;
      setState(() {
        _registos    = registos;
        _mesesCount  = meses.clamp(0, 999);
        _medicosCount = medicos;
        _loadingStats = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  // Export via Edge Function + guardar ficheiro localmente
  Future<void> _export() async {
    if (_registos == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sem registos para exportar no período seleccionado.',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
        ),
      );
      return;
    }

    setState(() => _exporting = true);
    try {
      await exportDoctorReport(
        context,
        DoctorReportExportParams(
          dateStart: _toIso(_dataInicio),
          dateEnd: _toIso(_dataFim),
          doctorId: _medicoId,
          reportType: _tipo,
          format: _formato,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // Filter row widget
  Widget _filterRow(String label, String value, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: _accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: _accentBorder, width: 1.1),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Opacity(
                    opacity: 0.6,
                    child: Text(
                      '$label: $value',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.black87),
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: _primary, size: 18),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFD4537E), thickness: 0.8),
      ],
    );
  }

  // Generic bottom sheet picker
  Future<void> _showPicker({
    required String title,
    required List<String> options,
    required String current,
    required ValueChanged<String> onSelected,
  }) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
            const SizedBox(height: 12),
            ...options.map((opt) {
              final isSelected = opt == current;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(opt, style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400, color: isSelected ? _pink : Colors.black87)),
                trailing: isSelected ? const Icon(Icons.check, color: _pink, size: 18) : null,
                onTap: () { onSelected(opt); Navigator.pop(context); },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Date picker
  Future<void> _pickDate({required String current, required ValueChanged<String> onSelected}) async {
    final initial = _parseDate(current);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _pink, onPrimary: Colors.white, onSurface: Colors.black87)),
        child: child!,
      ),
    );
    if (picked != null) onSelected(_formatDate(picked));
  }

  // Build
  @override
  Widget build(BuildContext context) {
    return TemplatePortalAdmin(
      currentIndex: _navIndex,
      onNavTap: (i) => setState(() => _navIndex = i),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page title
          const Text('Exportar Relatórios', style: TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black87)),
          const SizedBox(height: 20),

          // Tipo
          _filterRow('Tipo', _tipo, () async {
            await _showPicker(
              title: 'Tipo de relatório',
              options: _tipoOptions,
              current: _tipo,
              onSelected: (v) { setState(() => _tipo = v); _loadStats(); },
            );
          }),

          // Data Início
          _filterRow('Data Início', _dataInicio, () async {
            await _pickDate(
              current: _dataInicio,
              onSelected: (v) { setState(() => _dataInicio = v); _loadStats(); },
            );
          }),

          // Data Fim
          _filterRow('Data Fim', _dataFim, () async {
            await _pickDate(
              current: _dataFim,
              onSelected: (v) { setState(() => _dataFim = v); _loadStats(); },
            );
          }),

          // Médico - loaded from DB
          _filterRow('Médico', _medicoLabel, () async {
            if (_loadingMedicos) return;
            await showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              builder: (_) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Médico', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
                    const SizedBox(height: 12),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: _medicosOptions.map((opt) {
                            final isSelected = opt['id'] == _medicoId;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(opt['label'] as String, style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400, color: isSelected ? _pink : Colors.black87)),
                              trailing: isSelected ? const Icon(Icons.check, color: _pink, size: 18) : null,
                              onTap: () {
                                setState(() {
                                  _medicoId    = opt['id'] as String;
                                  _medicoLabel = opt['label'] as String;
                                });
                                Navigator.pop(context);
                                _loadStats();
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          }),

          // Formato
          _filterRow('Formato', _formato, () async {
            await _showPicker(
              title: 'Formato de exportação',
              options: _formatoOptions,
              current: _formato,
              onSelected: (v) => setState(() => _formato = v),
            );
          }),

          const SizedBox(height: 24),

          // Preview card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _pink, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pré visualização dos dados:', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: _primary)),
                const SizedBox(height: 12),
                _loadingStats
                    ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: _pink, strokeWidth: 2)))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _previewStat(_registos.toString(),    'Registos'),
                          _previewStat(_mesesCount.toString(),  'Meses'),
                          _previewStat(_medicosCount.toString(),'Médicos'),
                        ],
                      ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Export button
          GestureDetector(
            onTap: _exporting ? null : _export,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: _exporting ? _pink.withValues(alpha: 0.6) : _pink,
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: _exporting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Exportar Relatório', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _previewStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 26, fontWeight: FontWeight.w700, color: _pink, height: 1)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: _primary)),
      ],
    );
  }
}