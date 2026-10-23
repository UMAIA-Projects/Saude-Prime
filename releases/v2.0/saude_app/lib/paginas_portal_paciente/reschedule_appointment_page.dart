import 'package:saude_app/paginas_portal_paciente/portal_paciente.dart';

class RescheduleAppointmentPage extends StatefulWidget {
  /// ID da consulta a reagendar (obrigatório para persistir na BD).
  final String appointmentId;

  /// ID do médico (obrigatório para buscar slots ocupados na BD).
  final String doctorId;

  final String medicoInitials;
  final String medicoNome;
  final String medicoEspecialidade;
  final String data;
  final String hora;
  final String tipo;
  final String notas;

  const RescheduleAppointmentPage({
    super.key,
    required this.appointmentId,
    required this.doctorId,
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

class _RescheduleAppointmentPageState
    extends State<RescheduleAppointmentPage> {
  static const Color _primary      = Color(0xFF1A8070);
  static const Color _accent       = Color(0xFF7CDACF);
  static const Color _accentBorder = Color(0xFF46AA9F);
  static const Color _textSub      = Color(0xFF3DBDAD);
  static const Color _textMuted    = Color(0xFF6A9890);

  int _navIndex = 1;

  int?     _selectedDay;
  String?  _selectedTime;

  /// Mês em contexto — começa no mês actual.
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

  static const List<String> _weekDays = [
    'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom',
  ];

  static const List<String> _monthNames = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  // Ficam marcados como 'taken' em função dos dados da BD.
  static const List<String> _allSlots = [
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '14:00', '14:30', '15:00', '15:30', '16:00', '16:30',
  ];

  Set<String> _takenSlots   = {};
  bool        _loadingSlots = false;

  bool _isConfirming = false;


  /// Grid de dias: nulls preenchem os espaços antes do dia 1.
  List<int?> get _days {
    final firstDay    = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(
        _currentMonth.year, _currentMonth.month);
    final startOffset = firstDay.weekday - 1; // 0 = Seg
    return [
      ...List<int?>.filled(startOffset, null),
      ...List<int?>.generate(daysInMonth, (i) => i + 1),
    ];
  }

  String get _monthLabel =>
      'SELECIONA O DIA - ${_monthNames[_currentMonth.month - 1].toUpperCase()} ${_currentMonth.year}';

  /// Abreviatura do dia da semana para um dia no mês actual.
  String _getWeekdayAbbr(int day) =>
      _weekDays[DateTime(_currentMonth.year, _currentMonth.month, day).weekday - 1];

  /// True se o dia já passou (não pode ser seleccionado).
  bool _isPast(int day) {
    final today = DateTime.now();
    final date  = DateTime(_currentMonth.year, _currentMonth.month, day);
    return date.isBefore(DateTime(today.year, today.month, today.day));
  }


  bool get _isFirstMonth {
    final now = DateTime.now();
    return _currentMonth.year == now.year &&
        _currentMonth.month == now.month;
  }

  bool get _isLastMonth {
    final limit = DateTime(DateTime.now().year, DateTime.now().month + 12);
    return !_currentMonth.isBefore(limit);
  }

  void _prevMonth() {
    if (_isFirstMonth) return;
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _selectedDay  = null;
      _selectedTime = null;
      _takenSlots   = {};
    });
  }

  void _nextMonth() {
    if (_isLastMonth) return;
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _selectedDay  = null;
      _selectedTime = null;
      _takenSlots   = {};
    });
  }


  Future<void> _selectDay(int day) async {
    if (_isPast(day)) return; // dias passados não são seleccionáveis

    setState(() {
      _selectedDay  = day;
      _selectedTime = null;
      _loadingSlots = true;
      _takenSlots   = {};
    });

    try {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
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
      if (mounted) {
        setState(() {
          _takenSlots   = taken.toSet();
          _loadingSlots = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingSlots = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar horários: $e')),
        );
      }
    }
  }


  Future<void> _confirm() async {
    final day  = _selectedDay;
    final time = _selectedTime;

    if (day == null || time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleciona um dia e um horário.')),
      );
      return;
    }

    setState(() => _isConfirming = true);

    try {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final dateIso =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      await Supabase.instance.client
          .from('appointments')
          .update({
            'scheduled_date': dateIso,
            'scheduled_time': '$time:00',
            'status':         'scheduled',
            'updated_at':     DateTime.now().toIso8601String(),
          })
          .eq('id', widget.appointmentId);

      if (mounted) {
        // Devolve ao ecrã pai os dados formatados + ISO para que este possa
        // actualizar o estado sem fazer nova query (e ter o date_iso para a BD).
        Navigator.pop(context, {
          'date_iso': dateIso,
          'data': '${_getWeekdayAbbr(day)}, $day de ${_monthNames[_currentMonth.month - 1]}',
          'hora': time,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConfirming = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao reagendar: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final days = _days;

    return TemplatePortalPaciente(
      currentIndex: _navIndex,
      onNavTap: (i) => setState(() => _navIndex = i),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
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

          _buildSummaryCard(),
          const SizedBox(height: 20),

          Row(
            children: [
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
              Expanded(
                child: Text(
                  _monthLabel,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _primary,
                  ),
                ),
              ),
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
              final isPast     = _isPast(day);

              Color bgColor;
              Color textColor;
              Border? border;

              if (isPast) {
                bgColor   = _primary.withValues(alpha: 0.18);
                textColor = Colors.white.withValues(alpha: 0.45);
              } else if (isSelected) {
                bgColor   = const Color(0x233DBDAD);
                textColor = _textMuted;
                border    = Border.all(color: const Color(0x473DBDAD));
              } else {
                bgColor   = _primary;
                textColor = Colors.white;
              }

              return GestureDetector(
                onTap: isPast ? null : () => _selectDay(day),
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: border,
                    boxShadow: const [
                      BoxShadow(
                        color:       Color(0x1A000000),
                        blurRadius:  6,
                        offset:      Offset(0, 1),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontFamily:  'Poppins',
                      fontSize:    11,
                      fontWeight:  FontWeight.w700,
                      color:       textColor,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

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

          if (_selectedDay == null)
            // Nenhum dia seleccionado
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Seleciona um dia para ver os horários disponíveis.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: _textMuted.withValues(alpha: 0.7),
                  ),
                ),
              ),
            )
          else if (_loadingSlots)
            // A carregar slots da BD
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(color: _primary),
              ),
            )
          else
            // Grid de horários
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 3.5,
              ),
              itemCount: _allSlots.length,
              itemBuilder: (_, i) {
                final time       = _allSlots[i];
                final isTaken    = _takenSlots.contains(time);
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
                      color:        bgColor,
                      borderRadius: BorderRadius.circular(10),
                      border:       Border.all(color: borderColor),
                      boxShadow: const [
                        BoxShadow(
                          color:       Color(0x3F000000),
                          blurRadius:  20,
                          offset:      Offset(0, 2),
                          spreadRadius: -10,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      time,
                      style: TextStyle(
                        fontFamily:      'Poppins',
                        fontSize:        12,
                        color:           textColor,
                        decoration:      textDec,
                        decorationColor: textColor,
                      ),
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 24),

          GestureDetector(
            onTap: (_isConfirming || _selectedDay == null || _selectedTime == null)
                ? null
                : _confirm,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: (_selectedDay == null || _selectedTime == null)
                    ? _accent.withValues(alpha: 0.5)
                    : _accent,
                borderRadius: BorderRadius.circular(50),
                boxShadow: const [
                  BoxShadow(
                    color:       Color(0x3F000000),
                    blurRadius:  20,
                    offset:      Offset(0, 2),
                    spreadRadius: -10,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: _isConfirming
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
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


  Widget _buildSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color:       Color(0x3F000000),
            blurRadius:  20,
            offset:      Offset(0, 2),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Column(
        children: [
          // Linha do médico
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

          // Linhas de detalhe
          _InfoRow(icon: Icons.calendar_today_outlined,   label: 'Data',  value: widget.data),
          _InfoRow(icon: Icons.access_time_outlined,       label: 'Hora',  value: widget.hora),
          _InfoRow(icon: Icons.medical_services_outlined,  label: 'Tipo',  value: widget.tipo),
          _InfoRow(
            icon:   Icons.edit_outlined,
            label:  'Notas',
            value:  widget.notas.isEmpty ? '-' : widget.notas,
            isLast: true,
          ),
        ],
      ),
    );
  }
}


class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final bool     isLast;

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
