import 'package:saude_app/paginas_fluxo_publico/fluxo_publico.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  late final TextEditingController _atualCtrl;
  late final TextEditingController _novaCtrl;
  bool _obscureAtual = true;
  bool _obscureNova = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _atualCtrl = TextEditingController();
    _novaCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _atualCtrl.dispose();
    _novaCtrl.dispose();
    super.dispose();
  }

  Future<void> _alterarPassword() async {
    final passwordAtual = _atualCtrl.text.trim();
    final passwordNova = _novaCtrl.text.trim();

    // Validações básicas 
    if (passwordAtual.isEmpty || passwordNova.isEmpty) {
      _mostrarErro('Preenche ambos os campos.');
      return;
    }
    if (passwordNova.length < 6) {
      _mostrarErro('A nova palavra-passe deve ter pelo menos 6 caracteres.');
      return;
    }
    if (passwordAtual == passwordNova) {
      _mostrarErro('A nova palavra-passe deve ser diferente da atual.');
      return;
    }

    setState(() => _loading = true);

    try {
      // 1. Verificar a password atual re-autenticando com o email do utilizador
      final email = db.auth.currentUser?.email;
      if (email == null) {
        _mostrarErro('Sessão inválida. Inicia sessão novamente.');
        return;
      }

      await db.auth.signInWithPassword(email: email, password: passwordAtual);

      // 2. Atualizar para a nova password
      await db.auth.updateUser(UserAttributes(password: passwordNova));

      // 3. Terminar sessão e redirecionar para o login
      await db.auth.signOut();

      if (!mounted) return;
      _mostrarSucesso();
    } on AuthException catch (e) {
      if (!mounted) return;
      // Mensagem amigável consoante o erro do Supabase
      if (e.message.toLowerCase().contains('invalid login')) {
        _mostrarErro('Palavra-passe atual incorreta.');
      } else {
        _mostrarErro('Erro: ${e.message}');
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarErro('Ocorreu um erro inesperado. Tenta novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarSucesso() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Palavra-passe alterada com sucesso!',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor: Color(0xFF64D68A),
        behavior: SnackBarBehavior.floating,
      ),
    );
    // Redirecionar para o login limpando toda a navegação
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TemplateFluxoPublico(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),

            // Voltar 
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text(
                '< Voltar atrás',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF50C4A5),
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFF50C4A5),
                  fontFamily: 'Poppins',
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Título 
            const Text(
              'Alterar\nPalavra-Passe',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                fontFamily: 'Poppins',
                height: 1.1,
              ),
            ),

            const SizedBox(height: 36),

            // Campo: Palavra-passe Atual
            const Text(
              'Palavra-passe Atual',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 6),
            _CampoPassword(
              controller: _atualCtrl,
              obscure: _obscureAtual,
              onToggle: () => setState(() => _obscureAtual = !_obscureAtual),
            ),

            const SizedBox(height: 24),

            // Campo: Nova Palavra-passe 
            const Text(
              'Nova Palavra-passe',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 6),
            _CampoPassword(
              controller: _novaCtrl,
              obscure: _obscureNova,
              onToggle: () => setState(() => _obscureNova = !_obscureNova),
            ),

            const SizedBox(height: 40),

            // Botão Alterar 
            GestureDetector(
              onTap: _loading ? null : _alterarPassword,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF64D68A),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3364D68A),
                      blurRadius: 20,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: _loading
                    ? const Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Alterar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Poppins',
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


// Campo de password com toggle visibilidade
class _CampoPassword extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  const _CampoPassword({
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(
        fontSize: 14,
        fontFamily: 'Poppins',
        color: Colors.black,
      ),
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: Color(0xFF64D68A),
          size: 20,
        ),
        suffixIcon: GestureDetector(
          onTap: onToggle,
          child: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.black26,
            size: 20,
          ),
        ),
        hintText: '••••••••••••••••••',
        hintStyle: TextStyle(
          fontSize: 14,
          color: Colors.black.withValues(alpha: 0.30),
          fontFamily: 'Poppins',
          letterSpacing: 2,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF64D68A), width: 1.5),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF64D68A), width: 2),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }
}
