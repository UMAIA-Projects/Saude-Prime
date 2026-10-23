import 'package:flutter/material.dart';
import 'template/template_portal_paciente.dart';
import 'schedule_appointment_2_page.dart';

class ScheduleAppointment1Page extends StatefulWidget {
  const ScheduleAppointment1Page({super.key});

  @override
  State<ScheduleAppointment1Page> createState() => _ScheduleAppointment1PageState();
}

class _ScheduleAppointment1PageState extends State<ScheduleAppointment1Page> {
  // Colors
  static const Color _primary      = Color(0xFF1A8070);
  static const Color _accent       = Color(0xFF7CDACF);
  static const Color _accentBorder = Color(0xFF46AA9F);
  static const Color _textSub      = Color(0xFF3DBDAD);
  static const Color _textMuted    = Color(0xFF6A9890);

  // State
  int    _navIndex         = 1;
  int    _especialidadeIdx = 0;
  String _pesquisa         = '';

  // Data
  final List<String> _especialidades = [
    'Clínica Geral',
    'Cardiologia',
    'Ortopedia',
    'Pediatria',
  ];

  final List<Map<String, String>> _medicos = const [
    {'initials': 'CF', 'nome': 'Dr. Carlos Ferreira',  'especialidade': 'Clínica Geral', 'proxVaga': 'Sex, 3 de Abril, 10:00'},
    {'initials': 'LA', 'nome': 'Dr. Lucas Almeida',    'especialidade': 'Clínica Geral', 'proxVaga': 'Qui, 9 de Abril, 16:00'},
    {'initials': 'AS', 'nome': 'Dra. Ana Souza',       'especialidade': 'Clínica Geral', 'proxVaga': 'Ter, 7 de Abril, 12:30'},
    {'initials': 'SP', 'nome': 'Dra. Seixo Paulo',     'especialidade': 'Clínica Geral', 'proxVaga': 'Qui, 9 de Abril, 14:00'},
    {'initials': 'FO', 'nome': 'Dr. Felipe Oliveira',  'especialidade': 'Cardiologia',   'proxVaga': 'Qua, 1 de Abril, 09:00'},
    {'initials': 'MR', 'nome': 'Dr. Mário Rego',       'especialidade': 'Ortopedia',     'proxVaga': 'Seg, 6 de Abril, 11:00'},
    {'initials': 'JP', 'nome': 'Dra. Joana Pires',     'especialidade': 'Pediatria',     'proxVaga': 'Sex, 3 de Abril, 15:30'},
  ];

  List<Map<String, String>> get _medicosFiltrados {
    final especialidade = _especialidades[_especialidadeIdx];
    return _medicos.where((m) {
      final matchEsp  = m['especialidade'] == especialidade;
      final matchPesq = _pesquisa.isEmpty ||
          m['nome']!.toLowerCase().contains(_pesquisa.toLowerCase()) ||
          m['especialidade']!.toLowerCase().contains(_pesquisa.toLowerCase());
      return matchEsp && matchPesq;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePortalPaciente(
      currentIndex: _navIndex,
      onNavTap: (i) => setState(() => _navIndex = i),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Marcar Consulta - Médico',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          Row(
            children: [
              Container(
                width: 110,
                height: 3,
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 110,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 110,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search bar
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (v) => setState(() => _pesquisa = v),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: _primary,
              ),
              decoration: const InputDecoration(
                hintText: 'Pesquisar médico ou especialidade...',
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: _textMuted,
                ),
                prefixIcon: Icon(Icons.search, color: _textMuted, size: 18),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Filter label
          const Text(
            'FILTRAR ESPECIALIDADE',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _primary,
            ),
          ),
          const SizedBox(height: 8),

          // Specialty filter
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_especialidades.length, (i) {
              final isSelected = i == _especialidadeIdx;
              return GestureDetector(
                onTap: () => setState(() => _especialidadeIdx = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? _primary : const Color(0x233DBDAD),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? _primary : const Color(0x473DBDAD),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _especialidades[i],
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: isSelected ? Colors.white : _textMuted,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Doctors list
          if (_medicosFiltrados.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  'Nenhum médico encontrado.',
                  style: TextStyle(fontFamily: 'Poppins', color: _textMuted),
                ),
              ),
            )
          else
            ...List.generate(_medicosFiltrados.length, (i) {
              final m = _medicosFiltrados[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
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
                            m['initials']!,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Info
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m['nome']!,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _primary,
                                ),
                              ),
                              Text(
                                m['especialidade']!,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  color: _textSub,
                                ),
                              ),
                              Text(
                                'Próx. vaga: ${m['proxVaga']}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  color: _textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Schedule button
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ScheduleAppointment2Page(
                                  medicoInitials:      m['initials']!,
                                  medicoNome:          m['nome']!,
                                  medicoEspecialidade: m['especialidade']!,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 80,
                            height: 40,
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
                            alignment: Alignment.center,
                            child: const Text(
                              'Agendar',
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
              );
            }),
        ],
      ),
    );
  }
}