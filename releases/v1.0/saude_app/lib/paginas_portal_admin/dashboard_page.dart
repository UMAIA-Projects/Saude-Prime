import 'package:flutter/material.dart';
import 'template/template_portal_admin.dart';
import 'users_list_page.dart';
import 'schedules_page.dart';
import 'export_reports_page.dart';
import 'profile_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Color palette
  static const Color _primary  = Color(0xFF1A8070);
  static const Color _accent   = Color(0xFF7CDACF);
  static const Color _pink     = Color(0xFFD4537E);
  static const Color _textGrey = Color(0xFF616161);

  // State variables
  int _navIndex = 0;

  // Stats data
  final List<Map<String, String>> _stats = [
    {'value': '247', 'label': 'Pacientes',      'trend': '↑ + 12 mês'},
    {'value': '12',  'label': 'Médicos Ativos', 'trend': '— Estável'},
    {'value': '34',  'label': 'Consultas hoje', 'trend': '↑ + vs ontem'},
    {'value': '89',  'label': 'Senhas hoje',    'trend': '↑ + hoje'},
  ];

  // Admin actions
  final List<String> _acoes = [
    'Gerir Utilizadores',
    'Ver todas as agendas',
    'Exportar relatório',
    'Configurações',
  ];

  // Recent activity
  final List<String> _atividade = [
    '[Paula Rego] Atribuiu Médico a Gertrudes - 2h',
    '[Receção] criou Paciente Carlos - 3h',
    '[Médico] enviou doc a Ana Costa - 5h',
    '[Paula Rego] Atribuiu Médico a Horácio - 8h',
  ];

  // Build
  @override
  Widget build(BuildContext context) {
    return TemplatePortalAdmin(
      currentIndex: _navIndex,
      onNavTap: (i) => setState(() => _navIndex = i),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page title
          const Text(
            'Painel Admin',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Stats grid — 2x2
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.9,
            ),
            itemCount: _stats.length,
            itemBuilder: (_, i) {
              final stat = _stats[i];
              return Container(
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
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stat['value']!,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: _pink,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stat['label']!,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: _primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stat['trend']!,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Section label: admin actions
          const Text(
            'AÇÕES ADMINISTRATIVAS',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _primary,
            ),
          ),
          const SizedBox(height: 8),

          // Admin actions list
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: List.generate(_acoes.length, (i) {
                final isLast = i == _acoes.length - 1;
                return Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                          switch (i) {
                            case 0:
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersListPage()));
                              break;
                            case 1:
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const SchedulesPage()));
                              break;
                            case 2:
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportReportsPage()));
                              break;
                            case 3:
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
                              break;
                          }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _accent,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF46AA9F)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _acoes[i],
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: _primary,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!isLast)
                      const Divider(height: 1, indent: 36, endIndent: 16, color: Color(0xFFB1B1B1)),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 24),

          // Section label: recent activity
          const Text(
            'ATIVIDADE RECENTE',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _primary,
            ),
          ),
          const SizedBox(height: 8),

          // Recent activity list
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: List.generate(_atividade.length, (i) {
                final isLast = i == _atividade.length - 1;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _atividade[i],
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: _textGrey,
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFB1B1B1)),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}