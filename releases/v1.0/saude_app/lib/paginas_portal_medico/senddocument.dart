import 'package:flutter/material.dart';
import 'package:saude_app/paginas_portal_medico/template/template_portal_medico.dart';
import 'package:saude_app/paginas_portal_medico/dashboard.dart';
import 'package:saude_app/paginas_portal_medico/schedule.dart';
import 'package:saude_app/paginas_portal_medico/virtualqueue.dart';
import 'package:saude_app/paginas_portal_medico/search.dart';
import 'package:saude_app/paginas_portal_medico/profile.dart';

class SendDocument extends StatefulWidget {
  final String nomePaciente;
  final String iniciais;

  const SendDocument({
    super.key,
    required this.nomePaciente,
    required this.iniciais,
  });

  @override
  State<SendDocument> createState() => _SendDocumentState();
}

class _SendDocumentState extends State<SendDocument> {
  final TextEditingController _tipoController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();

  // Simula ficheiro selecionado
  Map<String, String>? _ficheiro;

  void _escolherFicheiro() {
    // TODO: integrar file_picker
    setState(() {
      _ficheiro = {
        'nome': 'analise_sangue_mar25.pdf',
        'tamanho': '1.2 MB',
        'estado': 'Pronto',
      };
    });
  }

  void _removerFicheiro() {
    setState(() => _ficheiro = null);
  }

  @override
  void dispose() {
    _tipoController.dispose();
    _descricaoController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePortalMedico(
      userInitials: 'CS',
      currentIndex: 3,
      onNavTap: (index) {
        if (index == 0) {Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const DashboardMedico()), (r) => false);}
        if (index == 1) {Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const Schedule()), (r) => false);}
        if (index == 2) {Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const VirtualQueue()), (r) => false);}    
        if (index == 3) {Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const Search()), (r) => false);}
        if (index == 4) {Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const Profile()), (r) => false);}
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Voltar atrás ──────────────────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text(
              '< Voltar atrás',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF50C4A5),
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF50C4A5),
                fontFamily: 'Poppins',
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Título ────────────────────────────────────────────────────────
          const Text(
            'Enviar Documento',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              fontFamily: 'Poppins',
            ),
          ),

          const SizedBox(height: 20),

          // ── Campos do formulário ──────────────────────────────────────────
          _FormField(
            icon: Icons.person_outline,
            child: Text(
              widget.nomePaciente,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black,
                fontFamily: 'Poppins',
              ),
            ),
          ),

          _FormField(
            icon: Icons.drive_file_rename_outline,
            child: TextField(
              controller: _tipoController,
              style: const TextStyle(fontSize: 15, fontFamily: 'Poppins'),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Tipo: Resultado de Análise',
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: Colors.black.withValues(alpha: 0.26),
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),

          _FormField(
            icon: Icons.subject_outlined,
            child: TextField(
              controller: _descricaoController,
              style: const TextStyle(fontSize: 15, fontFamily: 'Poppins'),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Análise de sangue - Mar 2025',
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: Colors.black.withValues(alpha: 0.26),
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),

          _FormField(
            icon: Icons.calendar_month_outlined,
            child: TextField(
              controller: _dataController,
              style: const TextStyle(fontSize: 15, fontFamily: 'Poppins'),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Data: 28/03/2025',
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: Colors.black.withValues(alpha: 0.26),
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Zona de upload ────────────────────────────────────────────────
          GestureDetector(
            onTap: _escolherFicheiro,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF9F7),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: const Color(0xFF9FDFD7),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  // Ícone upload
                  const Icon(
                    Icons.upload_file_outlined,
                    size: 48,
                    color: Color(0xFF3DBDAD),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Toque para selecionar o PDF',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A8070),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Formato PDF - Máx. 10 MB',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFFA8A8A8),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Botão escolher ficheiro
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                          color: const Color(0xFF66D1D8), width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x3F000000),
                          blurRadius: 33,
                          offset: Offset(0, 3),
                          spreadRadius: -17,
                        ),
                      ],
                    ),
                    child: const Text(
                      'Escolher ficheiro',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF66D1D8),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Ficheiro selecionado ──────────────────────────────────────────
          if (_ficheiro != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3F000000),
                    blurRadius: 33,
                    offset: Offset(0, 3),
                    spreadRadius: -17,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.copy_outlined,
                      size: 36, color: Color(0xFF3DBDAD)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _ficheiro!['nome']!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_ficheiro!['tamanho']} • ${_ficheiro!['estado']}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFA8A8A8),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _removerFicheiro,
                    child: const Icon(Icons.close,
                        size: 22, color: Color(0xFFCC3A44)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget auxiliar — linha de formulário
// ─────────────────────────────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  final IconData icon;
  final Widget child;

  const _FormField({required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: const Color(0xFF3DBDAD)),
              const SizedBox(width: 14),
              Expanded(child: child),
            ],
          ),
        ),
        Divider(
          color: const Color(0xFF3DBDAD).withValues(alpha: 0.40),
          height: 1,
        ),
      ],
    );
  }
}