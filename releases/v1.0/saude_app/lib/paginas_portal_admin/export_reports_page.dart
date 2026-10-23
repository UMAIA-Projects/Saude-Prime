import 'package:flutter/material.dart';
import 'template/template_portal_admin.dart';

class ExportReportsPage extends StatefulWidget {
  const ExportReportsPage({super.key});

  @override
  State<ExportReportsPage> createState() => _ExportReportsPageState();
}

class _ExportReportsPageState extends State<ExportReportsPage> {
  // Color palette
  static const Color _primary    = Color(0xFF1A8070);
  static const Color _accent     = Color(0xFF7CDACF);
  static const Color _accentBorder = Color(0xFF46AA9F);
  static const Color _pink       = Color(0xFFD4537E);
  static const Color _cardBg     = Color(0xFFD5E2E3);

  int _navIndex = 0;

  // Filter state
  String _tipo       = 'Atos médicos';
  String _dataInicio = '01/01/2026';
  String _dataFim    = '31/03/2026';
  String _medico     = 'Todos';
  String _formato    = 'PDF';

  // Dropdown options
  final List<String> _tipoOptions    = ['Atos médicos', 'Consultas', 'Internamentos', 'Urgências'];
  final List<String> _medicoOptions  = ['Todos', 'Dr. Carlos Santos', 'Luís Rodrigues'];
  final List<String> _formatoOptions = ['PDF', 'Excel', 'CSV'];

  // Preview stats (static mock — replace with real data later)
  final int _registos = 247;
  final int _meses    = 3;
  final int _medicos  = 12;

  // Helpers
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
                  width: 14,
                  height: 14,
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
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.black87,
                      ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...options.map((opt) {
              final isSelected = opt == current;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  opt,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected ? _pink : Colors.black87,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: _pink, size: 18)
                    : null,
                onTap: () {
                  onSelected(opt);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Date picker helper
  Future<void> _pickDate({
    required String label,
    required String current,
    required ValueChanged<String> onSelected,
  }) async {
    final parts = current.split('/');
    final initial = DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _pink,
            onPrimary: Colors.white,
            onSurface: Colors.black87,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final formatted =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      onSelected(formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePortalAdmin(
      currentIndex: _navIndex,
      onNavTap: (i) => setState(() => _navIndex = i),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page title
          const Text(
            'Exportar Relatórios',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // Filter rows
          _filterRow('Tipo', _tipo, () async {
            await _showPicker(
              title: 'Tipo de relatório',
              options: _tipoOptions,
              current: _tipo,
              onSelected: (v) => setState(() => _tipo = v),
            );
          }),
          _filterRow('Data Início', _dataInicio, () async {
            await _pickDate(
              label: 'Data Início',
              current: _dataInicio,
              onSelected: (v) => setState(() => _dataInicio = v),
            );
          }),
          _filterRow('Data Fim', _dataFim, () async {
            await _pickDate(
              label: 'Data Fim',
              current: _dataFim,
              onSelected: (v) => setState(() => _dataFim = v),
            );
          }),
          _filterRow('Médico', _medico, () async {
            await _showPicker(
              title: 'Médico',
              options: _medicoOptions,
              current: _medico,
              onSelected: (v) => setState(() => _medico = v),
            );
          }),
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
                const Text(
                  'Pré visualização dos dados:',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: _primary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _previewStat(_registos.toString(), 'Registos'),
                    _previewStat(_meses.toString(),    'Meses'),
                    _previewStat(_medicos.toString(),  'Médicos'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Export button
          GestureDetector(
            onTap: () {
              // TODO: trigger export
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'A exportar relatório em $_formato...',
                    style: const TextStyle(fontFamily: 'Poppins'),
                  ),
                  backgroundColor: _primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: _pink,
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Exportar Relatório',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
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
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: _pink,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: _primary,
          ),
        ),
      ],
    );
  }
}