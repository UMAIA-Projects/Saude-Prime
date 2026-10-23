import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'template/template_portal_recepcao.dart';
import 'gestao_pacientes_page.dart';

class NovoPacientePage extends StatelessWidget {
  const NovoPacientePage({super.key});

  @override
  Widget build(BuildContext context) {
    return TemplatePortalRecepcao(
      currentIndex: 2,
      userInitials: 'MC',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const GestaoPacientesPage(),
                ),
              );
            },
            child: const Text(
              '< Voltar atrás',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B9CE8),
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(height: 4),

          const Text(
            'Novo Paciente',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 24),
          _buildInputRow(icon: 'Person.svg', hint: 'Nome Completo'),

          Row(
            children: [
              Expanded(
                child: _buildInputRow(icon: 'Nif.svg', hint: 'NIF'),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildInputRow(
                  icon: 'Blue_Schedule.svg',
                  hint: 'Data Nasc.',
                ),
              ),
            ],
          ),

          Row(
            children: [
              Expanded(
                child: _buildInputRow(icon: 'Telemóvel.svg', hint: 'Telemóvel'),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildInputRow(icon: 'Cardinal.svg', hint: 'Nº Utente'),
              ),
            ],
          ),

          _buildInputRow(icon: 'Casa.svg', hint: 'Morada'),
          _buildInputRow(icon: 'Carta.svg', hint: 'E-mail'),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFD6EDE7),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(6),
                bottomRight: Radius.circular(6),
              ),
              border: const Border(
                left: BorderSide(color: Color(0xFF38B29B), width: 4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/imagens_portal_recepcao/Info.svg',
                  width: 16,
                  height: 16,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF7A97A9),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'O paciente receberá um email para ativar a conta.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF546E7A),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                /* TODO: criar paciente */
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B9CE8),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Criar Paciente',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GestaoPacientesPage(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B9CE8),
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInputRow({required String icon, required String hint}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF6B9CE8), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/imagens_portal_recepcao/$icon',
            width: 18,
            height: 18,
            colorFilter: const ColorFilter.mode(
              Color(0xFF6B9CE8),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Color(0xFF90A4AE),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
