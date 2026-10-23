import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TemplateFluxoPublico2 extends StatelessWidget {
  final Widget child;

  const TemplateFluxoPublico2({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/imagens_fluxo_publico/Vector1.svg',
                    width: MediaQuery.of(context).size.width,
                    fit: BoxFit.fitWidth,
                  ),
                  Positioned.fill(
                    child: Center(
                    ),
                  ),
                ],
              ),

                    child,
                    const SizedBox(height: 60),
                    const Center(
                      child: Text(
                        '© 2026 Saúde Prime ++',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w300,
                          color: Colors.black,
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}