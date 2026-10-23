import 'package:saude_app/paginas_portal_recepcao/portal_recepcao.dart';

class AbaDadosView extends StatelessWidget {
  final PacienteModel paciente;
  final VoidCallback onEditarPressed;

  const AbaDadosView({
    super.key,
    required this.paciente,
    required this.onEditarPressed,
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _linha('Nome', paciente.nome),
              _divisor(),
              _linha('NIF', paciente.nif),
              _divisor(),
              _linha('Data Nasc.', paciente.dataNasc),
              _divisor(),
              _linha('Telemóvel', paciente.telemovel),
              _divisor(),
              _linha('SNS', paciente.sns),
              _divisor(),
              _linha('E-mail', paciente.email),
              _divisor(),
              _linha('Morada', paciente.morada),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9E7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: const [
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sem acesso a diagnósticos ou notas médicas.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB7950B),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onEditarPressed,
            icon: SvgPicture.asset(
              'assets/imagens_portal_recepcao/Edit.svg',
              width: 18,
              height: 18,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
            label: const Text(
              'Entrar em modo de edição',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B6BE0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _linha(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black45,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divisor() =>
      const Divider(height: 1, thickness: 0.5, color: Color(0xFFE0E0E0));
}
