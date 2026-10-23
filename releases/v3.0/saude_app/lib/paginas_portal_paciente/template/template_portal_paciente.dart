import 'package:saude_app/paginas_portal_paciente/portal_paciente.dart';

class TemplatePortalPaciente extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final ValueChanged<int>? onNavTap;

  const TemplatePortalPaciente({
    super.key,
    required this.child,
    this.currentIndex = 0,
    this.onNavTap,
  });

  @override
  State<TemplatePortalPaciente> createState() => _TemplatePortalPacienteState();
}

class _TemplatePortalPacienteState extends State<TemplatePortalPaciente> {
  final db = Supabase.instance.client;
  String _iniciais = '--';

  @override
  void initState() {
    super.initState();
    _carregarIniciaisUser();
  }

  String _calcularIniciais(String nome) {
    final partes = nome.trim().split(' ').where((p) => p.isNotEmpty).toList();

    if (partes.isEmpty) return '??';
    if (partes.length == 1) return partes[0][0].toUpperCase();

    final uteis = partes.where((p) => !p.endsWith('.')).toList();

    if (uteis.length >= 2) {
      return '${uteis.first[0]}${uteis.last[0]}'.toUpperCase();
    }

    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }

  Future<void> _carregarIniciaisUser() async {
    final userId = db.auth.currentUser?.id;

    if (userId == null) {
      if (mounted) setState(() => _iniciais = '??');
      return;
    }

    try {
      final data = await db
          .from('users')
          .select('name')
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          _iniciais = _calcularIniciais(data['name'] ?? '');
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar iniciais: $e');

      if (mounted) {
        setState(() => _iniciais = '??');
      }
    }
  }

  static const Color _backgroundColor = Color(0xFFE0F4F1);
  static const Color _navColorInactive = Color(0xFFFFFFFF);
  static const Color _navColorActive = Color(0xFF1A8070);

  static const double _footerHeight = 130.0;
  static const double _headerHeight = 70.0;
  static const double _pillHeight = 56.0;
  static const double _pillTop = 40.0;

  static const List<String> _navAssets = [
    'assets/imagens_portal_paciente/home.svg',
    'assets/imagens_portal_paciente/calendar.svg',
    'assets/imagens_portal_paciente/ticket.svg',
    'assets/imagens_portal_paciente/documents.svg',
    'assets/imagens_portal_paciente/settings.svg',
  ];

  void _navigateTo(BuildContext context, int index) {
    // Don't navigate if already on this tab
    if (index == widget.currentIndex) return;

    widget.onNavTap?.call(index);

    final Widget destination;
    switch (index) {
      case 0:
        destination = const DashboardPaciente();
        break;
      case 1:
        destination = const ScheduleAppointment1Page();
        break;
      case 2:
        destination = const VirtualQueueScreen();
        break;
      case 3:
        destination = const DocumentsScreen();
        break;
      case 4:
        destination = const ProfileScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => destination,
        // Instant transition - feels native for bottom-nav switching
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
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                decoration: BoxDecoration(color: _backgroundColor),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/imagens_portal_paciente/Logo.png',
                      height: 50,
                      fit: BoxFit.contain,
                    ),
                    Container(
                      width: 45,
                      height: 45,
                      decoration: const BoxDecoration(
                        color: Color(0xFF80CBC4),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _iniciais,
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
                        'assets/imagens_portal_paciente/Vector_Footer_Paciente.svg',
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
                          color: const Color(0xFF80CBC4),
                          borderRadius: BorderRadius.circular(_pillHeight / 2),
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
                                  duration: const Duration(milliseconds: 200),
                                  child: SvgPicture.asset(
                                    _navAssets[index],
                                    key: ValueKey(
                                      '${_navAssets[index]}_$isActive',
                                    ),
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
