import 'package:flutter/material.dart';
import 'schedule_appointment_3_page.dart';
import 'template/template_portal_paciente.dart';

class ScheduleAppointment2Page extends StatefulWidget {
  final String medicoInitials;
  final String medicoNome;
  final String medicoEspecialidade;

  const ScheduleAppointment2Page({
    super.key,
    this.medicoInitials = 'CF',
    this.medicoNome = 'Dr. Carlos Ferreira',
    this.medicoEspecialidade = 'Clínica Geral',
  });

  @override
  State<ScheduleAppointment2Page> createState() =>
      _ScheduleAppointment2PageState();
}

class _ScheduleAppointment2PageState extends State<ScheduleAppointment2Page> {
  // Color palette
  static const Color _primary      = Color(0xFF1A8070);
  static const Color _accent       = Color(0xFF7CDACF);
  static const Color _accentBorder = Color(0xFF46AA9F);
  static const Color _textSub      = Color(0xFF3DBDAD);
  static const Color _textMuted    = Color(0xFF6A9890);

  // State variables
  int     _navIndex     = 1;
  int?    _selectedDay;
  String? _selectedTime;
  DateTime _currentMonth = DateTime(2026, 3); // starts on March 2026
  final TextEditingController _notasController = TextEditingController();

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  // Appointment type options
  final List<String> _tiposConsulta = [
    'Consulta Geral',
    'Análise',
    'Urgência',
    'Pediatria',
    'Acompanhamento',
  ];
  String _selectedTipo = 'Consulta Geral';

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

  // Calendar weekday headers
  static const List<String> _weekDays = ['Seg','Ter','Qua','Qui','Sex','Sáb','Dom'];

  // Month names
  static const List<String> _monthNames = [
    'Janeiro','Fevereiro','Março','Abril','Maio','Junho',
    'Julho','Agosto','Setembro','Outubro','Novembro','Dezembro',
  ];

  // Month abbreviations
  static const List<String> _monthAbbrs = [
    'Jan','Fev','Mar','Abr','Mai','Jun',
    'Jul','Ago','Set','Out','Nov','Dez',
  ];

  // Dynamically generated days for the current month
  List<int?> get _days {
    final firstDay    = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final startOffset = firstDay.weekday - 1; // Mon=0 ... Sun=6
    final totalCells  = startOffset + daysInMonth;
    final nextMonthDays = (7 - (totalCells % 7)) % 7;

    return [
      ...List.filled(startOffset, null),
      ...List.generate(daysInMonth, (i) => i + 1),
      ...List.generate(nextMonthDays, (i) => i + 1),
    ];
  }

  // Weekday abbreviation using DateTime (always correct)
  String _getWeekdayAbbr(int day) {
    final date = DateTime(_currentMonth.year, _currentMonth.month, day);
    return _weekDays[date.weekday - 1];
  }

  // Month label: e.g. "MARÇO 2026"
  String get _monthLabel =>
      '${_monthNames[_currentMonth.month - 1].toUpperCase()} ${_currentMonth.year}';

  // Month abbreviation: e.g. "Mar"
  String get _monthAbbr => _monthAbbrs[_currentMonth.month - 1];

  // Navigate to previous month (min: Jan 2026)
  void _prevMonth() {
    if (_currentMonth.year == 2026 && _currentMonth.month == 1) return;
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _selectedDay  = null;
    });
  }

  // Navigate to next month (max: Dec 2026)
  void _nextMonth() {
    if (_currentMonth.year == 2026 && _currentMonth.month == 12) return;
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _selectedDay  = null;
    });
  }

  // Build
  @override
  Widget build(BuildContext context) {
    final days = _days;
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);

    return TemplatePortalPaciente(
      currentIndex: _navIndex,
      onNavTap: (i) => setState(() => _navIndex = i),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page title
          const Text(
            'Marcar Consulta - Horário',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          Row(
            children: [
              Container(width: 110, height: 3, decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              Container(width: 110, height: 3, decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              Container(width: 110, height: 3, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
            ],
          ),
          const SizedBox(height: 16),

          // Selected doctor card
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Color(0x3F000000), blurRadius: 20, offset: Offset(0, 2), spreadRadius: -10)],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: _accent, shape: BoxShape.circle, border: Border.all(color: _accentBorder, width: 2)),
                    alignment: Alignment.center,
                    child: Text(widget.medicoInitials, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                  const SizedBox(width: 10),
                  // Doctor info
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.medicoNome, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: _primary)),
                        Text(widget.medicoEspecialidade, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: _textSub)),
                      ],
                    ),
                  ),
                  // Change doctor button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text('Mudar', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: _accent, decoration: TextDecoration.underline, decorationColor: _accent)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Calendar label with navigation arrows
          Row(
            children: [
              Expanded(
                child: Text(
                  'SELECIONA O DIA - $_monthLabel',
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: _primary),
                ),
              ),
              GestureDetector(
                onTap: _prevMonth,
                child: Icon(Icons.chevron_left, color: _currentMonth.month == 1 ? _textMuted : _primary, size: 20),
              ),
              GestureDetector(
                onTap: _nextMonth,
                child: Icon(Icons.chevron_right, color: _currentMonth.month == 12 ? _textMuted : _primary, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Weekday header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _weekDays.map((d) => SizedBox(
              width: 44,
              child: Text(d, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Poppins', fontSize: 9, fontWeight: FontWeight.w600, color: _textMuted)),
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

              // Cells after daysInMonth are next month overflow
              final cellNumber  = i - (days.length - daysInMonth - ((7 - (days.length % 7)) % 7));
              final isNextMonth = day <= 7 && i >= days.indexOf(daysInMonth) + 1;
              final isSelected  = day == _selectedDay && !isNextMonth;

              Color bgColor;
              Color textColor;

              if (isSelected) {
                bgColor   = const Color(0x233DBDAD);
                textColor = _textMuted;
              } else if (isNextMonth) {
                bgColor   = Colors.transparent;
                textColor = _primary.withValues(alpha: 0.3);
              } else {
                bgColor   = _primary;
                textColor = Colors.white;
              }

              return GestureDetector(
                onTap: isNextMonth ? null : () => setState(() => _selectedDay = day),
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected ? Border.all(color: const Color(0x473DBDAD)) : null,
                    boxShadow: isNextMonth ? null : const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 1))],
                  ),
                  alignment: Alignment.center,
                  child: Text('$day', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: textColor)),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Time slots label
          const Text('HORÁRIOS DISPONÍVEIS', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: _primary)),
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
              final h          = _horarios[i];
              final time       = h['time']!;
              final isTaken    = h['state'] == 'taken';
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
                onTap: isTaken ? null : () => setState(() => _selectedTime = time),
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                    boxShadow: const [BoxShadow(color: Color(0x3F000000), blurRadius: 20, offset: Offset(0, 2), spreadRadius: -10)],
                  ),
                  alignment: Alignment.center,
                  child: Text(time, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: textColor, decoration: textDec, decorationColor: textColor)),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Appointment type selector
          const Text('TIPO DE CONSULTA', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: _primary)),
          const SizedBox(height: 8),
          _AppointmentTypeDropdown(
            options: _tiposConsulta,
            selected: _selectedTipo,
            onChanged: (v) => setState(() => _selectedTipo = v),
          ),
          const SizedBox(height: 12),

          // Notes for the doctor
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _textSub),
            ),
            child: TextField(
              controller: _notasController,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _primary),
              decoration: const InputDecoration(
                hintText: 'Notas para o médico (Opcional)',
                hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _textSub),
                prefixIcon: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.edit_outlined, color: _textSub, size: 16),
                ),
                prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Back / Continue navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text('← Voltar atrás', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: _primary, decoration: TextDecoration.underline, decorationColor: _primary)),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScheduleAppointment3Page(
                        medicoInitials:      widget.medicoInitials,
                        medicoNome:          widget.medicoNome,
                        medicoEspecialidade: widget.medicoEspecialidade,
                        data:                _selectedDay != null
                                               ? '${_getWeekdayAbbr(_selectedDay!)}, $_selectedDay $_monthAbbr'
                                               : '-',
                        hora:                _selectedTime ?? '-',
                        tipo:                _selectedTipo,
                        notas:               _notasController.text.isEmpty ? '-' : _notasController.text,
                      ),
                    ),
                  );
                },
                child: const Text('Continuar →', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: _primary, decoration: TextDecoration.underline, decorationColor: _primary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// Custom dropdown overlay for appointment type
class _AppointmentTypeDropdown extends StatefulWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const _AppointmentTypeDropdown({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<_AppointmentTypeDropdown> createState() => _AppointmentTypeDropdownState();
}

class _AppointmentTypeDropdownState extends State<_AppointmentTypeDropdown>
    with SingleTickerProviderStateMixin {
  static const Color _primary   = Color(0xFF1A8070);
  static const Color _textMuted = Color(0xFF6A9890);
  static const Color _textSub   = Color(0xFF3DBDAD);

  bool _isOpen = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    _isOpen ? _animController.forward() : _animController.reverse();
  }

  void _select(String value) {
    widget.onChanged(value);
    setState(() => _isOpen = false);
    _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Trigger button
        GestureDetector(
          onTap: _toggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft:     const Radius.circular(12),
                topRight:    const Radius.circular(12),
                bottomLeft:  Radius.circular(_isOpen ? 0 : 12),
                bottomRight: Radius.circular(_isOpen ? 0 : 12),
              ),
              border: Border.all(color: _isOpen ? _primary : const Color(0x473DBDAD)),
              boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.selected, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: _primary)),
                AnimatedRotation(
                  turns: _isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(Icons.keyboard_arrow_down, color: _primary, size: 20),
                ),
              ],
            ),
          ),
        ),

        // Dropdown list
        FadeTransition(
          opacity: _fadeAnim,
          child: _isOpen
              ? Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                    border: Border.all(color: _primary),
                    boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 16, offset: Offset(0, 6))],
                  ),
                  child: Column(
                    children: widget.options.map((option) {
                      final isSelected = option == widget.selected;
                      final isLast     = option == widget.options.last;
                      return GestureDetector(
                        onTap: () => _select(option),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0x153DBDAD) : Colors.transparent,
                            borderRadius: isLast ? const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)) : null,
                            border: isLast ? null : const Border(bottom: BorderSide(color: Color(0x253DBDAD))),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(option, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? _primary : _textMuted)),
                              if (isSelected) const Icon(Icons.check, color: _textSub, size: 16),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}