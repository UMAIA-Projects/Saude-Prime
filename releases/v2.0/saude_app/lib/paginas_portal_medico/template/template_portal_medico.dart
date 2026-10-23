import 'package:saude_app/paginas_portal_medico/portal_medico.dart';

class TemplatePortalMedico extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final ValueChanged<int>? onNavTap;

  /// Se fornecido externamente (ex: DashboardMedico já foi buscar o nome),
  /// usa este valor directamente — evita um segundo fetch.
  /// Se for vazio (default), o template vai buscar ele próprio.
  final String userInitials;

  const TemplatePortalMedico({
    super.key,
    required this.child,
    this.userInitials = '',
    this.currentIndex = 0,
    this.onNavTap,
  });

  @override
  State<TemplatePortalMedico> createState() => _TemplatePortalMedicoState();
}

class _TemplatePortalMedicoState extends State<TemplatePortalMedico> {
  String _initials = '';

  static const Color _backgroundColor = Color(0xFFE0F4F1);
  static const Color _navColorInactive = Color(0xFFFFFFFF);
  static const Color _navColorActive = Color(0xFF1A8070);

  static const double _footerHeight = 130.0;
  static const double _headerHeight = 70.0;
  static const double _pillHeight = 56.0;
  static const double _pillTop = 40.0;

  static const List<String> _navAssets = [
    'assets/imagens_portal_medico/home.svg',
    'assets/imagens_portal_medico/calendar.svg',
    'assets/imagens_portal_medico/ticket.svg',
    'assets/imagens_portal_medico/search.svg',
    'assets/imagens_portal_medico/settings.svg',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.userInitials.isNotEmpty) {
      _initials = widget.userInitials;
    } else {
      _fetchInitials();
    }
  }

  @override
  void didUpdateWidget(TemplatePortalMedico oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se o pai acabou de receber as iniciais (ex: após o fetch do dashboard)
    if (widget.userInitials.isNotEmpty &&
        widget.userInitials != oldWidget.userInitials) {
      setState(() => _initials = widget.userInitials);
    }
  }

  Future<void> _fetchInitials() async {
    try {
      final userId = db.auth.currentUser?.id;
      if (userId == null) return;
      final row = await db
          .from('users')
          .select('name')
          .eq('id', userId)
          .single();
      final name = row['name'] as String? ?? '';
      if (!mounted) return;
      setState(() => _initials = _toInitials(name));
    } catch (_) {
      // Silently fallback — not critical
    }
  }

  String _toInitials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  void _navigateTo(BuildContext context, int index) {
    if (index == widget.currentIndex) return;
    widget.onNavTap?.call(index);

    final Widget destination;
    switch (index) {
      case 0:
        destination = const DashboardMedico();
        break;
      case 1:
        destination = const Schedule();
        break;
      case 2:
        destination = const VirtualQueue();
        break;
      case 3:
        destination = const Search();
        break;
      case 4:
        destination = const Profile();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          // ── Conteúdo principal ─────────────────────
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.only(
                  top: _headerHeight,
                  bottom: _footerHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: widget.child,
                ),
              ),
            ),
          ),

          // ── Header (logo + avatar) ─────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                decoration: const BoxDecoration(color: _backgroundColor),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/imagens_portal_medico/Logo.png',
                      height: 50,
                      fit: BoxFit.contain,
                    ),
                    // Avatar com iniciais dinâmicas
                    Container(
                      width: 45,
                      height: 45,
                      decoration: const BoxDecoration(
                        color: Color(0xFF46AA9F),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: _initials.isEmpty
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'Poppins',
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Footer (nav bar) ───────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: _footerHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: SvgPicture.asset(
                        'assets/imagens_portal_medico/Vector_Footer_Medico.svg',
                        fit: BoxFit.fill,
                      ),
                    ),
                    Positioned(
                      top: _pillTop,
                      left: 20,
                      right: 20,
                      height: _pillHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF7CDACF),
                          borderRadius:
                              BorderRadius.circular(_pillHeight / 2),
                        ),
                      ),
                    ),
                    Positioned(
                      top: _pillTop,
                      left: 20,
                      right: 20,
                      height: _pillHeight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: List.generate(_navAssets.length, (index) {
                          final bool isActive = index == widget.currentIndex;
                          return GestureDetector(
                            onTap: () => _navigateTo(context, index),
                            behavior: HitTestBehavior.opaque,
                            child: SizedBox(
                              width: 44,
                              height: _pillHeight,
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  child: SvgPicture.asset(
                                    _navAssets[index],
                                    key: ValueKey(
                                        '${_navAssets[index]}_$isActive'),
                                    width: 26,
                                    height: 26,
                                    fit: BoxFit.contain,
                                    colorFilter: ColorFilter.mode(
                                      isActive
                                          ? _navColorActive
                                          : _navColorInactive,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Text(
                        '© 2026 Saúde Prime ++',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}