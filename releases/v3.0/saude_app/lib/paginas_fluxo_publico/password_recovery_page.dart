import 'package:saude_app/paginas_fluxo_publico/fluxo_publico.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, introduz o teu email.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String? redirectUrl = kIsWeb ? null : 'saudeapp://reset-callback';

      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link de recuperação enviado! Verifica o teu email.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Volta para o LoginScreen que tens exportado
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ocorreu um erro inesperado. Tenta novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TemplateFluxoPublico(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 20, 26, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TÍTULO
            const Text(
              'Recuperar\nPalavra-Passe',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
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

            // EMAIL
            const Text('Email'),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
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
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Introduz o teu email e enviaremos um link para redefinires a tua palavra-passe.',
            ),

            const SizedBox(height: 30),

            // BOTÃO COM ESTADO DE LOADING
            GestureDetector(
              onTap: _isLoading ? null : _resetPassword,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: _isLoading
                      ? Colors.grey
                      : const Color.fromRGBO(100, 215, 138, 1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: _isLoading
                    ? const Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : const Text(
                        'Enviar Link',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          // color: Colors.white, // Descomenta se quiseres texto branco
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}