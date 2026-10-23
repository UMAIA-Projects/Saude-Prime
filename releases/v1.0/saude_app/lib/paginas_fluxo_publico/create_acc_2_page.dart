import 'package:flutter/material.dart';
import 'template/template_fluxo_publico.dart';
import 'create_acc_1_page.dart';
import 'terms_conditions_page.dart';
import '../paginas_portal_paciente/dashboard_page.dart';

class CreateAccScreen2 extends StatefulWidget {
  const CreateAccScreen2({super.key});

  @override
  State<CreateAccScreen2> createState() => _CreateAccScreen2State();
}

class _CreateAccScreen2State extends State<CreateAccScreen2> {
  static const Color _verde = Color.fromRGBO(100, 215, 138, 1);

  bool _passVisible = false;
  bool _confirmPassVisible = false;
  bool _aceitouTermos = false;

  InputDecoration _inputDecoration(IconData icon, String hint, {Widget? suffix}) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: _verde, size: 20),
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 14,
        fontFamily: 'Poppins',
      ),
      suffixIcon: suffix,
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color.fromRGBO(100, 215, 138, 1), width: 1.5),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color.fromRGBO(100, 215, 138, 1), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TemplateFluxoPublico(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 16, 26, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Voltar atrás
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateAccScreen1()),
              ),
              child: const Text(
                '< Voltar atrás',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color.fromRGBO(100, 215, 138, 1),
                  decoration: TextDecoration.underline,
                  decorationColor: Color.fromRGBO(100, 215, 138, 1),
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Criar Conta (2/2)',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 20),

            // Email
            const Text(
              'Email',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            TextField(
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              decoration: _inputDecoration(Icons.mail_outline, 'email@gmail.com'),
              cursorColor: _verde,
            ),

            const SizedBox(height: 20),

            // Palavra-Passe
            const Text(
              'Palavra-Passe',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            TextField(
              obscureText: !_passVisible,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              decoration: _inputDecoration(
                Icons.lock_outline,
                'Palavra-passe...',
                suffix: GestureDetector(
                  onTap: () => setState(() => _passVisible = !_passVisible),
                  child: Icon(
                    _passVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: _verde,
                    size: 20,
                  ),
                ),
              ),
              cursorColor: _verde,
            ),

            const SizedBox(height: 20),

            // Confirmar Palavra-Passe
            const Text(
              'Confirmar Palavra-Passe',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            TextField(
              obscureText: !_confirmPassVisible,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              decoration: _inputDecoration(
                Icons.lock_outline,
                'Repita a palavra-passe...',
                suffix: GestureDetector(
                  onTap: () => setState(() => _confirmPassVisible = !_confirmPassVisible),
                  child: Icon(
                    _confirmPassVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: _verde,
                    size: 20,
                  ),
                ),
              ),
              cursorColor: _verde,
            ),

            const SizedBox(height: 24),

            // Termos e Condições
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _aceitouTermos = !_aceitouTermos),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _verde, width: 2),
                      color: _aceitouTermos ? _verde : Colors.transparent,
                    ),
                    child: _aceitouTermos
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.black,
                      ),
                      children: [
                        const TextSpan(text: 'Declaro que li e aceito os '),
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const TermsConditionsPage()),
                            ),
                            child: const Text(
                              'Termos e Condições',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: Color.fromRGBO(100, 215, 138, 1),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Botão Criar Conta
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _aceitouTermos
                    ? () {
                        Navigator.push(context,MaterialPageRoute(builder: (context) => DashboardPage()));
                      }
                    : null, // desativado enquanto não aceitar os termos
                style: ElevatedButton.styleFrom(
                  backgroundColor: _verde,
                  disabledBackgroundColor: _verde.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Criar Conta',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}