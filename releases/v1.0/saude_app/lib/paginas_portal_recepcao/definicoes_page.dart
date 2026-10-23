import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'template/template_portal_recepcao.dart';

class DefinicoesPage extends StatefulWidget {
  const DefinicoesPage({super.key});

  @override
  State<DefinicoesPage> createState() => _DefinicoesPageState();
}

class _DefinicoesPageState extends State<DefinicoesPage> {
  bool _notificacoesMarcacao = true;
  bool _alertasFila = true;

  @override
  Widget build(BuildContext context) {
    return TemplatePortalRecepcao(
      currentIndex: 4,
      userInitials: 'MC',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Container(
              width: 86,
              height: 86,
              decoration: const BoxDecoration(
                color: Color(0xFF6B9CE8),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text(
                'MC',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Mariana Costa',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'mariana@saudeprime.pt',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF7A97A9),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE0DDF8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Rececionista',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7B66FF),
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: editar perfil
              },
              icon: SvgPicture.asset(
                'assets/imagens_portal_recepcao/Edit.svg',
                width: 16,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF42BCA3),
                  BlendMode.srcIn,
                ),
              ),
              label: const Text(
                'Editar Perfil',
                style: TextStyle(
                  color: Color(0xFF42BCA3),
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF42BCA3), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Dados Pessoais',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B9CE8),
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildCardBox(
            child: Column(
              children: [
                _buildDadoItem('Telemóvel', '920 000 000'),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Color(0xFFEEEEEE),
                  ),
                ),
                _buildDadoItem('Morada', 'Av. República, 12, Porto'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildCardBox(
            child: Column(
              children: [
                _buildSwitchItem(
                  'Notificações de Marcação',
                  _notificacoesMarcacao,
                  (val) => setState(() => _notificacoesMarcacao = val),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Color(0xFFEEEEEE),
                  ),
                ),
                _buildSwitchItem(
                  'Alertas de Fila',
                  _alertasFila,
                  (val) => setState(() => _alertasFila = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildCardBox(
            child: InkWell(
              onTap: () {
                // TODO: alterar password
              },
              borderRadius: BorderRadius.circular(15),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/imagens_portal_recepcao/Lock.svg',
                      width: 18,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFFF2A649),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Alterar Palavra-Passe',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.black38,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: terminar sessão
              },
              icon: SvgPicture.asset(
                'assets/imagens_portal_recepcao/Door.svg',
                width: 18,
                colorFilter: const ColorFilter.mode(
                  Color(0xFFD32F2F),
                  BlendMode.srcIn,
                ),
              ),
              label: const Text(
                'Terminar Sessão',
                style: TextStyle(
                  color: Color(0xFFD32F2F),
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFEBEE),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '© 2026 Saúde Prime ++ · v1.0.0',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF90A4AE),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCardBox({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: child,
    );
  }

  Widget _buildDadoItem(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF80CBC4),
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchItem(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF42BCA3),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}
