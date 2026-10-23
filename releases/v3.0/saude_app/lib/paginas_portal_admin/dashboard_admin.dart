import 'package:saude_app/paginas_portal_admin/portal_admin.dart';

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({super.key});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  // Color palette
  static const Color _primary = Color(0xFF1A8070);
  static const Color _accent = Color(0xFF7CDACF);
  static const Color _pink = Color(0xFFD4537E);
  static const Color _textGrey = Color(0xFF616161);

  // State
  int _navIndex = 0;
  bool _loading = true;
  // Stats - preenchidos pelo Supabase
  int _totalPacientes = 0;
  int _medicosAtivos = 0;
  int _consultasHoje = 0;
  int _senhasHoje = 0;
  String _trendPacientes = '↑ A carregar...';
  String _trendConsultas = '↑ A carregar...';

  // Atividade recente - últimas entradas do audit_log
  List<Map<String, dynamic>> _atividade = [];

  // Admin actions
  final List<String> _acoes = [
    'Gerir Utilizadores',
    'Ver todas as agendas',
    'Exportar relatório',
    'Configurações',
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  // Data loading

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    try {
      await Future.wait([_loadStats(), _loadAtividade()]);
    } catch (e) {
      // Em caso de erro silencioso, os valores ficam em zero
      debugPrint('DashboardAdmin error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadStats() async {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // 1. Total de pacientes ativos
    final pacientesRes = await db
        .from('users')
        .select()
        .eq('role', 'patient')
        .isFilter('deleted_at', null)
        .count(CountOption.exact);

    // 2. Médicos ativos
    final medicosRes = await db
        .from('users')
        .select()
        .eq('role', 'doctor')
        .isFilter('deleted_at', null)
        .count(CountOption.exact);

    // 3. Consultas agendadas para hoje
    final consultasRes = await db
        .from('appointments')
        .select()
        .eq('scheduled_date', todayStr)
        .isFilter('deleted_at', null)
        .count(CountOption.exact);

    // 4. Senhas emitidas hoje
    final senhasRes = await db
        .from('virtual_queue')
        .select()
        .gte('issued_at', '${todayStr}T00:00:00')
        .lte('issued_at', '${todayStr}T23:59:59')
        .count(CountOption.exact);

    // 5. Novos pacientes este mês
    final firstOfMonth = DateTime(today.year, today.month, 1);
    final firstOfMonthStr =
        '${firstOfMonth.year}-${firstOfMonth.month.toString().padLeft(2, '0')}-01';
    final novosMesRes = await db
        .from('users')
        .select()
        .eq('role', 'patient')
        .gte('created_at', firstOfMonthStr)
        .isFilter('deleted_at', null)
        .count(CountOption.exact);

    // 6. Consultas de ontem
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayStr =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    final consultasOntemRes = await db
        .from('appointments')
        .select()
        .eq('scheduled_date', yesterdayStr)
        .isFilter('deleted_at', null)
        .count(CountOption.exact);

    if (!mounted) return;

    // PostgrestCountResponse expõe .count (int)
    final totalPacientes = pacientesRes.count;
    final medicosAtivos = medicosRes.count;
    final consultasHoje = consultasRes.count;
    final senhasHoje = senhasRes.count;
    final novosMes = novosMesRes.count;
    final consultasOntem = consultasOntemRes.count;

    setState(() {
      _totalPacientes = totalPacientes;
      _medicosAtivos = medicosAtivos;
      _consultasHoje = consultasHoje;
      _senhasHoje = senhasHoje;

      _trendPacientes = novosMes > 0
          ? '↑ + $novosMes este mês'
          : '- Sem novos este mês';

      if (consultasOntem == 0) {
        _trendConsultas = consultasHoje > 0
            ? '↑ + vs ontem'
            : '- Igual a ontem';
      } else {
        final diff = consultasHoje - consultasOntem;
        _trendConsultas = diff > 0
            ? '↑ + $diff vs ontem'
            : diff < 0
            ? '↓ $diff vs ontem'
            : '- Igual a ontem';
      }
    });
  }

  Future<void> _loadAtividade() async {
    // Últimas 4 entradas do audit_log com o nome do actor
    // Supabase join: audit_log -> users (actor)
    final res = await db
        .from('audit_log')
        .select('description, created_at, actor:users!actor_id(name)')
        .order('created_at', ascending: false)
        .limit(4);

    if (!mounted) return;

    setState(() {
      _atividade = List<Map<String, dynamic>>.from(res as List);
    });
  }

  // Helpers

  // Converte timestamp ISO em label relativo: "2h", "3h", "ontem", etc.
  String _relativeTime(String? isoString) {
    if (isoString == null) return '';
    final dt = DateTime.tryParse(isoString)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }

  // Formata uma linha de atividade a partir de uma entrada do audit_log
  String _formatAtividade(Map<String, dynamic> entry) {
    final actor = (entry['actor'] as Map?)?['name'] as String? ?? 'Sistema';
    final desc = entry['description'] as String? ?? '';
    final time = _relativeTime(entry['created_at'] as String?);
    // Trunca a descrição para caber numa linha
    final shortDesc = desc.length > 50 ? '${desc.substring(0, 50)}…' : desc;
    return '[$actor] $shortDesc - $time';
  }

  // Build

  @override
  Widget build(BuildContext context) {
    // Stats grid
    final stats = [
      {
        'value': '$_totalPacientes',
        'label': 'Pacientes',
        'trend': _trendPacientes,
      },
      {
        'value': '$_medicosAtivos',
        'label': 'Médicos Ativos',
        'trend': '- Estável',
      },
      {
        'value': '$_consultasHoje',
        'label': 'Consultas hoje',
        'trend': _trendConsultas,
      },
      {'value': '$_senhasHoje', 'label': 'Senhas hoje', 'trend': '↑ + hoje'},
    ];

    return TemplatePortalAdmin(
      currentIndex: _navIndex,
      onNavTap: (i) => setState(() => _navIndex = i),
      child: _loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: CircularProgressIndicator(
                  color: Color(0xFF1A8070),
                  strokeWidth: 2,
                ),
              ),
            )
          : Column(
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

                // Stats grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.9,
                  ),
                  itemCount: stats.length,
                  itemBuilder: (_, i) {
                    final stat = stats[i];
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

                // Admin actions
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const UsersListPage(),
                                    ),
                                  );
                                  break;
                                case 1:
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SchedulesPage(),
                                    ),
                                  );
                                  break;
                                case 2:
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ExportReportsPage(),
                                    ),
                                  );
                                  break;
                                case 3:
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ProfilePage(),
                                    ),
                                  );
                                  break;
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _accent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF46AA9F),
                                      ),
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
                            const Divider(
                              height: 1,
                              indent: 36,
                              endIndent: 16,
                              color: Color(0xFFB1B1B1),
                            ),
                        ],
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 24),

                // Atividade recente
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
                  child: _atividade.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Sem atividade recente.',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.black38,
                            ),
                          ),
                        )
                      : Column(
                          children: List.generate(_atividade.length, (i) {
                            final isLast = i == _atividade.length - 1;
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _formatAtividade(_atividade[i]),
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: _textGrey,
                                      ),
                                    ),
                                  ),
                                ),
                                if (!isLast)
                                  const Divider(
                                    height: 1,
                                    indent: 16,
                                    endIndent: 16,
                                    color: Color(0xFFB1B1B1),
                                  ),
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
