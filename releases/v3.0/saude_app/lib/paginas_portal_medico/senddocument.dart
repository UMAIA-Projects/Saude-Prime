import 'package:saude_app/paginas_portal_medico/portal_medico.dart';

const _kBucket = 'patient-documents';

//  Tipos de documento
const _kTipos = <({String value, String label})>[
  (value: 'analysis', label: 'Resultado de Análise'),
  (value: 'prescription', label: 'Receita Médica'),
  (value: 'invoice', label: 'Fatura'),
  (value: 'other', label: 'Outro'),
];

//  Widget principal
class SendDocument extends StatefulWidget {
  final String patientId;
  final String nomePaciente;
  final String iniciais;

  // Opcional: associar a uma consulta específica
  final String? appointmentId;

  const SendDocument({
    super.key,
    required this.patientId,
    required this.nomePaciente,
    required this.iniciais,
    this.appointmentId,
  });

  @override
  State<SendDocument> createState() => _SendDocumentState();
}

class _SendDocumentState extends State<SendDocument> {
  // Formulário
  String _tipoSelecionado = _kTipos.first.value;
  final TextEditingController _nomeCtrl = TextEditingController();
  final TextEditingController _labCtrl = TextEditingController();
  DateTime? _dataDocumento;

  // Ficheiro
  PlatformFile? _ficheiro;

  // Estado
  bool _uploading = false;
  double _uploadProgress = 0;
  String? _error;

  static const List<String> _monthPt = [
    '',
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];

  @override
  void initState() {
    super.initState();
    _dataDocumento = DateTime.now();
    // Pré-preenche nome com data de hoje
    _nomeCtrl.text =
        'Documento ${DateTime.now().day} ${_monthPt[DateTime.now().month]} ${DateTime.now().year}';
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _labCtrl.dispose();
    super.dispose();
  }

  // Formatador de data
  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // Escolher ficheiro
  Future<void> _escolherFicheiro() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true, // necessário para mobile
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _ficheiro = result.files.first;
      _error = null;
      // Auto-preenche o nome com o nome do ficheiro (sem extensão)
      if (_nomeCtrl.text.startsWith('Documento')) {
        final semExt = (_ficheiro!.name.contains('.')
            ? _ficheiro!.name.substring(0, _ficheiro!.name.lastIndexOf('.'))
            : _ficheiro!.name);
        _nomeCtrl.text = semExt;
      }
    });
  }

  void _removerFicheiro() => setState(() => _ficheiro = null);

  // DatePicker
  Future<void> _pickData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataDocumento ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'PT'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF3DBDAD),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dataDocumento = picked);
  }

  // Validações
  bool get _podeEnviar =>
      _ficheiro != null && _nomeCtrl.text.trim().isNotEmpty && !_uploading;

  // Enviar para Supabase
  Future<void> _enviar() async {
    if (!_podeEnviar) {
      setState(
        () => _error = 'Seleciona um ficheiro e preenche o nome do documento.',
      );
      return;
    }

    final doctorId = db.auth.currentUser?.id;
    if (doctorId == null) {
      setState(() => _error = 'Sem sessão ativa.');
      return;
    }

    setState(() {
      _uploading = true;
      _uploadProgress = 0;
      _error = null;
    });

    try {
      final file = _ficheiro!;
      final ext = file.extension ?? 'pdf';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // Storage só aceita chaves ASCII simples (sem espaços nem acentos no nome)
      final safeFileName = _sanitizeStorageFileName(file.name);
      final storagePath = '${widget.patientId}/${timestamp}_$safeFileName';

      // 1. Upload para Supabase Storage
      setState(() => _uploadProgress = 0.3);

      Uint8List fileBytes;
      if (file.bytes != null) {
        // Web / pickFiles(withData: true)
        fileBytes = file.bytes!;
      } else if (file.path != null) {
        // Mobile / Desktop
        fileBytes = await File(file.path!).readAsBytes();
      } else {
        throw Exception('Não foi possível ler o ficheiro.');
      }

      await db.storage
          .from(_kBucket)
          .uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
              contentType: _mimeType(ext),
              upsert: false,
            ),
          );

      setState(() => _uploadProgress = 0.7);

      // 2. Inserir registo na tabela documents
      final docId = _novoIdDocumento();

      await db.from('documents').insert({
        'id': docId,
        'patient_id': widget.patientId,
        'doctor_id': doctorId,
        'appointment_id': widget.appointmentId,
        'type': _tipoSelecionado,
        'name': _nomeCtrl.text.trim(),
        'laboratory_name': _labCtrl.text.trim().isEmpty
            ? null
            : _labCtrl.text.trim(),
        'file_path': storagePath,
        'file_size_bytes': file.size,
        'uploaded_by': doctorId,
        // created_at é preenchido pelo default da DB,
        // mas guardamos a data do documento nos metadados do nome
        // (a tabela não tem campo date separado - a data do ficheiro é o created_at)
      });

      setState(() => _uploadProgress = 0.9);
      try {
        await db.functions.invoke(
          'notify-document',
          body: {
            'patient_id': widget.patientId,
            'doc_type': _tipoLabel,
            'doc_name': _nomeCtrl.text.trim(),
          },
        );
      } catch (e) {
        debugPrint('Aviso: Falha ao mandar o e-mail de notificação - $e');
      }
      setState(() => _uploadProgress = 1.0);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Documento enviado com sucesso!',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Color(0xFF3DBDAD),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true); // sinaliza sucesso ao ecrã anterior
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _error = 'Erro ao enviar: $e';
      });
    }
  }

  // Helpers
  /// Nome seguro para o path no Supabase Storage (evita InvalidKey).
  String _sanitizeStorageFileName(String original) {
    final base = original.split(RegExp(r'[/\\]')).last;
    final dot = base.lastIndexOf('.');
    var stem = dot > 0 ? base.substring(0, dot) : base;
    final ext = dot > 0 ? base.substring(dot).toLowerCase() : '.pdf';

    stem = _foldAccents(stem)
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    if (stem.isEmpty) stem = 'documento';
    return '$stem$ext';
  }

  String _foldAccents(String input) {
    const map = {
      'à': 'a',
      'á': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'è': 'e',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'ì': 'i',
      'í': 'i',
      'î': 'i',
      'ï': 'i',
      'ò': 'o',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ù': 'u',
      'ú': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
      'ñ': 'n',
      'À': 'A',
      'Á': 'A',
      'Â': 'A',
      'Ã': 'A',
      'Ä': 'A',
      'È': 'E',
      'É': 'E',
      'Ê': 'E',
      'Ë': 'E',
      'Ì': 'I',
      'Í': 'I',
      'Î': 'I',
      'Ï': 'I',
      'Ò': 'O',
      'Ó': 'O',
      'Ô': 'O',
      'Õ': 'O',
      'Ö': 'O',
      'Ù': 'U',
      'Ú': 'U',
      'Û': 'U',
      'Ü': 'U',
      'Ç': 'C',
      'Ñ': 'N',
    };
    final out = StringBuffer();
    for (final c in input.split('')) {
      out.write(map[c] ?? c);
    }
    return out.toString();
  }

  String _mimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  String _tamanhoFicheiro(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get _tipoLabel =>
      _kTipos.firstWhere((t) => t.value == _tipoSelecionado).label;

  @override
  Widget build(BuildContext context) {
    return TemplatePortalMedico(
      currentIndex: 3,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -- Voltar --------------------------------------------------
              GestureDetector(
                onTap: _uploading ? null : () => Navigator.pop(context),
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

              // -- Título ---------------------------------------------------
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

              // Paciente (só leitura) 
              _FormField(
                icon: Icons.person_outline,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD8F2EF),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.iniciais,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A6B62),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.nomePaciente,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),

              // Tipo (dropdown)
              _FormField(
                icon: Icons.folder_outlined,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _tipoSelecionado,
                    isExpanded: true,
                    isDense: true,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),
                    items: _kTipos
                        .map(
                          (t) => DropdownMenuItem(
                            value: t.value,
                            child: Text(
                              t.label,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _uploading
                        ? null
                        : (v) {
                            if (v != null) setState(() => _tipoSelecionado = v);
                          },
                  ),
                ),
              ),

              // Nome do documento
              _FormField(
                icon: Icons.drive_file_rename_outline,
                child: TextField(
                  controller: _nomeCtrl,
                  enabled: !_uploading,
                  style: const TextStyle(fontSize: 15, fontFamily: 'Poppins'),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'Nome do documento',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: Colors.black.withValues(alpha: 0.26),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),

              // Laboratório (opcional, só para análises)
              if (_tipoSelecionado == 'analysis')
                _FormField(
                  icon: Icons.science_outlined,
                  child: TextField(
                    controller: _labCtrl,
                    enabled: !_uploading,
                    style: const TextStyle(fontSize: 15, fontFamily: 'Poppins'),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Laboratório (opcional)',
                      hintStyle: TextStyle(
                        fontSize: 15,
                        color: Colors.black.withValues(alpha: 0.26),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),

              // Data do documento (DatePicker)
              GestureDetector(
                onTap: _uploading ? null : _pickData,
                child: _FormField(
                  icon: Icons.calendar_month_outlined,
                  child: Row(
                    children: [
                      Text(
                        _dataDocumento != null
                            ? _fmtDate(_dataDocumento!)
                            : 'Data do documento',
                        style: TextStyle(
                          fontSize: 15,
                          color: _dataDocumento != null
                              ? Colors.black
                              : Colors.black.withValues(alpha: 0.26),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.black.withValues(alpha: 0.20),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Zona de upload
              GestureDetector(
                onTap: _uploading ? null : _escolherFicheiro,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: _ficheiro != null
                        ? const Color(0xFFF0FDF9)
                        : const Color(0xFFEAF9F7),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: _ficheiro != null
                          ? const Color(0xFF3DBDAD)
                          : const Color(0xFF9FDFD7),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _ficheiro != null
                            ? Icons.check_circle_outline
                            : Icons.upload_file_outlined,
                        size: 48,
                        color: const Color(0xFF3DBDAD),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _ficheiro != null
                            ? 'Ficheiro selecionado'
                            : 'Toque para selecionar o ficheiro',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A8070),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'PDF, PNG, JPG - Máx. 10 MB',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFA8A8A8),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      if (_ficheiro == null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: const Color(0xFF66D1D8),
                              width: 2,
                            ),
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
                    ],
                  ),
                ),
              ),

              // Ficheiro selecionado
              if (_ficheiro != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
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
                      Icon(
                        _ficheiro!.extension?.toLowerCase() == 'pdf'
                            ? Icons.picture_as_pdf_outlined
                            : Icons.image_outlined,
                        size: 36,
                        color: const Color(0xFF3DBDAD),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _ficheiro!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_tamanhoFicheiro(_ficheiro!.size)} • Pronto',
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
                        onTap: _uploading ? null : _removerFicheiro,
                        child: const Icon(
                          Icons.close,
                          size: 22,
                          color: Color(0xFFCC3A44),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Barra de progresso (durante upload)
              if (_uploading) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: const Color(0xFFD8F2EF),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF3DBDAD)),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 8),
                Text(
                  'A enviar... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6A9890),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],

              // Erro
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFCDD2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFCC3A44),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFCC3A44),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Botão Enviar
              GestureDetector(
                onTap: _podeEnviar ? _enviar : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _podeEnviar
                        ? const Color(0xFF3DBDAD)
                        : const Color(0xFF3DBDAD).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: _podeEnviar
                        ? const [
                            BoxShadow(
                              color: Color(0x1F000000),
                              blurRadius: 20,
                              offset: Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.upload_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _uploading ? 'A enviar...' : 'Enviar Documento',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Pré-visualização do registo
              if (_ficheiro != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC5EDE8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF9FDFD7),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RESUMO DO ENVIO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A8070),
                          fontFamily: 'Poppins',
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _PreviewRow(
                        label: 'Paciente',
                        valor: widget.nomePaciente,
                      ),
                      _PreviewRow(label: 'Tipo', valor: _tipoLabel),
                      _PreviewRow(
                        label: 'Nome',
                        valor: _nomeCtrl.text.trim().isEmpty
                            ? '-'
                            : _nomeCtrl.text.trim(),
                      ),
                      if (_labCtrl.text.trim().isNotEmpty)
                        _PreviewRow(
                          label: 'Laboratório',
                          valor: _labCtrl.text.trim(),
                        ),
                      if (_dataDocumento != null)
                        _PreviewRow(
                          label: 'Data',
                          valor: _fmtDate(_dataDocumento!),
                        ),
                      _PreviewRow(label: 'Ficheiro', valor: _ficheiro!.name),
                      _PreviewRow(
                        label: 'Tamanho',
                        valor: _tamanhoFicheiro(_ficheiro!.size),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),

          // Overlay de loading
          if (_uploading)
            Positioned.fill(
              child: Container(color: Colors.white.withValues(alpha: 0.50)),
            ),
        ],
      ),
    );
  }
}

//  Widgets auxiliares
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

class _PreviewRow extends StatelessWidget {
  final String label, valor;
  const _PreviewRow({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A8070),
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ID único para novo registo em `documents` (coluna UUID no Postgres).
String _novoIdDocumento() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
      '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20, 32)}';
}
