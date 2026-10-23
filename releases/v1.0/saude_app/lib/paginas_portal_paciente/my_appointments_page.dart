import 'package:flutter/material.dart';
import 'template/template_portal_paciente.dart';
import 'appointment_details_page.dart';
import 'reschedule_appointment_page.dart';

class MyAppointmentsPage extends StatefulWidget {
  final Map<String, String>? novaConsulta; // new confirmed appointment

  const MyAppointmentsPage({super.key, this.novaConsulta});

  @override
  State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends State<MyAppointmentsPage> {
  // Color palette
  static const Color _primary  = Color(0xFF1A8070);
  static const Color _textSub  = Color(0xFF3DBDAD);
  static const Color _textMuted = Color(0xFF6A9890);

  // State variables
  int _navIndex   = 1;
  int _activeTab  = 0; // 0 = Próximas, 1 = Passadas, 2 = Canceladas

  // Tab labels
  final List<String> _tabs = ['Próximas', 'Passadas', 'Canceladas'];

  // Appointment data per tab
  final Map<int, List<Map<String, String>>> _appointments = {
    0: [ // Upcoming
      {'datetime': 'Qui, 3 Abr • 14:30',  'doctor': 'Dr. Carlos Menezes',  'specialty': 'Clínica Geral', 'status': 'Agendada',  'initials': 'CM', 'telefone': '220 000 001', 'hora': '14:30', 'tipo': 'Consulta Geral', 'notas': '-'},
      {'datetime': 'Sex, 11 Abr • 09:00', 'doctor': 'Dr. Asdrubal Silva',  'specialty': 'Clínica Geral', 'status': 'Agendada',  'initials': 'AS', 'telefone': '220 000 002', 'hora': '09:00', 'tipo': 'Consulta Geral', 'notas': '-'},
      {'datetime': 'Sáb, 19 Mai • 11:00', 'doctor': 'Dra. Ana Sofia',      'specialty': 'Clínica Geral', 'status': 'Agendada',  'initials': 'AS', 'telefone': '220 000 003', 'hora': '11:00', 'tipo': 'Consulta Geral', 'notas': '-'},
      {'datetime': 'Ter, 5 Jun • 10:00',  'doctor': 'Dr. Carlos Menezes',  'specialty': 'Clínica Geral', 'status': 'Agendada',  'initials': 'CM', 'telefone': '220 000 001', 'hora': '10:00', 'tipo': 'Consulta Geral', 'notas': '-'},
    ],
    1: [ // Past
      {'datetime': 'Seg, 10 Mar • 09:30', 'doctor': 'Dra. Ana Souza',      'specialty': 'Pediatria',     'status': 'Realizada', 'initials': 'AS', 'telefone': '220 000 004', 'hora': '09:30', 'tipo': 'Pediatria',      'notas': '-'},
      {'datetime': 'Qua, 26 Fev • 14:00', 'doctor': 'Dr. Lucas Almeida',   'specialty': 'Cardiologia',   'status': 'Realizada', 'initials': 'LA', 'telefone': '220 000 005', 'hora': '14:00', 'tipo': 'Cardiologia',    'notas': '-'},
    ],
    2: [ // Cancelled
      {'datetime': 'Sex, 7 Mar • 10:00',  'doctor': 'Dr. Felipe Oliveira', 'specialty': 'Clínica Geral', 'status': 'Cancelada', 'initials': 'FO', 'telefone': '220 000 006', 'hora': '10:00', 'tipo': 'Consulta Geral', 'notas': '-'},
    ],
  };

  // Returns badge color based on status
  Color _badgeBgColor(String status) {
    switch (status) {
      case 'Realizada': return const Color(0xFFDFF5E3);
      case 'Cancelada': return const Color(0xFFFFE5E5);
      default:          return const Color(0xFFD5EAFF); // Agendada
    }
  }

  Color _badgeTextColor(String status) {
    switch (status) {
      case 'Realizada': return const Color(0xFF1A7A3C);
      case 'Cancelada': return const Color(0xFF8B1A1A);
      default:          return const Color(0xFF1A3B8B); // Agendada
    }
  }

  @override
  void initState() {
    super.initState();
    // Insert new confirmed appointment at the top of upcoming list
    if (widget.novaConsulta != null) {
      _appointments[0]!.insert(0, widget.novaConsulta!);
    }
  }

  // Build
  @override
  Widget build(BuildContext context) {
    final appointments = _appointments[_activeTab] ?? [];

    return TemplatePortalPaciente(
      currentIndex: _navIndex,
      onNavTap: (i) => setState(() => _navIndex = i),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab bar
          Row(
            children: List.generate(_tabs.length, (i) {
              final isActive = i == _activeTab;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeTab = i),
                  child: Column(
                    children: [
                      Text(
                        _tabs[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isActive ? _textSub : _textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Active underline indicator
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 2,
                        color: isActive ? _textSub : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Appointment list
          if (appointments.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  'Sem consultas nesta categoria.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: _textMuted,
                  ),
                ),
              ),
            )
          else
            ...appointments.map((appt) {
              final status    = appt['status']!;
              final isUpcoming = _activeTab == 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _primary,
                      width: 3,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x3F000000),
                        blurRadius: 20,
                        offset: Offset(0, 2),
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date/time row + status badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              appt['datetime']!,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _primary,
                              ),
                            ),
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _badgeBgColor(status),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: _badgeTextColor(status),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Doctor and specialty
                        Text(
                          '${appt['doctor']} • ${appt['specialty']}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: _textMuted,
                          ),
                        ),

                        // Action links — upcoming: Ver Detalhes + Reagendar + Cancelar
                        // Past/Cancelled: Ver Detalhes only
                        if (isUpcoming) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AppointmentDetailsPage(
                                        medicoInitials:      appt['initials']  ?? 'CF',
                                        medicoNome:          appt['doctor']    ?? '-',
                                        medicoEspecialidade: appt['specialty'] ?? '-',
                                        medicoTelefone:      appt['telefone']  ?? '-',
                                        estado:              appt['status']    ?? '-',
                                        data:                appt['data']  ?? '-',
                                        hora:                appt['hora']      ?? '-',
                                        tipo:                appt['tipo']      ?? '-',
                                        notas:               appt['notas']     ?? '-',
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Ver Detalhes', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: _primary, decoration: TextDecoration.underline, decorationColor: _primary)),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RescheduleAppointmentPage(
                                        medicoInitials:      appt['initials']  ?? 'CF',
                                        medicoNome:          appt['doctor']    ?? '-',
                                        medicoEspecialidade: appt['specialty'] ?? '-',
                                        data:                appt['data']  ?? '-',
                                        hora:                appt['hora']      ?? '-',
                                        tipo:                appt['tipo']      ?? '-',
                                        notas:               appt['notas']     ?? '-',
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Reagendar', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: _primary, decoration: TextDecoration.underline, decorationColor: _primary)),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    final index = _appointments[0]!.indexOf(appt);
                                    if (index != -1) {
                                      _appointments[0]![index] = {..._appointments[0]![index], 'status': 'Cancelada'};
                                      _appointments[2]!.insert(0, _appointments[0]![index]);
                                      _appointments[0]!.removeAt(index);
                                    }
                                  });
                                },
                                child: const Text('Cancelar', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: _primary, decoration: TextDecoration.underline, decorationColor: _primary)),
                              ),
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AppointmentDetailsPage(
                                    medicoInitials:      appt['initials']  ?? 'CF',
                                    medicoNome:          appt['doctor']    ?? '-',
                                    medicoEspecialidade: appt['specialty'] ?? '-',
                                    medicoTelefone:      appt['telefone']  ?? '-',
                                    estado:              appt['status']    ?? '-',
                                    data:                appt['data']  ?? '-',
                                    hora:                appt['hora']      ?? '-',
                                    tipo:                appt['tipo']      ?? '-',
                                    notas:               appt['notas']     ?? '-',
                                  ),
                                ),
                              );
                            },
                            child: const Text('Ver Detalhes', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: _primary, decoration: TextDecoration.underline, decorationColor: _primary)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}