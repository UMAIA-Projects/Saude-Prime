import 'package:saude_app/paginas_fluxo_publico/fluxo_publico.dart';

class TemplateFluxoPublico extends StatelessWidget {
  final Widget child;

  const TemplateFluxoPublico({super.key, required this.child});

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
                    'assets/imagens_fluxo_publico/Vector2.svg',
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