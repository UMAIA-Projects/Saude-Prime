import 'package:flutter/material.dart';
import 'template/template_portal_paciente.dart';
import 'patient_profile_page.dart';

class PatientEditProfileScreen extends StatelessWidget {
  const PatientEditProfileScreen({super.key});

  static const Color _verde = Color(0xFF1A8070);

  InputDecoration _inputDecoration(IconData icon, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
        color: Color(0xFF1A1A1A),
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF1A1A1A), size: 22),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF1A8070), width: 1.5),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF1A8070), width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePortalPaciente(
      currentIndex: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Voltar atrás
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: const Text(
              '< Voltar atrás',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A8070),
              ),
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'Editar Perfil',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),

          const SizedBox(height: 24),

          // ── Campos editáveis (ilustrativos) ───────────────────────────

          TextField(
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 15),
            decoration: _inputDecoration(Icons.person_outline, 'Rodízio Dinis'),
            cursorColor: _verde,
          ),

          const SizedBox(height: 8),

          TextField(
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 15),
            decoration: _inputDecoration(Icons.phone_outlined, '910 000 000'),
            cursorColor: _verde,
          ),

          const SizedBox(height: 8),

          TextField(
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 15),
            decoration: _inputDecoration(
                Icons.home_outlined, 'Rua Santana, 67, Matosinhos'),
            cursorColor: _verde,
          ),

          const SizedBox(height: 8),

          TextField(
            keyboardType: TextInputType.number,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 15),
            decoration: _inputDecoration(Icons.tag, '000000000'),
            cursorColor: _verde,
          ),

          const SizedBox(height: 28),

          // ── Card "Não Editável" ────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NÃO EDITÁVEL',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9E9E9E),
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),

                // NIF
                const Row(
                  children: [
                    Icon(Icons.credit_card_off_outlined,
                        size: 18, color: Color(0xFFB2B2B2)),
                    SizedBox(width: 10),
                    Text(
                      '222 222 222',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Color(0xFFB2B2B2),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20, color: Color(0xFFE0E0E0)),
                const Text(
                  'Para alterar o NIF, contacta a clínica.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Color(0xFFB2B2B2),
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 14),

                // Email
                const Row(
                  children: [
                    Icon(Icons.mail_outline,
                        size: 18, color: Color(0xFFB2B2B2)),
                    SizedBox(width: 10),
                    Text(
                      'anibal@gmail.com',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Color(0xFFB2B2B2),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20, color: Color(0xFFE0E0E0)),
                const Text(
                  'Para alterar o email, contacta o suporte.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Color(0xFFB2B2B2),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Botão Guardar ──────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _verde,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Guardar Alterações',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Cancelar
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}