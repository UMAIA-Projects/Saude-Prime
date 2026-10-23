import 'package:saude_app/paginas_fluxo_publico/fluxo_publico.dart';

class UpdatePasswordPage extends StatefulWidget {
  const UpdatePasswordPage({super.key});

  @override
  State<UpdatePasswordPage> createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends State<UpdatePasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final newPassword = _passwordController.text.trim();

    if (newPassword.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A palavra-passe deve ter pelo menos 8 caracteres.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Atualiza a password do utilizador atualmente autenticado
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Palavra-passe atualizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Redireciona para o Login após o sucesso
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao atualizar a palavra-passe.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
            const Text(
              'Nova\nPalavra-Passe',
              style: TextStyle(
                fontSize: 36, 
                fontWeight: FontWeight.w700, 
                fontFamily: 'Poppins'
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 60, 
              height: 3,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(100, 215, 138, 1), 
                borderRadius: BorderRadius.circular(2)
              ),
            ),
            const SizedBox(height: 28),
            
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
                hintText: 'Mínimo 8 caracteres',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400, 
                  fontSize: 14, 
                  fontFamily: 'Poppins'
                ),
                prefixIcon: Icon(
                  Icons.lock_outline, 
                  color: Colors.grey.shade400, 
                  size: 20
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
                    width: 2
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
            const SizedBox(height: 30),
            
            GestureDetector(
              onTap: _isLoading ? null : _updatePassword,
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
                            strokeWidth: 2
                          )
                        )
                      )
                    : const Text(
                        'Guardar Password', 
                        textAlign: TextAlign.center, 
                        style: TextStyle(fontWeight: FontWeight.bold)
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}