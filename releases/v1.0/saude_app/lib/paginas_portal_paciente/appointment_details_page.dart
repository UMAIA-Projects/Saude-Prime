import 'package:flutter/material.dart';
import 'template/template_portal_paciente.dart';
import 'reschedule_appointment_page.dart';

class AppointmentDetailsPage extends StatefulWidget {
  final String medicoInitials;
  final String medicoNome;
  final String medicoEspecialidade;
  final String medicoTelefone;
  final String estado;
  final String data;
  final String hora;
  final String tipo;
  final String notas;
  final List<Map<String, String>> documentos;

  const AppointmentDetailsPage({
    super.key,
    this.medicoInitials      = 'CF',
    this.medicoNome          = 'Dr. Carlos Ferreira',
    this.medicoEspecialidade = 'Clínica Geral',
    this.medicoTelefone      = '220 000 000',
    this.estado              = 'Agendada',
    this.data                = 'Qui, 27 de Março',
    this.hora                = '10:30',
    this.tipo                = 'Consulta Normal',
    this.notas               = '-',
    this.documentos          = const [
      {'nome': 'Análise ao sangue - Março', 'data': '15 Mar', 'tamanho': '1.2 MB'},
    ],
  });

  @override
  State<AppointmentDetailsPage> createState() => _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
  // Color palette
  static const Color _primary      = Color(0xFF1A8070);
  static const Color _accent       = Color(0xFF7CDACF);
  static const Color _accentBorder = Color(0xFF46AA9F);
  static const Color _textSub      = Color(0xFF3DBDAD);
  static const Color _textMuted    = Color(0xFF6A9890);

  // State variables
  int _navIndex = 1;

  // Mutable copies of data/hora so they can be updated after reschedule
  late String _data;
  late String _hora;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
    _hora = widget.hora;
  }

  // Badge colors based on status
  Color _badgeBgColor(String status) {
    switch (status) {
      case 'Realizada': return const Color(0xFFDFF5E3);
      case 'Cancelada': return const Color(0xFFFFE5E5);
      default:          return const Color(0xFFD5EAFF);
    }
  }

  Color _badgeTextColor(String status) {
    switch (status) {
      case 'Realizada': return const Color(0xFF1A7A3C);
      case 'Cancelada': return const Color(0xFF8B1A1A);
      default:          return const Color(0xFF1A3B8B);
    }
  }

  // Navigate to RescheduleAppointmentPage and await result
  Future<void> _openReschedule() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => RescheduleAppointmentPage(
          medicoInitials:      widget.medicoInitials,
          medicoNome:          widget.medicoNome,
          medicoEspecialidade: widget.medicoEspecialidade,
          data:                _data,
          hora:                _hora,
          tipo:                widget.tipo,
          notas:               widget.notas,
        ),
      ),
    );

    // If the user confirmed a new slot, update this page in-place.
    // The stack is unchanged so "Voltar atrás" still goes to MyAppointmentsPage.
    if (result != null) {
      setState(() {
        _data = result['data'] ?? _data;
        _hora = result['hora'] ?? _hora;
      });
    }
  }

  // Build
  @override
  Widget build(BuildContext context) {
    return TemplatePortalPaciente(
      currentIndex: _navIndex,
      onNavTap: (i) => setState(() => _navIndex = i),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page title
          const Text(
            'Consulta - Detalhes',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Doctor card
          Container(
            height: 70,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                        Text(
                          widget.medicoTelefone,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: _textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // View details button
                  GestureDetector(
                    onTap: () {
                      // TODO: navigate to doctor profile
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: _accent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x3F000000),
                            blurRadius: 20,
                            offset: Offset(0, 2),
                            spreadRadius: -10,
                          ),
                        ],
                      ),
                      child: const Text(
                        'Ver Detalhes',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section label: information
          const Text(
            'INFORMAÇÃO',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _primary,
            ),
          ),
          const SizedBox(height: 8),

          // Info card
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
                // Estado row with badge
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: _primary, size: 14),
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 60,
                        child: Text('Estado', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _primary)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _badgeBgColor(widget.estado),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.estado,
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 8, fontWeight: FontWeight.w700, color: _badgeTextColor(widget.estado)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 12, endIndent: 12, color: Color(0xFFE0F0EE)),
                // Data row — uses mutable _data
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: _primary, size: 14),
                      const SizedBox(width: 8),
                      const SizedBox(width: 60, child: Text('Data', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _primary))),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_data, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _textMuted))),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 12, endIndent: 12, color: Color(0xFFE0F0EE)),
                // Hora row — uses mutable _hora
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_outlined, color: _primary, size: 14),
                      const SizedBox(width: 8),
                      const SizedBox(width: 60, child: Text('Hora', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _primary))),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_hora, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _textMuted))),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 12, endIndent: 12, color: Color(0xFFE0F0EE)),
                // Tipo row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.medical_services_outlined, color: _primary, size: 14),
                      const SizedBox(width: 8),
                      const SizedBox(width: 60, child: Text('Tipo', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _primary))),
                      const SizedBox(width: 8),
                      Expanded(child: Text(widget.tipo, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _textMuted))),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 12, endIndent: 12, color: Color(0xFFE0F0EE)),
                // Notas row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, color: _primary, size: 14),
                      const SizedBox(width: 8),
                      const SizedBox(width: 60, child: Text('Notas', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _primary))),
                      const SizedBox(width: 8),
                      Expanded(child: Text(widget.notas.isEmpty ? '-' : widget.notas, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _textMuted))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section label: documents
          const Text(
            'DOCUMENTOS ASSOCIADOS',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _primary,
            ),
          ),
          const SizedBox(height: 8),

          // Documents list
          if (widget.documentos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Sem documentos associados.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: _textMuted,
                ),
              ),
            )
          else
            ...widget.documentos.map((doc) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F4F1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.description_outlined,
                          color: _primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc['nome']!,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${doc['data']} • ${doc['tamanho']}',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: _primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // TODO: download document
                        },
                        child: const Icon(
                          Icons.download_outlined,
                          color: _primary,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )),
          const SizedBox(height: 20),

          // Reschedule button — opens RescheduleAppointmentPage and awaits result
          GestureDetector(
            onTap: _openReschedule,
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
                'Reagendar Consulta',
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

          // Back navigation
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Center(
              child: Text(
                '← Voltar atrás',
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