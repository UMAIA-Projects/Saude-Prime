
import 'package:saude_app/paginas_portal_admin/portal_admin.dart';

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

  // State
  int    _navIndex         = 2;
  int    _viewMode         = 0; // 0 = Dia, 1 = Semana
  int    _selectedDayIndex = DateTime.now().weekday - 1; // Mon=0..Sat=5
  String _filterMedico     = 'todos';
  String _userInitials     = '';

  // BD state
  bool   _loading  = true;
  String? _error;

  // Data loaded from Supabase
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _doctors      = [
    {'id': 'todos', 'label': 'Todos os médicos'},
  ];

  // Current week — Monday of this week
  late DateTime _weekStart;

  // Week days for display
  late List<Map<String, String>> _weekDays;

  @override
  void initState() {
    super.initState();
    _buildWeek();
    _loadUserInitials();
    _loadData();
  }

  // Load user initials from DB
  Future<void> _loadUserInitials() async {
    try {
      final user = db.auth.currentUser;
      if (user != null) {
        final res = await db
            .from('users')
            .select('name')
            .eq('id', user.id)
            .single();
        final name = res['name'] as String? ?? '';
        final initials = name
            .split(' ')
            .where((word) => word.isNotEmpty)
            .take(2)
            .map((word) => word[0].toUpperCase())
            .join('');
        if (mounted) {
          setState(() => _userInitials = initials.isEmpty ? '?' : initials);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _userInitials = '?');
    }
  }

  // Build week days starting from Monday of current week
  void _buildWeek() {
    final now   = DateTime.now();
    _weekStart  = now.subtract(Duration(days: now.weekday - 1));
    const labels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    _weekDays = List.generate(7, (i) {
      final d = _weekStart.add(Duration(days: i));
      return {
        'day':  labels[i],
        'date': d.day.toString(),
        'iso':  d.toIso8601String().substring(0, 10),
      };
    });
  }

  // Load doctors + appointments for the current week from Supabase
  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });

    try {
      final supabase = Supabase.instance.client;

      final weekEnd = _weekStart.add(const Duration(days: 6));

      // Load appointments with patient and doctor names
      final raw = await supabase
          .from('appointments')
          .select('''
            id,
            scheduled_date,
            scheduled_time,
            type,
            status,
            patient:patients!appointments_patient_id_fkey(
              user:users!patients_user_id_fkey(name)
            ),
            doctor:doctors!appointments_doctor_id_fkey(
              user_id,
              user:users!doctors_user_id_fkey(name)
            )
          ''')
          .gte('scheduled_date', _weekStart.toIso8601String().substring(0, 10))
          .lte('scheduled_date', weekEnd.toIso8601String().substring(0, 10))
          .isFilter('deleted_at', null)
          .order('scheduled_date')
          .order('scheduled_time');

      // Build doctors list from results
      final Map<String, String> doctorMap = {'todos': 'Todos os médicos'};
      for (final row in raw) {
        final doctorId   = row['doctor']?['user_id'] as String?;
        final doctorName = row['doctor']?['user']?['name'] as String?;
        if (doctorId != null && doctorName != null) {
          doctorMap[doctorId] = doctorName;
        }
      }

      // Map appointments to local display format
      final List<Map<String, dynamic>> mapped = raw.map((row) {
        final date      = row['scheduled_date'] as String;
        final dayIndex  = _weekDays.indexWhere((d) => d['iso'] == date);
        final type      = row['type'] as String? ?? 'normal';
        final isUrgent  = type == 'urgent';
        final doctorId  = row['doctor']?['user_id'] as String? ?? '';
        final doctorName = row['doctor']?['user']?['name'] as String? ?? '—';
        final doctorShort = doctorName.split(' ').last; // e.g. "Santos"
        final patientName = row['patient']?['user']?['name'] as String? ?? '—';
        final time      = (row['scheduled_time'] as String).substring(0, 5); // HH:mm

        return {
          'id':          row['id'],
          'time':        time,
          'day':         dayIndex,
          'doctorId':    doctorId,
          'doctorLabel': doctorShort,
          'patient':     patientName,
          'accent':      isUrgent ? _orange : _teal,
          'bg':          isUrgent ? _orangeLight : _tealLight,
          'textColor':   isUrgent ? _orange : _textSub,
          'hasAlert':    isUrgent,
        };
      }).where((a) => a['day'] != -1).toList();

      setState(() {
        _appointments = mapped;
        _doctors = doctorMap.entries
            .map((e) => {'id': e.key, 'label': e.value})
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error   = 'Erro ao carregar agendas: $e';
        _loading = false;
      });
    }
  }

  // Filtered appointments for day view
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
            SizedBox(
              width: 54,
              child: Text(
                appt['time'] as String,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w300, color: _timeColor),
              ),
            ),
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
                              TextSpan(children: [
                                TextSpan(
                                  text: '${appt['doctorLabel']}: ',
                                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w300, color: _timeColor),
                                ),
                                TextSpan(
                                  text: appt['patient'] as String,
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
                                ),
                              ]),
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

  Widget _weekView() {
    final timeSlots = ['09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(width: 40),
            ..._weekDays.asMap().entries.map((e) {
              final isToday = _weekStart.add(Duration(days: e.key)).day == DateTime.now().day;
              return Expanded(
                child: Column(
                  children: [
                    Text(e.value['day']!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: _timeColor)),
                    const SizedBox(height: 2),
                    Container(
                      width: 26, height: 26,
                      decoration: isToday ? const BoxDecoration(color: _pink, shape: BoxShape.circle) : null,
                      alignment: Alignment.center,
                      child: Text(
                        e.value['date']!,
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
        ...timeSlots.map((time) {
          final hour = time.substring(0, 2);
          return Column(
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(time, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: _timeColor)),
                    ),
                    ..._weekDays.asMap().entries.map((e) {
                      final dayIndex = e.key;
                      final appt = _appointments.where((a) {
                        final apptHour  = (a['time'] as String).substring(0, 2);
                        final matchFilter = _filterMedico == 'todos' || a['doctorId'] == _filterMedico;
                        return a['day'] == dayIndex && apptHour == hour && matchFilter;
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
        Wrap(
          spacing: 16, runSpacing: 8,
          children: [
            _legendItem(_teal,   'Normal'),
            _legendItem(_orange, 'Urgências'),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return TemplatePortalAdmin(
      userInitials: _userInitials,
      currentIndex: _navIndex,
      onNavTap: (i) => setState(() => _navIndex = i),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + refresh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Agendas',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black87),
              ),
              if (!_loading)
                GestureDetector(
                  onTap: _loadData,
                  child: const Icon(Icons.refresh, color: _pink, size: 22),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Error banner
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: Text(_error!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFFC62828))),
            ),

          // Doctor filter
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
                      value: _doctors.any((d) => d['id'] == _filterMedico) ? _filterMedico : 'todos',
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

          // Dia / Semana toggle
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
                    border: Border(bottom: BorderSide(color: isActive ? _pink : Colors.transparent, width: 2)),
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

          // Loading indicator
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(color: _pink),
              ),
            )
          else if (_viewMode == 0) ...[
            // Day selector
            Row(
              children: _weekDays.asMap().entries.map((e) {
                final i = e.key;
                final d = e.value;
                final isSelected = i == _selectedDayIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDayIndex = i),
                    child: Column(
                      children: [
                        Text(
                          d['day']!,
                          style: TextStyle(
                            fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600,
                            color: isSelected ? _pink : _timeColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 28, height: 28,
                          decoration: isSelected ? const BoxDecoration(color: _pink, shape: BoxShape.circle) : null,
                          alignment: Alignment.center,
                          child: Text(
                            d['date']!,
                            style: TextStyle(
                              fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700,
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

            // Appointments
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(
                  child: Text(
                    'Sem consultas para este dia.',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _timeColor),
                  ),
                ),
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
            Wrap(
              spacing: 16, runSpacing: 8,
              children: [
                _legendItem(_teal,   'Normal'),
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