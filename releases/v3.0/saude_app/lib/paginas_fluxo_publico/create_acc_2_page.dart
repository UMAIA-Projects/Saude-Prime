import 'package:saude_app/paginas_fluxo_publico/fluxo_publico.dart';

class CreateAccScreen2 extends StatefulWidget {
  final String nome;
  final String nif;
  final DateTime dataNascimento;
  final String telefone;
  final String numUtente;
  final String morada;

  const CreateAccScreen2({
    super.key,
    required this.nome,
    required this.nif,
    required this.dataNascimento,
    required this.telefone,
    required this.numUtente,
    required this.morada,
  });

  @override
  State<CreateAccScreen2> createState() => _CreateAccScreen2State();
}

class _CreateAccScreen2State extends State<CreateAccScreen2> {
  static const Color _verde = Color.fromRGBO(100, 215, 138, 1);

  bool _passVisible = false;
  bool _confirmPassVisible = false;
  bool _aceitouTermos = false;
  bool _isLoading = false; // Novo state para não deixar o user carregar 2 vezes

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(IconData icon, String hint, {Widget? suffix}) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: _verde, size: 20),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontFamily: 'Poppins'),
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

  Future<void> _registarConta() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha os campos obrigatórios.')));
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('As palavras-passe não coincidem!')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      //Criar conta no safe do Supabase (Auth) usando o atalho "db"
      final AuthResponse res = await db.auth.signUp(
        email: email,
        password: password,
      );

      final User? user = res.user;

      if (user != null) {
        //Inserir os dados gerais na tabela pública USERS com role "patient"
        await db.from('users').insert({
          'id': user.id,
          'email': email,
          'name': widget.nome,
          'nif': widget.nif,
          'date_of_birth': widget.dataNascimento.toIso8601String(),
          'phone': widget.telefone,
          'address': widget.morada,
          'role': 'patient', 
        });

        // Inserir os dados médicos na tabela PATIENTS (por ser o default, nao vamos dar perms de admin a todos, depois o admin pode gerir roles)
        await db.from('patients').insert({
          'user_id': user.id,
          'health_number': widget.numUtente,
        });

        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conta criada com sucesso! Por favor inicie sessão.')),
        );

        //Redirect para o Login e apagar as páginas de registo do histórico
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false, // Remove tudo para trás
        );
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro de Autenticação: ${e.message}')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
              onTap: () => Navigator.pop(context), // Um pop chega para voltar à pag 1
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
            const Text('Criar Conta (2/2)', style: TextStyle(fontFamily: 'Poppins', fontSize: 30, fontWeight: FontWeight.w800, color: Colors.black)),
            const SizedBox(height: 20),

            // Email
            const Text('Email', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black)),
            TextField(
              controller: _emailController, // LIGADO
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              decoration: _inputDecoration(Icons.mail_outline, 'email@gmail.com'),
              cursorColor: _verde,
            ),
            const SizedBox(height: 20),

            // Palavra-Passe
            const Text('Palavra-Passe', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black)),
            TextField(
              controller: _passwordController, // LIGADO
              obscureText: !_passVisible,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              decoration: _inputDecoration(
                Icons.lock_outline,
                'Palavra-passe...',
                suffix: GestureDetector(
                  onTap: () => setState(() => _passVisible = !_passVisible),
                  child: Icon(_passVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: _verde, size: 20),
                ),
              ),
              cursorColor: _verde,
            ),
            const SizedBox(height: 20),

            // Confirmar Palavra-Passe
            const Text('Confirmar Palavra-Passe', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black)),
            TextField(
              controller: _confirmPasswordController, // LIGADO
              obscureText: !_confirmPassVisible,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              decoration: _inputDecoration(
                Icons.lock_outline,
                'Repita a palavra-passe...',
                suffix: GestureDetector(
                  onTap: () => setState(() => _confirmPassVisible = !_confirmPassVisible),
                  child: Icon(_confirmPassVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: _verde, size: 20),
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
                    child: _aceitouTermos ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black),
                      children: [
                        const TextSpan(text: 'Declaro que li e aceito os '),
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsConditionsPage())),
                            child: const Text('Termos e Condições', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Color.fromRGBO(100, 215, 138, 1), fontWeight: FontWeight.w600)),
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
                // Só clica se tiver aceitado os termos E não estiver já a carregar
                onPressed: (_aceitouTermos && !_isLoading) ? _registarConta : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _verde,
                  disabledBackgroundColor: _verde.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Criar Conta', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}