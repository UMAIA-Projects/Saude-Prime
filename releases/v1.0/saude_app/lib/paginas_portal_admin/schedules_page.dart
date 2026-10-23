import 'package:flutter/material.dart';
import 'template/template_portal_admin.dart'; // adjust path to match your project structure

class SchedulesPage extends StatefulWidget {
  const SchedulesPage({super.key});

  @override
  State<SchedulesPage> createState() => _SchedulesPageState();
}

class _SchedulesPageState extends State<SchedulesPage> {
  // Color palette
  static const Color _pink        = Color(0xFFD4537E);
  static const Color _teal        = Color(0xFF3DBDAD);
  static const Color _tealLight   = Color(0xFF92D3C9);
  static const Color _navy        = Color(0xFF1A3B8B);
  static const Color _orange      = Color(0xFFFF4800);
  static const Color _orangeLight = Color(0xFFFFE9CD);
  static const Color _timeColor   = Color(0xFF888888);
  static const Color _textSub     = Color(0xFF616161);
  static const Color _divider     = Color(0xFFB1B1B1);

  // State variables
  int    _navIndex     = 2;
  int    _viewMode     = 0; // 0 = Dia, 1 = Semana
  int    _selectedDayIndex = 4; // default: Friday
  String _filterMedico = 'todos';

  // Doctors filter options
  final List<Map<String, dynamic>> _doctors = [
    {'id': 'todos',     'label': 'Todos os médicos'},
    {'id': 'santos',    'label': 'Dr. Santos'},
    {'id': 'mendes',    'label': 'Dra. Mendes'},
    {'id': 'urgencias', 'label': 'Urgências'},
  ];

  // Appointments data — keyed by 'day' (Mon=0..Sat=5) and hour
  final List<Map<String, dynamic>> _appointments = [
    // Monday (Seg 24)
    {'time': '09:00', 'day': 0, 'doctorId': 'santos',    'doctorLabel': 'Santos', 'patient': 'Carlos Mota',      'accent': _teal,   'bg': _tealLight,   'textColor': _textSub, 'hasAlert': false},
    {'time': '11:00', 'day': 0, 'doctorId': 'mendes',    'doctorLabel': 'Mendes', 'patient': 'Beatriz Nunes',    'accent': _navy,   'bg': Colors.white,  'textColor': _textSub, 'hasAlert': false},
    {'time': '14:00', 'day': 0, 'doctorId': 'santos',    'doctorLabel': 'Santos', 'patient': 'Filipe Gomes',     'accent': _teal,   'bg': _tealLight,   'textColor': _textSub, 'hasAlert': false},
    {'time': '16:00', 'day': 0, 'doctorId': 'urgencias', 'doctorLabel': 'Urg.',   'patient': 'Teresa Alves',     'accent': _orange, 'bg': _orangeLight,  'textColor': _orange,  'hasAlert': true},

    // Tuesday (Ter 25)
    {'time': '09:00', 'day': 1, 'doctorId': 'mendes',    'doctorLabel': 'Mendes', 'patient': 'Rui Pereira',      'accent': _navy,   'bg': Colors.white,  'textColor': _textSub, 'hasAlert': false},
    {'time': '10:00', 'day': 1, 'doctorId': 'santos',    'doctorLabel': 'Santos', 'patient': 'Sofia Lopes',      'accent': _teal,   'bg': _tealLight,   'textColor': _textSub, 'hasAlert': false},
    {'time': '14:00', 'day': 1, 'doctorId': 'mendes',    'doctorLabel': 'Mendes', 'patient': 'Jorge Ribeiro',    'accent': _navy,   'bg': Colors.white,  'textColor': _textSub, 'hasAlert': false},
    {'time': '16:00', 'day': 1, 'doctorId': 'santos',    'doctorLabel': 'Santos', 'patient': 'Inês Carvalho',    'accent': _teal,   'bg': _tealLight,   'textColor': _textSub, 'hasAlert': false},

    // Wednesday (Qua 26)
    {'time': '09:00', 'day': 2, 'doctorId': 'santos',    'doctorLabel': 'Santos', 'patient': 'Paulo Ferreira',   'accent': _teal,   'bg': _tealLight,   'textColor': _textSub, 'hasAlert': false},
    {'time': '11:00', 'day': 2, 'doctorId': 'urgencias', 'doctorLabel': 'Urg.',   'patient': 'Clara Mendes',     'accent': _orange, 'bg': _orangeLight,  'textColor': _orange,  'hasAlert': true},
    {'time': '14:00', 'day': 2, 'doctorId': 'santos',    'doctorLabel': 'Santos', 'patient': 'Luís Faria',       'accent': _teal,   'bg': _tealLight,   'textColor': _textSub, 'hasAlert': false},
    {'time': '17:00', 'day': 2, 'doctorId': 'mendes',    'doctorLabel': 'Mendes', 'patient': 'Marta Sousa',      'accent': _navy,   'bg': Colors.white,  'textColor': _textSub, 'hasAlert': false},

    // Thursday (Qui 27)
    {'time': '09:00', 'day': 3, 'doctorId': 'mendes',    'doctorLabel': 'Mendes', 'patient': 'Nuno Araújo',      'accent': _navy,   'bg': Colors.white,  'textColor': _textSub, 'hasAlert': false},
    {'time': '10:00', 'day': 3, 'doctorId': 'santos',    'doctorLabel': 'Santos', 'patient': 'Helena Correia',   'accent': _teal,   'bg': _tealLight,   'textColor': _textSub, 'hasAlert': false},
    {'time': '14:00', 'day': 3, 'doctorId': 'urgencias', 'doctorLabel': 'Urg.',   'patient': 'Marco Pinto',      'accent': _orange, 'bg': _orangeLight,  'textColor': _orange,  'hasAlert': true},
    {'time': '16:00', 'day': 3, 'doctorId': 'mendes',    'doctorLabel': 'Mendes', 'patient': 'Vera Rodrigues',   'accent': _navy,   'bg': Colors.white,  'textColor': _textSub, 'hasAlert': false},

    // Friday (Sex 28)
    {'time': '09:00', 'day': 4, 'doctorId': 'santos',    'doctorLabel': 'Santos', 'patient': 'João Ferreira',    'accent': _teal,   'bg': _tealLight,   'textColor': _textSub, 'hasAlert': false},
    {'time': '10:00', 'day': 4, 'doctorId': 'mendes',    'doctorLabel': 'Mendes', 'patient': 'Ana Costa',        'accent': _navy,   'bg': Colors.white,  'textColor': _textSub, 'hasAlert': false},
    {'time': '11:00', 'day': 4, 'doctorId': 'santos',    'doctorLabel': 'Santos', 'patient': 'Rui Lima',         'accent': _teal,   'bg': _tealLight,   'textColor': _textSub, 'hasAlert': false},
    {'time': '14:00', 'day': 4, 'doctorId': 'urgencias', 'doctorLabel': 'Urg.',   'patient': 'Aníbal Oliveira',  'accent': _orange, 'bg': _orangeLight,  'textColor': _orange,  'hasAlert': true},
    {'time': '16:00', 'day': 4, 'doctorId': 'santos',    'doctorLabel': 'Santos', 'patient': 'Rui Lima',         'accent': _teal,   'bg': _tealLight,   'textColor': _textSub, 'hasAlert': false},
    {'time': '17:00', 'day': 4, 'doctorId': 'mendes',    'doctorLabel': 'Mendes', 'patient': 'Maria Costa',      'accent': _navy,   'bg': Colors.white,  'textColor': _textSub, 'hasAlert': false},

    // Saturday (Sáb 29)
    {'time': '09:00', 'day': 5, 'doctorId': 'santos',    'doctorLabel': 'Santos', 'patient': 'Ricardo Silva',    'accent': _teal,   'bg': _tealLight,   'textColor': _textSub, 'hasAlert': false},
    {'time': '10:00', 'day': 5, 'doctorId': 'urgencias', 'doctorLabel': 'Urg.',   'patient': 'Catarina Dias',    'accent': _orange, 'bg': _orangeLight,  'textColor': _orange,  'hasAlert': true},
    {'time': '11:00', 'day': 5, 'doctorId': 'santos',    'doctorLabel': 'Santos', 'patient': 'Bruno Monteiro',   'accent': _teal,   'bg': _tealLight,   'textColor': _textSub, 'hasAlert': false},
  ];

  // Week days for the week view
  final List<Map<String, String>> _weekDays = [
    {'day': 'Seg', 'date': '24'},
    {'day': 'Ter', 'date': '25'},
    {'day': 'Qua', 'date': '26'},
    {'day': 'Qui', 'date': '27'},
    {'day': 'Sex', 'date': '28'},
    {'day': 'Sáb', 'date': '29'},
  ];

  // Filtered appointments — day view shows selected day
  List<Map<String, dynamic>> get _filtered {
    final dayAppts = _appointments.where((a) => a['day'] == _selectedDayIndex).toList();
    if (_filterMedico == 'todos') return dayAppts;
    return dayAppts.where((a) => a['doctorId'] == _filterMedico).toList();
  }

  // Appointment row widget
  Widget _appointmentRow(Map<String, dynamic> appt) {
    final Color accent    = appt['accent'] as Color;
    final Color bg        = appt['bg'] as Color;
    final Color textColor = appt['textColor'] as Color;
    final bool  hasAlert  = appt['hasAlert'] as bool;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        height: 36,
        child: Row(
          children: [
            // Time column
            SizedBox(
              width: 54,
              child: Text(
                appt['time'] as String,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w300, color: _timeColor),
              ),
            ),
            // Appointment bar
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(5)),
                  ),
                  Positioned(
                    left: 3, top: 0, right: 0, bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${appt['doctorLabel']}: ',
                                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w300, color: _timeColor),
                                  ),
                                  TextSpan(
                                    text: appt['patient'] as String,
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
                                  ),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasAlert)
                            Container(
                              width: 12, height: 12,
                              margin: const EdgeInsets.only(left: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDE201E),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFB31414), width: 1),
                              ),
                            ),
                        ],
                      ),
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

  // Legend item widget
  Widget _legendItem(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 36, height: 22,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _timeColor)),
    ],
  );

  // Week view layout
  Widget _weekView() {
    final timeSlots = ['09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Week header row
        Row(
          children: [
            const SizedBox(width: 40),
            ..._weekDays.asMap().entries.map((e) {
              final dayIndex = e.key;
              final d       = e.value;
              final isToday = dayIndex == 4; // Friday highlighted
              return Expanded(
                child: Column(
                  children: [
                    Text(d['day']!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: _timeColor)),
                    const SizedBox(height: 2),
                    Container(
                      width: 26, height: 26,
                      decoration: isToday
                          ? const BoxDecoration(color: _pink, shape: BoxShape.circle)
                          : null,
                      alignment: Alignment.center,
                      child: Text(
                        d['date']!,
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: isToday ? Colors.white : Colors.black87),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: _divider),

        // Time slot rows
        ...timeSlots.map((time) {
          final hour = time.substring(0, 2);
          return Column(
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Time label
                    SizedBox(
                      width: 40,
                      child: Text(time, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: _timeColor)),
                    ),
                    // Day columns
                    ..._weekDays.asMap().entries.map((e) {
                      final dayIndex = e.key;
                      final appt = _appointments.where((a) {
                        final apptHour = (a['time'] as String).substring(0, 2);
                        final matchDay    = a['day'] == dayIndex;
                        final matchHour   = apptHour == hour;
                        final matchFilter = _filterMedico == 'todos' || a['doctorId'] == _filterMedico;
                        return matchDay && matchHour && matchFilter;
                      }).toList();

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 3),
                          child: appt.isNotEmpty
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: appt.first['accent'] as Color,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    (appt.first['patient'] as String).split(' ').first,
                                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 8, color: Colors.white, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: _divider.withValues(alpha: 0.3)),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const Divider(height: 1, color: _divider),
            ],
          );
        }),

        const SizedBox(height: 16),

        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _legendItem(_teal,   'Dr. Santos'),
            _legendItem(_navy,   'Dra. Mendes'),
            _legendItem(_orange, 'Urgências'),
          ],
        ),
      ],
    );
  }

  // Build
  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return TemplatePortalAdmin(
      currentIndex: _navIndex,
      onNavTap: (i) => setState(() => _navIndex = i),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Agendar button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Agendas',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Doctor filter — bottom border only
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _pink, width: 1.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.black38, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filterMedico,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black26, size: 18),
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.black54),
                      items: _doctors.map((d) => DropdownMenuItem<String>(
                        value: d['id'] as String,
                        child: Opacity(opacity: 0.7, child: Text(d['label'] as String)),
                      )).toList(),
                      onChanged: (v) => setState(() => _filterMedico = v!),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Dia / Semana toggle — bottom border only on active
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ['Dia', 'Semana'].asMap().entries.map((e) {
              final isActive = _viewMode == e.key;
              return GestureDetector(
                onTap: () => setState(() => _viewMode = e.key),
                child: Container(
                  width: 100,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: isActive ? _pink : Colors.transparent, width: 2),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    e.value,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                      color: isActive ? _pink : Colors.black45,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Content: Dia or Semana view
          if (_viewMode == 0) ...[
            // Day selector row
            Row(
              children: _weekDays.asMap().entries.map((e) {
                final i          = e.key;
                final d          = e.value;
                final isSelected = i == _selectedDayIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDayIndex = i),
                    child: Column(
                      children: [
                        Text(
                          d['day']!,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? _pink : _timeColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 28, height: 28,
                          decoration: isSelected
                              ? const BoxDecoration(color: _pink, shape: BoxShape.circle)
                              : null,
                          alignment: Alignment.center,
                          child: Text(
                            d['date']!,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Appointment rows
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: Text('Sem consultas para este filtro.', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _timeColor))),
              )
            else ...[
              const Divider(height: 1, color: _divider),
              ...filtered.map((appt) => Column(
                children: [
                  _appointmentRow(appt),
                  const Divider(height: 1, color: _divider),
                ],
              )),
            ],

            const SizedBox(height: 20),

            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _legendItem(_teal,   'Dr. Santos'),
                _legendItem(_navy,   'Dra. Mendes'),
                _legendItem(_orange, 'Urgências'),
              ],
            ),
          ] else
            _weekView(),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}