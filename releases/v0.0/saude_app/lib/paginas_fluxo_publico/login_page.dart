import 'package:flutter/material.dart';
import 'template/template_fluxo_publico.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
 
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
 
class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _efetuarLogin() {
    // Versão 0.0: UI limpa
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login UI a funcionar perfeitamente!')),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return TemplateFluxoPublico(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 20, 26, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Início de Sessão',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                height: 1.1,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 60,
              height: 3,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(100, 215, 138, 1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Email',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'email@gmail.com',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromRGBO(100, 215, 138, 1), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Palavra-Passe',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: '••••••••',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                suffixIcon: GestureDetector(
                  onTap: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  child: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromRGBO(100, 215, 138, 1), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Página não existe na V0.0')));
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Recuperar palavra-passe?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color.fromRGBO(100, 215, 138, 1),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                setState(() {
                  _rememberMe = !_rememberMe;
                });
              },
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                      activeColor: const Color.fromRGBO(100, 215, 138, 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: BorderSide(color: Colors.grey.shade400),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Lembrar de mim',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: _efetuarLogin,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(100, 215, 138, 1),
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: const Text(
                  'Iniciar Sessão',
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
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Ainda não tens conta? ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.black54,
                    fontFamily: 'Poppins',
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Página não existe na V0.0')));
                  },
                  child: const Text(
                    'Regista-te agora!',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color.fromRGBO(100, 215, 138, 1),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}