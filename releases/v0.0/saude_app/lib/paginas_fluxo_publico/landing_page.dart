import 'package:flutter/material.dart';
import 'template/template_fluxo_publico_2.dart';
import 'login_page.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  Widget build(BuildContext context) {
    return TemplateFluxoPublico2(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 20, 26, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Olá!',
              style: TextStyle(
                fontSize: 70,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                height: 1,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  height: 1.5,
                  fontFamily: 'Poppins',
                ),
                children: [
                  TextSpan(text: 'Bem-vindo(a) à '),
                  TextSpan(
                    text: 'Saúde Prime ++',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF46AA9F),
                    ),
                  ),
                  TextSpan(text: '!\n'),
                  TextSpan(text: 'Marca consultas, acede aos teus exames e evita filas espera. '),
                  TextSpan(
                    text: 'Tudo num só lugar!',
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF46AA9F),
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: const Text(
                  'Vamos a isso!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}