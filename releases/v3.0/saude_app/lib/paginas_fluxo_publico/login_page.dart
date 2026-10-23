import 'package:saude_app/paginas_fluxo_publico/fluxo_publico.dart';
import '../paginas_portal_paciente/dashboard_paciente.dart';
import '../paginas_portal_medico/dashboard_medico.dart';
import '../paginas_portal_admin/dashboard_admin.dart';
import '../paginas_portal_recepcao/dashboard_recepcao.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<void> _efetuarLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preenche todos os campos.')),
      );
      return;
    }

    try {
      // 1. Tentar fazer login no Supabase Auth usando o atalho "db"
      final AuthResponse res = await db.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final User? user = res.user;

      if (user != null) {
        // 2. Login com sucesso! Usar o "db" para ir buscar o role
        final userData = await db
            .from('users')
            .select('role')
            .eq('id', user.id)
            .single(); // Retorna apenas 1 linha

        final String role = userData['role'];

        if (!mounted) return;

        // 3. Redirecionar para o portal certo com base no role
        switch (role) {
          case 'patient':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const DashboardPaciente(),
              ),
            );
            break;
          case 'doctor':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardMedico()),
            );
            break;
          case 'receptionist':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const DashboardRecepcao(),
              ),
            );
            break;
          case 'admin':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardAdmin()),
            );
            break;
          default:
            throw Exception('Perfil desconhecido');
        }
      }
    } on AuthException catch (e) {
      // Erro de autenticação (ex: password errada)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: ${e.message}')));
    } catch (e) {
      // Outros erros (ex: falha de internet)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro inesperado: $e')));
    }
  }

  bool _obscurePassword = true;
  bool _rememberMe = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Retornamos o Template e passamos o conteúdo do Login como child
    return TemplateFluxoPublico(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 20, 26, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
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

            // Linha decorativa verde sob o título
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

            // -- Campo Email --
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
                  borderSide: BorderSide(
                    color: Color.fromRGBO(100, 215, 138, 1),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),

            const SizedBox(height: 22),

            // Campo Palavra-Passe 
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
                  borderSide: BorderSide(
                    color: Color.fromRGBO(100, 215, 138, 1),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),

            // Link "Recuperar palavra-passe?"
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PasswordRecoveryScreen(),
                    ),
                  );
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

            // Lembrar de mim 
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

            // Botão Iniciar Sessão
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

            // Link Registo 
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateAccScreen1(),
                      ),
                    );
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
