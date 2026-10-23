import 'package:flutter/material.dart';
import 'template/template_portal_recepcao.dart';

class FilaVirtualPage extends StatelessWidget {
  const FilaVirtualPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TemplatePortalRecepcao(
      currentIndex: 3,
      userInitials: 'MC',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fila Virtual',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  /* TODO: emitir senha */
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B9CE8),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Emitir',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFDFEDFA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF4A78D6), width: 0.8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'A ser atendido',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7A97A9),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'A-43',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3B8B),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      'Em espera',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7A97A9),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '6',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3B8B),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      'Próxima',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7A97A9),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'A-44',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3B8B),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Fila Completa',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5BA2E0),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),
          _buildFilaItem(
            pos: '1',
            senha: 'A-43',
            nome: 'Maria Santos',
            hora: '09:47',
          ),
          _buildFilaItem(
            pos: '2',
            senha: 'A-44',
            nome: 'João Oliveira',
            hora: '10:02',
          ),
          _buildFilaItem(
            pos: '3',
            senha: 'A-45',
            nome: 'Rui Figueiredo',
            hora: '10:15',
          ),
          _buildFilaItem(
            pos: '4',
            senha: 'A-46',
            nome: 'Ana Lima',
            hora: '10:23',
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildFilaItem({
    required String pos,
    required String senha,
    required String nome,
    required String hora,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white, width: 1.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              pos,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFB0BEC5),
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Container(
            width: 48,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFB8D4FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              senha,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3B8B),
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              nome,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              hora,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black45,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          // Ações (Chamar / Ausente)
          GestureDetector(
            onTap: () {
              /* TODO: chamar senha, por fazer ainda*/
            },
            child: const Text(
              'Chamar',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4BA3E3),
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              /* TODO: marcar ausente */
            },
            child: const Text(
              'Ausente',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD32F2F),
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
