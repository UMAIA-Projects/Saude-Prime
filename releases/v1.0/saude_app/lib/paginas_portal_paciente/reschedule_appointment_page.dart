import 'package:flutter/material.dart';
import 'template/template_portal_paciente.dart';


class RescheduleAppointmentPage extends StatefulWidget {
  final String medicoInitials;
  final String medicoNome;
  final String medicoEspecialidade;
  final String data;
  final String hora;
  final String tipo;
  final String notas;

  const RescheduleAppointmentPage({
    super.key,
    this.medicoInitials      = 'CF',
    this.medicoNome          = 'Dr. Carlos Ferreira',
    this.medicoEspecialidade = 'Clínica Geral',
    this.data                = 'Qui, 27 de Março',
    this.hora                = '10:30',
    this.tipo                = 'Consulta Normal',
    this.notas               = '-',
  });

  @override
  State<RescheduleAppointmentPage> createState() =>
      _RescheduleAppointmentPageState();
}

class _RescheduleAppointmentPageState extends State<RescheduleAppointmentPage> {
  // Color palette
  static const Color _primary      = Color(0xFF1A8070);
  static const Color _accent       = Color(0xFF7CDACF);
  static const Color _accentBorder = Color(0xFF46AA9F);
  static const Color _textSub      = Color(0xFF3DBDAD);
  static const Color _textMuted    = Color(0xFF6A9890);

  // State variables
  int     _navIndex    = 1;
  int?    _selectedDay;
  String? _selectedTime;

  // Calendar navigation — constrained to 2026
  int _currentYear  = 2026;
  int _currentMonth = 3; // March as default

  static const int _minMonth = 1;
  static const int _maxMonth = 12;

  static const List<String> _weekDays = ['Seg','Ter','Qua','Qui','Sex','Sáb','Dom'];

  static const List<String> _monthNames = [
    '', // index 0 unused
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  /// Returns a flat list of nullable ints representing the calendar grid.
  /// Nulls fill the leading offset so day 1 lands on the correct weekday column.
  /// Flutter's DateTime.weekday: 1=Mon … 7=Sun, matching our column order.
  List<int?> get _days {
    final firstWeekday = DateTime(_currentYear, _currentMonth, 1).weekday; // 1=Mon
    final daysInMonth  = DateUtils.getDaysInMonth(_currentYear, _currentMonth);
    final offset       = firstWeekday - 1; // 0-based offset for Mon-first grid

    return [
      ...List<int?>.filled(offset, null),
      ...List<int?>.generate(daysInMonth, (i) => i + 1),
    ];
  }

  // Time slots — state: 'available' | 'taken'
  final List<Map<String, String>> _horarios = [
    {'time': '09:00', 'state': 'taken'},
    {'time': '09:30', 'state': 'available'},
    {'time': '10:00', 'state': 'available'},
    {'time': '10:30', 'state': 'available'},
    {'time': '11:00', 'state': 'available'},
    {'time': '11:30', 'state': 'taken'},
    {'time': '14:00', 'state': 'available'},
    {'time': '14:30', 'state': 'available'},
    {'time': '15:00', 'state': 'taken'},
  ];

  // Navigation helpers
  bool get _isFirstMonth => _currentMonth == _minMonth;
  bool get _isLastMonth  => _currentMonth == _maxMonth;

  void _prevMonth() {
    if (_isFirstMonth) return;
    setState(() {
      _currentMonth--;
      _selectedDay = null;
    });
  }

  void _nextMonth() {
    if (_isLastMonth) return;
    setState(() {
      _currentMonth++;
      _selectedDay = null;
    });
  }

  /// Returns the abbreviated weekday name for the selected day, e.g. "Qua".
  String _getWeekdayAbbr(int day) {
    final dt = DateTime(_currentYear, _currentMonth, day);
    // weekday: 1=Mon…7=Sun — matches _weekDays index (0-based)
    return _weekDays[dt.weekday - 1];
  }

  // Build
  @override
  Widget build(BuildContext context) {
    final days = _days;

    return TemplatePortalPaciente(
      currentIndex: _navIndex,
      onNavTap: (i) => setState(() => _navIndex = i),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page title
          const Text(
            'Consulta - Reagendar',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Current appointment summary card
          Container(
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
                // Doctor row
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
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
                          widget.medicoInitials,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Doctor info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.medicoNome,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _primary,
                            ),
                          ),
                          Text(
                            widget.medicoEspecialidade,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              color: _textSub,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE0F0EE)),

                // Current appointment detail rows
                _InfoRow(icon: Icons.calendar_today_outlined, label: 'Data',  value: widget.data),
                _InfoRow(icon: Icons.access_time_outlined,    label: 'Hora',  value: widget.hora),
                _InfoRow(icon: Icons.medical_services_outlined, label: 'Tipo', value: widget.tipo),
                _InfoRow(
                  icon: Icons.edit_outlined,
                  label: 'Notas',
                  value: widget.notas.isEmpty ? '-' : widget.notas,
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Calendar label + navigation arrows
          Row(
            children: [
              // Previous month arrow
              GestureDetector(
                onTap: _prevMonth,
                child: Icon(
                  Icons.chevron_left,
                  color: _isFirstMonth
                      ? _primary.withValues(alpha: 0.3)
                      : _primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'SELECIONA O DIA - ${_monthNames[_currentMonth].toUpperCase()} $_currentYear',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                ),
              ),
              const SizedBox(width: 4),
              // Next month arrow
              GestureDetector(
                onTap: _nextMonth,
                child: Icon(
                  Icons.chevron_right,
                  color: _isLastMonth
                      ? _primary.withValues(alpha: 0.3)
                      : _primary,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Weekday header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _weekDays.map((d) => SizedBox(
              width: 44,
              child: Text(
                d,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: _textMuted,
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 4),

          // Days grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.4,
            ),
            itemCount: days.length,
            itemBuilder: (_, i) {
              final day = days[i];
              if (day == null) return const SizedBox();

              final isSelected = day == _selectedDay;

              Color bgColor;
              Color textColor;

              if (isSelected) {
                bgColor   = const Color(0x233DBDAD);
                textColor = _textMuted;
              } else {
                bgColor   = _primary;
                textColor = Colors.white;
              }

              return GestureDetector(
                onTap: () => setState(() => _selectedDay = day),
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: const Color(0x473DBDAD))
                        : null,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Time slots label
          const Text(
            'HORÁRIOS DISPONÍVEIS',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _primary,
            ),
          ),
          const SizedBox(height: 8),

          // Time slots grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3.5,
            ),
            itemCount: _horarios.length,
            itemBuilder: (_, i) {
              final h        = _horarios[i];
              final time     = h['time']!;
              final isTaken  = h['state'] == 'taken';
              final isSelected = _selectedTime == time;

              Color bgColor;
              Color borderColor;
              Color textColor;
              TextDecoration textDec = TextDecoration.none;

              if (isTaken) {
                bgColor     = Colors.white.withValues(alpha: 0.35);
                borderColor = const Color(0xFFC8DDD9);
                textColor   = const Color(0xFFA8C5C0);
                textDec     = TextDecoration.lineThrough;
              } else if (isSelected) {
                bgColor     = _textSub;
                borderColor = _textSub;
                textColor   = Colors.white;
              } else {
                bgColor     = Colors.white;
                borderColor = _textSub;
                textColor   = _textSub;
              }

              return GestureDetector(
                onTap: isTaken
                    ? null
                    : () => setState(() => _selectedTime = time),
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
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
                  child: Text(
                    time,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: textColor,
                      decoration: textDec,
                      decorationColor: textColor,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Confirm button
          GestureDetector(
            onTap: () {
              final day = _selectedDay;
              Navigator.pop(context, {
                'data': day != null
                    ? '${_getWeekdayAbbr(day)}, $day de ${_monthNames[_currentMonth]}'
                    : '-',
                'hora': _selectedTime ?? '-',
              });
            },
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
                'Confirmar Novo Horário',
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

          // Cancel link
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Center(
              child: Text(
                'Cancelar',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                  decoration: TextDecoration.underline,
                  decorationColor: _primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// Reusable info row for the summary card
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  static const Color _primary   = Color(0xFF1A8070);
  static const Color _textMuted = Color(0xFF6A9890);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
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
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: 12,
            endIndent: 12,
            color: Color(0xFFE0F0EE),
          ),
      ],
    );
  }
}