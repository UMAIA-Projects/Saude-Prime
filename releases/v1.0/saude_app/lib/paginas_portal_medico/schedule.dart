import 'package:flutter/material.dart';
import 'package:saude_app/paginas_portal_medico/template/template_portal_medico.dart';
import 'package:saude_app/paginas_portal_medico/blockschedule.dart';
import 'package:saude_app/paginas_portal_medico/dashboard.dart';
import 'package:saude_app/paginas_portal_medico/search.dart';
import 'package:saude_app/paginas_portal_medico/profile.dart';
import 'package:saude_app/paginas_portal_medico/consulta.dart';
import 'package:saude_app/paginas_portal_medico/virtualqueue.dart';
 
class Schedule extends StatefulWidget {
  const Schedule({super.key});
 
  @override
  State<Schedule> createState() => _ScheduleState();
}
 
class _ScheduleState extends State<Schedule> {
  int _selectedDay = 4; // Sex 28 por defeito
  bool _isDiaView = true;
 
  static const List<Map<String, String>> _week = [
    {'label': 'Seg', 'num': '24'},
    {'label': 'Ter', 'num': '25'},
    {'label': 'Qua', 'num': '26'},
    {'label': 'Qui', 'num': '27'},
    {'label': 'Sex', 'num': '28'},
    {'label': 'Sáb', 'num': '29'},
    {'label': 'Dom', 'num': '30'},
  ];
 
  @override
  Widget build(BuildContext context) {
    return TemplatePortalMedico(
      userInitials: 'CS',
      currentIndex: 1,
      onNavTap: (index) {
              if (index == 0) {Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const DashboardMedico()), (r) => false);}
              if (index == 2) {Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const VirtualQueue()), (r) => false);}
              if (index == 3) {Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const Search()), (r) => false);}
              if (index == 4) {Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const Profile()), (r) => false);}
            },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
 
          // ── Navegação semana ──────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {/* TODO: semana anterior */},
                child: const Text(
                  '< Ant.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF50C4A5),
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF50C4A5),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const Text(
                '27 Mar - 2 Abr',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  fontFamily: 'Poppins',
                ),
              ),
              GestureDetector(
                onTap: () {/* TODO: próxima semana */},
                child: const Text(
                  'Próx. >',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF50C4A5),
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF50C4A5),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
 
          const SizedBox(height: 14),
 
          // ── Tabs Dia / Semana ─────────────────────────────────────────────
          Row(
            children: [
              // Dia
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isDiaView = true),
                  child: Column(
                    children: [
                      Text(
                        'Dia',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: _isDiaView
                              ? const Color(0xFF3DBDAD)
                              : Colors.black.withValues(alpha: 0.30),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: _isDiaView ? 2 : 1,
                        color: _isDiaView
                            ? const Color(0xFF3DBDAD)
                            : Colors.black.withValues(alpha: 0.14),
                      ),
                    ],
                  ),
                ),
              ),
              // Semana
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isDiaView = false),
                  child: Column(
                    children: [
                      Text(
                        'Semana',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: !_isDiaView
                              ? const Color(0xFF3DBDAD)
                              : Colors.black.withValues(alpha: 0.30),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: !_isDiaView ? 2 : 1,
                        color: !_isDiaView
                            ? const Color(0xFF3DBDAD)
                            : Colors.black.withValues(alpha: 0.14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
 
          const SizedBox(height: 18),
 
          // ── Seletor de dias ───────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_week.length, (index) {
              final bool isActive = index == _selectedDay;
              return GestureDetector(
                onTap: () => setState(() => _selectedDay = index),
                child: Container(
                  width: 44,
                  height: 58,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF3DBDAD)
                        : const Color(0xCCF2FBFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE1E9E7)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _week[index]['label']!,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                          color: isActive
                              ? Colors.white
                              : Colors.black.withValues(alpha: 0.50),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _week[index]['num']!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                          color: isActive
                              ? Colors.white
                              : Colors.black.withValues(alpha: 0.50),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
 
          const SizedBox(height: 20),
 
          // ── Data + nº consultas ───────────────────────────────────────────
          Text(
            'Sexta, 28 de Março - 4 consultas',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.black.withValues(alpha: 0.45),
              fontFamily: 'Poppins',
            ),
          ),
 
          const SizedBox(height: 16),
 
          // ── Lista de consultas ────────────────────────────────────────────
          _AgendaItem(
            hora: '09:00',
            nome: 'João Ferreira',
            tipo: 'Normal',
            tipoConsulta: _TipoConsulta.normal,
            isDone: true,
          ),
          _AgendaItem(
            hora: '10:30',
            nome: 'Ana Costa',
            tipo: 'Seguimento',
            tipoConsulta: _TipoConsulta.normal,
            isDone: true,
          ),
          GestureDetector(
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const Consulta(
                nomePaciente: 'Aníbal Oliveira',
                iniciais: 'AO',
                nif: '222-***-***',
                data: 'Sex, 28 Mar',
                hora: '14:30',
                tipoConsulta: TipoConsulta.urgente,
                motivo: 'Dores abdominais fortes',
                notas: 'Possível gastroenterite. Prescristo omeprazol 20mg e dieta ligeira...',
              ))),
            child: _AgendaItem(
              hora: '14:30',
              nome: 'Aníbal Oliveira',
              tipo: 'Urgente',
              tipoConsulta: _TipoConsulta.urgente,
              isDone: false,
            ),
          ),
          _AgendaItem(
            hora: '14:30',
            nome: 'Bloqueado - Formação',
            tipo: '',
            tipoConsulta: _TipoConsulta.bloqueado,
            isDone: false,
          ),
 
          const SizedBox(height: 32),
 
          // ── Botão Bloquear Horário ─────────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const BlockSchedule())),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF3DBDAD),
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 20,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Bloquear Horário',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
 
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
 
// ─────────────────────────────────────────────────────────────────────────────
// Widgets auxiliares
// ─────────────────────────────────────────────────────────────────────────────
 
enum _TipoConsulta { normal, urgente, bloqueado }
 
class _AgendaItem extends StatelessWidget {
  final String hora;
  final String nome;
  final String tipo;
  final _TipoConsulta tipoConsulta;
  final bool isDone;
 
  const _AgendaItem({
    required this.hora,
    required this.nome,
    required this.tipo,
    required this.tipoConsulta,
    required this.isDone,
  });
 
  @override
  Widget build(BuildContext context) {
    final Color accentColor = switch (tipoConsulta) {
      _TipoConsulta.urgente   => const Color(0xFFE65100),
      _TipoConsulta.bloqueado => const Color(0xFFA8A8A8),
      _TipoConsulta.normal    => const Color(0xFF3DBDAD),
    };
 
    final Color textColor = switch (tipoConsulta) {
      _TipoConsulta.urgente   => const Color(0xFFE65100),
      _TipoConsulta.bloqueado => const Color(0xFFA8A8A8),
      _TipoConsulta.normal    => Colors.black.withValues(alpha: 0.70),
    };
 
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // hora
            SizedBox(
              width: 42,
              child: Text(
                hora,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withValues(alpha: 0.26),
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            const SizedBox(width: 6),
            // card
            Expanded(
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xE5DAFDF9),
                  borderRadius: BorderRadius.circular(11),
                  border: Border(
                    left: BorderSide(color: accentColor, width: 4),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: tipo.isEmpty
                          ? Row(
                              children: [
                                Text(
                                  nome,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.lock_outline,
                                  size: 16,
                                  color: accentColor,
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Text(
                                  nome,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                Text(
                                  ' • ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textColor,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                Text(
                                  tipo,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                    ),
                    if (isDone)
                      const Icon(
                        Icons.check,
                        size: 15,
                        color: Color(0xFF3DBDAD),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // separador
        Padding(
          padding: const EdgeInsets.only(left: 48),
          child: Divider(
            color: Colors.black.withValues(alpha: 0.10),
            height: 12,
          ),
        ),
      ],
    );
  }
}
