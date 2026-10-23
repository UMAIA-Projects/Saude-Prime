import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TemplatePortalRecepcao extends StatelessWidget {
  final Widget child;
  final String userInitials;
  final int currentIndex;
  final ValueChanged<int>? onNavTap;

  const TemplatePortalRecepcao({
    super.key,
    required this.child,
    this.userInitials = 'MC',
    this.currentIndex = 0,
    this.onNavTap,
  });

  static const Color _backgroundColor = Color(0xFFE0F4F1);
  static const Color _navColorInactive = Color(0xFFFFFFFF);
  static const Color _navColorActive = Color(0xFF1A3B8B);

  static const double _footerHeight = 130.0;
  static const double _headerHeight = 70.0;
  static const double _pillHeight = 56.0;
  static const double _pillTop = 40.0;

  static const List<String> _navAssets = [
    'assets/imagens_portal_recepcao/Home.svg',
    'assets/imagens_portal_recepcao/People.svg',
    'assets/imagens_portal_recepcao/Schedule.svg',
    'assets/imagens_portal_recepcao/Ticket.svg',
    'assets/imagens_portal_recepcao/Settings.svg',
  ];

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
                  child: child,
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
                decoration: BoxDecoration(
                  color: _backgroundColor.withValues(alpha: 0.95),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/imagens_portal_recepcao/Logo.png',
                      height: 50,
                      fit: BoxFit.contain,
                    ),
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D7BDA).withValues(alpha: 0.73),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF67bed9),
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        userInitials,
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
                        'assets/imagens_portal_recepcao/Vector_Footer_Recepcao.svg',
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
                          color: const Color(0xFF3B6BE0),
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
                          final bool isActive = index == currentIndex;
                          return GestureDetector(
                            onTap: () => onNavTap?.call(index),
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
