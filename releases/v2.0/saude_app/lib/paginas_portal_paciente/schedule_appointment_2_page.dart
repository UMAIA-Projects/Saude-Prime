import 'package:saude_app/paginas_portal_paciente/portal_paciente.dart';

class ScheduleAppointment2Page extends StatefulWidget {

  final String doctorId;
  final String medicoInitials;
  final String medicoNome;
  final String medicoEspecialidade;

  const ScheduleAppointment2Page({
    super.key,
    required this.doctorId,
    this.medicoInitials      = 'CF',
    this.medicoNome          = 'Dr. Carlos Ferreira',
    this.medicoEspecialidade = 'Clínica Geral',
  });

  @override
  State<ScheduleAppointment2Page> createState() => _ScheduleAppointment2PageState();
}

class _ScheduleAppointment2PageState extends State<ScheduleAppointment2Page> {
  // Colors
  static const Color _primary      = Color(0xFF1A8070);
  static const Color _accent       = Color(0xFF7CDACF);
  static const Color _accentBorder = Color(0xFF46AA9F);
  static const Color _textSub      = Color(0xFF3DBDAD);
  static const Color _textMuted    = Color(0xFF6A9890);

  // Nav
  int _navIndex = 1;

  // Calendário
  int?     _selectedDay;
  String?  _selectedTime;
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

  // Tipo e notas
  final List<String> _tiposConsulta = [
    'Normal', 'Urgência', 'Acompanhamento',
  ];
  String _selectedTipo = 'Normal';
  final TextEditingController _notasController = TextEditingController();

  // Slots — gerados fixos, marcados como 'taken' com base na BD
  static const List<String> _allSlots = [
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '14:00', '14:30', '15:00', '15:30', '16:00', '16:30',
  ];

  // Slots ocupados vindos da BD para o dia seleccionado
  Set<String> _takenSlots    = {};
  bool        _loadingSlots  = false;

  // Nomes
  static const List<String> _weekDays   = ['Seg','Ter','Qua','Qui','Sex','Sáb','Dom'];
  static const List<String> _monthNames = ['Janeiro','Fevereiro','Março','Abril','Maio','Junho','Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'];
  static const List<String> _monthAbbrs = ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'];

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }


  List<int?> get _days {
    final firstDay    = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final startOffset = firstDay.weekday - 1;
    final totalCells  = startOffset + daysInMonth;
    final nextMonthDays = (7 - (totalCells % 7)) % 7;
    return [
      ...List.filled(startOffset, null),
      ...List.generate(daysInMonth, (i) => i + 1),
      ...List.generate(nextMonthDays, (i) => i + 1),
    ];
  }

  String _getWeekdayAbbr(int day) =>
      _weekDays[DateTime(_currentMonth.year, _currentMonth.month, day).weekday - 1];

  String get _monthLabel =>
      '${_monthNames[_currentMonth.month - 1].toUpperCase()} ${_currentMonth.year}';

  String get _monthAbbr => _monthAbbrs[_currentMonth.month - 1];

  void _prevMonth() {
    final now = DateTime.now();
    if (_currentMonth.year == now.year && _currentMonth.month == now.month) return;
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _selectedDay  = null;
      _selectedTime = null;
      _takenSlots   = {};
    });
  }

  void _nextMonth() {
    // Limite: 12 meses no futuro
    final limit = DateTime(DateTime.now().year, DateTime.now().month + 12);
    if (_currentMonth.isAtSameMomentAs(limit) || _currentMonth.isAfter(limit)) return;
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _selectedDay  = null;
      _selectedTime = null;
      _takenSlots   = {};
    });
  }


  Future<void> _selectDay(int day) async {
    setState(() {
      _selectedDay  = day;
      _selectedTime = null;
      _loadingSlots = true;
      _takenSlots   = {};
    });

    try {
      final date  = DateTime(_currentMonth.year, _currentMonth.month, day);
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await Supabase.instance.client
          .from('appointments')
          .select('scheduled_time')
          .eq('doctor_id', widget.doctorId)
          .eq('scheduled_date', dateStr)
          .neq('status', 'canceled');
      final taken = (response as List)
          .map((r) => (r['scheduled_time'] as String).substring(0, 5))
          .toList();
      setState(() {
        _takenSlots   = taken.toSet();
        _loadingSlots = false;
      });
    } catch (_) {
      setState(() => _loadingSlots = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final days        = _days;
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);

    return TemplatePortalPaciente(
      currentIndex: _navIndex,
      onNavTap: (i) => setState(() => _navIndex = i),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título + progresso
          const Text(
            'Marcar Consulta - Horário',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          Row(children: [
            _ProgressBar(color: _accent),
            const SizedBox(width: 4),
            _ProgressBar(color: _accent),
            const SizedBox(width: 4),
            _ProgressBar(color: Colors.white),
          ]),
          const SizedBox(height: 16),

          // Médico seleccionado
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
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: _accent, shape: BoxShape.circle, border: Border.all(color: _accentBorder, width: 2)),
                    alignment: Alignment.center,
                    child: Text(widget.medicoInitials, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                  const SizedBox(width: 10),
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
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text('Mudar', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: _accent, decoration: TextDecoration.underline, decorationColor: _accent)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Calendário
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Color(0x3F000000), blurRadius: 20, offset: Offset(0, 2), spreadRadius: -10)],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Cabeçalho do mês
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(onTap: _prevMonth, child: const Icon(Icons.chevron_left, color: _primary)),
                      Text(_monthLabel, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: _primary)),
                      GestureDetector(onTap: _nextMonth, child: const Icon(Icons.chevron_right, color: _primary)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Dias da semana
                  Row(
                    children: _weekDays.map((d) => Expanded(
                      child: Center(
                        child: Text(d, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: _textMuted)),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 4),

                  // Grelha de dias
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: days.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1),
                    itemBuilder: (_, i) {
                      final day = days[i];
                      if (day == null) return const SizedBox();

                      final isCurrentMonth = day <= daysInMonth;
                      final isSelected     = _selectedDay == day && isCurrentMonth;
                      final isPast         = DateTime(_currentMonth.year, _currentMonth.month, day).isBefore(DateTime.now().subtract(const Duration(days: 1)));
                      final isWeekend      = DateTime(_currentMonth.year, _currentMonth.month, day).weekday >= 6;

                      final isDisabled = !isCurrentMonth || isPast || isWeekend;

                      return GestureDetector(
                        onTap: isDisabled ? null : () => _selectDay(day),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isSelected ? _primary : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                              color: isSelected
                                  ? Colors.white
                                  : isDisabled
                                      ? const Color(0xFFCCCCCC)
                                      : _primary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Slots de horário
          if (_selectedDay != null) ...[
            const Text(
              'HORÁRIOS DISPONÍVEIS',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: _primary),
            ),
            const SizedBox(height: 8),
            if (_loadingSlots)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(color: Color(0xFF1A8070)),
              ))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allSlots.map((slot) {
                  final isTaken    = _takenSlots.contains(slot);
                  final isSelected = _selectedTime == slot;

                  return GestureDetector(
                    onTap: isTaken ? null : () => setState(() => _selectedTime = slot),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isTaken
                            ? const Color(0xFFF5F5F5)
                            : isSelected
                                ? _primary
                                : const Color(0x233DBDAD),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isTaken
                              ? const Color(0xFFE0E0E0)
                              : isSelected
                                  ? _primary
                                  : const Color(0x473DBDAD),
                        ),
                      ),
                      child: Text(
                        slot,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: isTaken
                              ? const Color(0xFFBBBBBB)
                              : isSelected
                                  ? Colors.white
                                  : _textMuted,
                          decoration: isTaken ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
          ],

          // Tipo de consulta
          const Text(
            'TIPO DE CONSULTA',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: _primary),
          ),
          const SizedBox(height: 8),
          _AppointmentTypeDropdown(
            options: _tiposConsulta,
            selected: _selectedTipo,
            onChanged: (v) => setState(() => _selectedTipo = v),
          ),
          const SizedBox(height: 12),

          // Notas
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

          // Navegação
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text('← Voltar atrás', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: _primary, decoration: TextDecoration.underline, decorationColor: _primary)),
              ),
              GestureDetector(
                onTap: (_selectedDay == null || _selectedTime == null)
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScheduleAppointment3Page(
                              doctorId:            widget.doctorId,
                              medicoInitials:      widget.medicoInitials,
                              medicoNome:          widget.medicoNome,
                              medicoEspecialidade: widget.medicoEspecialidade,
                              data:                '${_getWeekdayAbbr(_selectedDay!)}, $_selectedDay $_monthAbbr',
                              hora:                _selectedTime!,
                              tipo:                _selectedTipo,
                              notas:               _notasController.text.isEmpty ? '-' : _notasController.text,
                              scheduledDate:       DateTime(_currentMonth.year, _currentMonth.month, _selectedDay!),
                            ),
                          ),
                        );
                      },
                child: Text(
                  'Continuar →',
                  style: TextStyle(
                    fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700,
                    color: (_selectedDay == null || _selectedTime == null) ? _textMuted : _primary,
                    decoration: TextDecoration.underline,
                    decorationColor: (_selectedDay == null || _selectedTime == null) ? _textMuted : _primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}


class _ProgressBar extends StatelessWidget {
  final Color color;
  const _ProgressBar({required this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: 110, height: 3,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
      );
}

// Dropdown de tipo de consulta — igual ao original
class _AppointmentTypeDropdown extends StatefulWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  const _AppointmentTypeDropdown({required this.options, required this.selected, required this.onChanged});
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
  void dispose() { _animController.dispose(); super.dispose(); }

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
        GestureDetector(
          onTap: _toggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12), topRight: const Radius.circular(12),
                bottomLeft: Radius.circular(_isOpen ? 0 : 12), bottomRight: Radius.circular(_isOpen ? 0 : 12),
              ),
              border: Border.all(color: _isOpen ? _primary : const Color(0x473DBDAD)),
              boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.selected, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: _primary)),
                AnimatedRotation(turns: _isOpen ? 0.5 : 0, duration: const Duration(milliseconds: 180), child: const Icon(Icons.keyboard_arrow_down, color: _primary, size: 20)),
              ],
            ),
          ),
        ),
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
