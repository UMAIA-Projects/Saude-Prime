import 'package:flutter/material.dart';
import 'template/template_portal_paciente.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  static const Color _verde = Color(0xFF1A8070);

  int _filtroIndex = 0; // 0=Todos, 1=Faturas, 2=Análises, 3=Prescrições
  String _pesquisa = '';

  final List<String> _filtros = ['Todos', 'Faturas', 'Análises', 'Prescrições'];

  final List<Map<String, dynamic>> _documentos = [
    {
      'titulo': 'Análise de sangue - Mar 2025',
      'subtitulo': 'Dr. Gerundio - 15 Mar - 1.2 MB',
      'categoria': 'Análises',
    },
    {
      'titulo': 'Fatura - Consulta 15 Mar',
      'subtitulo': 'Clínica - 15 Mar - 0.4 MB',
      'categoria': 'Faturas',
    },
    {
      'titulo': 'Prescrição - Benurom',
      'subtitulo': 'Dra Paula Rego - 2 Fev - 1.3 MB',
      'categoria': 'Prescrições',
    },
    {
      'titulo': 'Análise cabeça - Jan 2025',
      'subtitulo': 'Lab. Ceentral - 12 Jan - 10.9 MB',
      'categoria': 'Análises',
    },
  ];

  List<Map<String, dynamic>> get _documentosFiltrados {
    return _documentos.where((doc) {
      final categoria = _filtroIndex == 0 ||
          doc['categoria'] == _filtros[_filtroIndex];
      final pesquisa = _pesquisa.isEmpty ||
          (doc['titulo'] as String)
              .toLowerCase()
              .contains(_pesquisa.toLowerCase());
      return categoria && pesquisa;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final docs = _documentosFiltrados;

    return TemplatePortalPaciente(
      currentIndex: 3, // documents
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de pesquisa
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border(
                bottom: BorderSide(color: _verde.withValues(alpha: 0.5), width: 1.5),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: _verde, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _pesquisa = v),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Pesquisar documentos...',
                      hintStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Color(0xFF9E9E9E),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    cursorColor: _verde,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Chips de filtro
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_filtros.length, (i) {
                final ativo = i == _filtroIndex;
                return Padding(
                  padding: EdgeInsets.only(right: i < _filtros.length - 1 ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => setState(() => _filtroIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: ativo ? _verde : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: ativo ? _verde : const Color(0xFFB2DFDB),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        _filtros[i],
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ativo ? Colors.white : const Color(0xFF555555),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 20),

          // Lista de documentos
          if (docs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Nenhum documento encontrado.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final doc = docs[i];
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar circular
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: Color(0xFF80CBC4),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Texto
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc['titulo'] as String,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A8070),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              doc['subtitulo'] as String,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Color(0xFF777777),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Botão download
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF80CBC4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.download_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}