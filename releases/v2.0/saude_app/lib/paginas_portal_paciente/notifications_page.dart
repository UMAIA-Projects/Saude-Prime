import 'package:saude_app/paginas_portal_paciente/portal_paciente.dart';

class _Notificacao {
  final String id;
  final String titulo;
  final DateTime createdAt;
  bool isRead;

  _Notificacao({
    required this.id,
    required this.titulo,
    required this.createdAt,
    required this.isRead,
  });

  String get tempoRelativo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return 'Há ${diff.inMinutes} min';
    if (diff.inHours < 24)   return 'Há ${diff.inHours} hora${diff.inHours == 1 ? '' : 's'}';
    if (diff.inDays == 1)    return 'Há 1 dia';
    if (diff.inDays < 7)     return 'Há ${diff.inDays} dias';
    return 'Há ${(diff.inDays / 7).floor()} semana${(diff.inDays / 7).floor() == 1 ? '' : 's'}';
  }
}

// SUPABASE SERVICE

class _NotificacoesService {
  static final _sb     = Supabase.instance.client;
  static String get _userId => _sb.auth.currentUser!.id;

  static Future<List<_Notificacao>> fetchNotificacoes() async {
    final rows = await _sb
        .from('notifications')
        .select('id, message, is_read, created_at')
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return rows.map((r) => _Notificacao(
      id:        r['id'] as String,
      titulo:    r['message'] as String,
      createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
      isRead:    r['is_read'] as bool,
    )).toList();
  }

  static Future<void> marcarComoLida(String id) async {
    await _sb
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  static Future<void> marcarTodasComoLidas() async {
    await _sb
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', _userId)
        .eq('is_read', false);
  }
}

// SCREEN

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const Color _verde = Color(0xFF1A8070);

  int _tabIndex = 0;

  late Future<List<_Notificacao>> _futureNotificacoes;

  // Lista em memória após o fetch — permite mutações otimistas sem refetch
  List<_Notificacao>? _notificacoes;

  @override
  void initState() {
    super.initState();
    _futureNotificacoes = _carregarNotificacoes();
  }

  Future<List<_Notificacao>> _carregarNotificacoes() async {
    final lista = await _NotificacoesService.fetchNotificacoes();
    _notificacoes = lista;
    return lista;
  }

  List<_Notificacao> get _filtradas {
    final lista = _notificacoes ?? [];
    if (_tabIndex == 1) return lista.where((n) => !n.isRead).toList();
    return lista;
  }

  int get _naoLidasCount =>
      (_notificacoes ?? []).where((n) => !n.isRead).length;

  Future<void> _marcarComoLida(_Notificacao notif) async {
    if (notif.isRead) return;
    setState(() => notif.isRead = true);
    try {
      await _NotificacoesService.marcarComoLida(notif.id);
    } catch (_) {
      // Reverte se falhar
      setState(() => notif.isRead = false);
    }
  }

  Future<void> _marcarTodasComoLidas() async {
    final antigas = _notificacoes?.map((n) => n.isRead).toList();
    setState(() {
      for (final n in _notificacoes ?? []) {
        n.isRead = true;
      }
    });
    try {
      await _NotificacoesService.marcarTodasComoLidas();
    } catch (_) {
      // Reverte se falhar
      setState(() {
        for (int i = 0; i < (_notificacoes?.length ?? 0); i++) {
          _notificacoes![i].isRead = antigas?[i] ?? false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePortalPaciente(
      currentIndex: 0,
      child: FutureBuilder<List<_Notificacao>>(
        future: _futureNotificacoes,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final hasError  = snapshot.hasError;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Voltar atrás
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardPaciente()),
                ),
                child: const Text(
                  '< Voltar atrás',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _verde,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Título
              const Text(
                'Notificações',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                  fontFamily: 'Poppins',
                ),
              ),

              const SizedBox(height: 16),

              // Tabs
              Row(
                children: [
                  _Tab(
                    label: 'Todas',
                    ativo: _tabIndex == 0,
                    onTap: () => setState(() => _tabIndex = 0),
                  ),
                  _Tab(
                    label: _naoLidasCount > 0
                        ? 'Não Lidas ($_naoLidasCount)'
                        : 'Não Lidas',
                    ativo: _tabIndex == 1,
                    onTap: () => setState(() => _tabIndex = 1),
                  ),
                ],
              ),

              Container(height: 1, color: const Color(0xFFB2DFDB)),

              const SizedBox(height: 8),

              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(color: _verde),
                  ),
                )
              else if (hasError)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            color: Color(0xFF9E9E9E), size: 36),
                        const SizedBox(height: 12),
                        const Text(
                          'Erro ao carregar notificações.\nVerifica a tua ligação.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => setState(() {
                            _futureNotificacoes = _carregarNotificacoes();
                          }),
                          child: const Text('Tentar novamente',
                              style: TextStyle(
                                  fontFamily: 'Poppins', color: _verde)),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_filtradas.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      _tabIndex == 1
                          ? 'Sem notificações não lidas.'
                          : 'Sem notificações.',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filtradas.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFB2DFDB)),
                  itemBuilder: (context, i) {
                    final notif = _filtradas[i];
                    return GestureDetector(
                      onTap: () => _marcarComoLida(notif),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Indicador lida/não lida
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 3, right: 12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: notif.isRead
                                      ? Colors.transparent
                                      : _verde,
                                ),
                              ),
                            ),
                            // Texto
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notif.titulo,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: notif.isRead
                                          ? FontWeight.w400
                                          : FontWeight.w500,
                                      color: const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    notif.tempoRelativo,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: Color(0xFF9E9E9E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 32),

              // Botão "Marcar todas como lidas"
              if (!isLoading && !hasError && _naoLidasCount > 0)
                Center(
                  child: GestureDetector(
                    onTap: _marcarTodasComoLidas,
                    child: const Text(
                      'MARCAR TODAS COMO LIDAS',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _verde,
                        decoration: TextDecoration.underline,
                        decorationColor: _verde,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

// TAB

class _Tab extends StatelessWidget {
  final String label;
  final bool ativo;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.ativo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: ativo
                    ? const Color(0xFF1A8070)
                    : const Color(0xFF9E9E9E),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 2,
              color: ativo
                  ? const Color(0xFF1A8070)
                  : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}
