import 'package:saude_app/paginas_portal_paciente/portal_paciente.dart';

class _Documento {
  final String id;
  final String titulo;
  final String subtitulo;
  final String categoria;   // label PT para o filtro
  final String filePath;    // caminho no Storage
  final int    fileSizeBytes;

  const _Documento({
    required this.id,
    required this.titulo,
    required this.subtitulo,
    required this.categoria,
    required this.filePath,
    required this.fileSizeBytes,
  });

  String get tamanhoLabel {
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// SUPABASE SERVICE

class _DocumentosService {
  static final _sb     = Supabase.instance.client;
  static String get _userId => _sb.auth.currentUser!.id;

  // Mapeamento document_type (BD) → label PT (filtro)
  static const _tipoLabel = {
    'analysis':    'Análises',
    'invoice':     'Faturas',
    'prescription':'Prescrições',
    'other':       'Outros',
  };

  static Future<List<_Documento>> fetchDocumentos() async {
    final rows = await _sb
        .from('documents')
        .select('''
          id,
          name,
          type,
          file_path,
          file_size_bytes,
          created_at,
          laboratory_name,
          doctors(users(name))
        ''')
        .eq('patient_id', _userId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);

    return rows.map((r) {
      final tipo       = r['type'] as String;
      final categoria  = _tipoLabel[tipo] ?? 'Outros';
      final date       = DateTime.parse(r['created_at'] as String).toLocal();
      final months     = ['Jan','Fev','Mar','Abr','Mai','Jun',
                          'Jul','Ago','Set','Out','Nov','Dez'];
      final dataFmt    = '${date.day} ${months[date.month - 1]} ${date.year}';

      // Linha de subtítulo: fonte (médico ou laboratório) + data + tamanho
      final sizeBytes  = r['file_size_bytes'] as int;
      final sizeLabel  = sizeBytes < 1024 * 1024
          ? '${(sizeBytes / 1024).toStringAsFixed(1)} KB'
          : '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';

      String fonte = '';
      final doctorData = r['doctors'];
      if (doctorData != null && doctorData['users'] != null) {
        fonte = doctorData['users']['name'] as String;
      } else if (r['laboratory_name'] != null) {
        fonte = r['laboratory_name'] as String;
      }

      final subtitulo = [fonte, dataFmt, sizeLabel]
          .where((s) => s.isNotEmpty)
          .join(' · ');

      return _Documento(
        id:            r['id'] as String,
        titulo:        r['name'] as String,
        subtitulo:     subtitulo,
        categoria:     categoria,
        filePath:      r['file_path'] as String,
        fileSizeBytes: sizeBytes,
      );
    }).toList();
  }

  /// Gera URL assinada (1 hora) para download/visualização
  static Future<String> getDownloadUrl(String filePath) async {
    final response = await _sb.storage
        .from('documents')
        .createSignedUrl(filePath, 3600);
    return response;
  }
}

// SCREEN

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  static const Color _verde = Color(0xFF1A8070);

  int    _filtroIndex = 0;
  String _pesquisa    = '';

  final List<String> _filtros = ['Todos', 'Faturas', 'Análises', 'Prescrições', 'Outros'];

  late Future<List<_Documento>> _futureDocumentos;

  @override
  void initState() {
    super.initState();
    _futureDocumentos = _DocumentosService.fetchDocumentos();
  }

  List<_Documento> _aplicarFiltros(List<_Documento> todos) {
    return todos.where((doc) {
      final categoriaOk = _filtroIndex == 0 ||
          doc.categoria == _filtros[_filtroIndex];
      final pesquisaOk = _pesquisa.isEmpty ||
          doc.titulo.toLowerCase().contains(_pesquisa.toLowerCase());
      return categoriaOk && pesquisaOk;
    }).toList();
  }

  Future<void> _downloadDocumento(_Documento doc) async {
    try {
      final url = await _DocumentosService.getDownloadUrl(doc.filePath);
      // Abre a URL assinada — o browser/WebView trata do download
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A abrir ${doc.titulo}…',
              style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: _verde,
          duration: const Duration(seconds: 2),
        ),
      );
      // Para abrir o URL usa url_launcher no projeto:
      // await launchUrl(Uri.parse(url));
      debugPrint('Signed URL: $url');
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao gerar link de download.',
              style: TextStyle(fontFamily: 'Poppins')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePortalPaciente(
      currentIndex: 3,
      child: FutureBuilder<List<_Documento>>(
        future: _futureDocumentos,
        builder: (context, snapshot) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 48,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: _verde.withValues(alpha: 0.5), width: 1.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: _verde, size: 22),
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

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_filtros.length, (i) {
                    final ativo = i == _filtroIndex;
                    return Padding(
                      padding: EdgeInsets.only(
                          right: i < _filtros.length - 1 ? 8 : 0),
                      child: GestureDetector(
                        onTap: () => setState(() => _filtroIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                ativo ? _verde : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: ativo
                                  ? _verde
                                  : const Color(0xFFB2DFDB),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            _filtros[i],
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: ativo
                                  ? Colors.white
                                  : const Color(0xFF555555),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 20),

              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(color: _verde),
                  ),
                )
              else if (snapshot.hasError)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            color: Color(0xFF9E9E9E), size: 36),
                        const SizedBox(height: 12),
                        const Text(
                          'Erro ao carregar documentos.\nVerifica a tua ligação.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => setState(() {
                            _futureDocumentos =
                                _DocumentosService.fetchDocumentos();
                          }),
                          child: const Text('Tentar novamente',
                              style: TextStyle(
                                  fontFamily: 'Poppins', color: _verde)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                _ListaDocumentos(
                  docs: _aplicarFiltros(snapshot.data!),
                  onDownload: _downloadDocumento,
                ),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

// LISTA

class _ListaDocumentos extends StatelessWidget {
  final List<_Documento> docs;
  final Future<void> Function(_Documento) onDownload;

  const _ListaDocumentos({required this.docs, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) {
      return const Padding(
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
      );
    }

    return Column(
      children: [
        for (int i = 0; i < docs.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _DocumentCard(doc: docs[i], onDownload: onDownload),
        ],
      ],
    );
  }
}

// CARD

class _DocumentCard extends StatefulWidget {
  final _Documento doc;
  final Future<void> Function(_Documento) onDownload;

  const _DocumentCard({required this.doc, required this.onDownload});

  @override
  State<_DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends State<_DocumentCard> {
  bool _loading = false;

  // Ícone conforme categoria
  IconData get _icone {
    switch (widget.doc.categoria) {
      case 'Análises':
        return Icons.biotech_outlined;
      case 'Faturas':
        return Icons.receipt_long_outlined;
      case 'Prescrições':
        return Icons.medication_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          // Avatar circular com ícone da categoria
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFF80CBC4),
              shape: BoxShape.circle,
            ),
            child: Icon(_icone, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doc.titulo,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A8070),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.doc.subtitulo,
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
          // Botão download com estado de loading
          GestureDetector(
            onTap: _loading
                ? null
                : () async {
                    setState(() => _loading = true);
                    await widget.onDownload(widget.doc);
                    if (mounted) setState(() => _loading = false);
                  },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF80CBC4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.download_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
