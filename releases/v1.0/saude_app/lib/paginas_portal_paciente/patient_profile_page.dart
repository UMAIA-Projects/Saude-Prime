import 'package:flutter/material.dart';
import 'template/template_portal_paciente.dart';
import 'patient_edit_profile_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _verde = Color(0xFF1A8070);

  // Toggles de preferências
  bool _notifEmail = true;
  bool _notifSMS = false;
  bool _lembrete24h = true;

  @override
  Widget build(BuildContext context) {
    return TemplatePortalPaciente(
      currentIndex: 4, // settings
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // perfil + info
          Center(
            child: Column(
              children: [
                // perfil
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A8070),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'RD',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Nome
                const Text(
                  'Rodizio Dinis',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                // Email
                const Text(
                  'DinisRodizio@gmail.com',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Color(0xFF777777),
                  ),
                ),
                const SizedBox(height: 12),
                // badge de paciente
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 8),
                  decoration: BoxDecoration(
                    color: _verde,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'Paciente',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Botão Editar Perfil 
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PatientEditProfileScreen()));
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFB2DFDB), width: 1.5),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Editar Perfil',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF1A8070),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Dados Pessoais 
          const Text(
            'DADOS PESSOAIS',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A8070),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _DadosRow(label: 'NIF', valor: '222 222 222', divisor: true),
                _DadosRow(label: 'Telemóvel', valor: '910 000 000', divisor: true),
                _DadosRow(
                    label: 'Morada',
                    valor: 'Rua Santana, 67, Matosinhos',
                    divisor: false),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'NOTIFICAÇÕES',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A8070),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _ToggleRow(
                  label: 'Notificações por email',
                  value: _notifEmail,
                  onChanged: (v) => setState(() => _notifEmail = v),
                  divisor: true,
                ),
                _ToggleRow(
                  label: 'Notificações por email',
                  value: _notifSMS,
                  onChanged: (v) => setState(() => _notifSMS = v),
                  divisor: true,
                ),
                _ToggleRow(
                  label: 'Lembrete 24h antes',
                  value: _lembrete24h,
                  onChanged: (v) => setState(() => _lembrete24h = v),
                  divisor: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// Widget auxiliar: linha de dado
class _DadosRow extends StatelessWidget {
  final String label;
  final String valor;
  final bool divisor;

  const _DadosRow({
    required this.label,
    required this.valor,
    required this.divisor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  valor,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (divisor)
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
      ],
    );
  }
}

// Widget auxiliar: linha de toggle 
class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool divisor;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.divisor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFF1A8070),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFB2DFDB),
                trackOutlineColor:
                    WidgetStateProperty.all(Colors.transparent),
              ),
            ],
          ),
        ),
        if (divisor)
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
      ],
    );
  }
}