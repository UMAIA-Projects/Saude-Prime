import 'package:saude_app/paginas_fluxo_publico/fluxo_publico.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
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
                color: Color.fromRGBO(100, 215, 138, 1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 28),

            // EMAIL
            const Text('Email'),
            TextField(
              controller: _emailController,
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

            Text(
              'Introduz o teu email e enviaremos um link para redefinires a tua palavra-passe.',
            ),

            const SizedBox(height: 30),

            // BOTÃO
            GestureDetector(
              onTap: () {
                    Navigator.push(context,MaterialPageRoute(builder: (context) => const LoginScreen()));
                  },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(100, 215, 138, 1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Text(
                  'Enviar Link',
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