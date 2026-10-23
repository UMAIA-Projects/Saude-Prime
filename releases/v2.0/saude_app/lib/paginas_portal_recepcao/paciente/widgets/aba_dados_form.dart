import 'package:saude_app/paginas_portal_recepcao/portal_recepcao.dart';

class AbaDadosForm extends StatelessWidget {
  final TextEditingController nomeCtrl;
  final TextEditingController nifCtrl;
  final TextEditingController dataNascCtrl;
  final TextEditingController telemovelCtrl;
  final TextEditingController snsCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController moradaCtrl;
  final VoidCallback onGuardar;
  final VoidCallback onCancelar;

  const AbaDadosForm({
    super.key,
    required this.nomeCtrl,
    required this.nifCtrl,
    required this.dataNascCtrl,
    required this.telemovelCtrl,
    required this.snsCtrl,
    required this.emailCtrl,
    required this.moradaCtrl,
    required this.onGuardar,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFF3B6BE0).withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _campo('Nome', nomeCtrl),
              _campo('NIF', nifCtrl, teclado: TextInputType.number),
              _campo('Data Nasc.', dataNascCtrl, dica: 'DD/MM/AAAA'),
              _campo('Telemóvel', telemovelCtrl, teclado: TextInputType.phone),
              _campo('SNS', snsCtrl, teclado: TextInputType.number),
              _campo('E-mail', emailCtrl, teclado: TextInputType.emailAddress),
              _campo('Morada', moradaCtrl),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onGuardar,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Guardar Alterações',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onCancelar,
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _campo(
    String label,
    TextEditingController ctrl, {
    TextInputType teclado = TextInputType.text,
    String? dica,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: TextField(
        controller: ctrl,
        keyboardType: teclado,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color.fromARGB(255, 0, 0, 0),
          fontFamily: 'Poppins',
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: dica,
          labelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Colors.black45,
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFB0C4DE), width: 1),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF3B6BE0), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }
}
