import 'package:saude_app/paginas_portal_recepcao/portal_recepcao.dart';

class NovoPacientePage extends StatefulWidget {
  const NovoPacientePage({super.key});

  @override
  State<NovoPacientePage> createState() => _NovoPacientePageState();
}

class _NovoPacientePageState extends State<NovoPacientePage> {
  static const Color _azul = Color(0xFF6B9CE8);

  bool _isLoading = false;

  final _nomeCtrl      = TextEditingController();
  final _nifCtrl       = TextEditingController();
  final _dataNascCtrl  = TextEditingController();
  final _telemovelCtrl = TextEditingController();
  final _numUtenteCtrl = TextEditingController();
  final _moradaCtrl    = TextEditingController();
  final _emailCtrl     = TextEditingController();

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _nifCtrl.dispose();
    _dataNascCtrl.dispose();
    _telemovelCtrl.dispose();
    _numUtenteCtrl.dispose();
    _moradaCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  String? _validar() {
    if (_nomeCtrl.text.trim().isEmpty)   return 'O nome é obrigatório.';
    if (_emailCtrl.text.trim().isEmpty)  return 'O e-mail é obrigatório.';
    if (_nifCtrl.text.trim().isEmpty)    return 'O NIF é obrigatório.';
    if (_numUtenteCtrl.text.trim().isEmpty) return 'O número de utente é obrigatório.';
    return null;
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _criarPaciente() async {
    final erro = _validar();
    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newId = const Uuid().v4();
      final nomeStr     = _nomeCtrl.text.trim();
      final emailStr    = _emailCtrl.text.trim();
      final nifStr      = _nifCtrl.text.trim();
      final telStr      = _telemovelCtrl.text.trim();
      final moradaStr   = _moradaCtrl.text.trim();
      final utenteStr   = _numUtenteCtrl.text.trim();
      final dataNascStr = _dataNascCtrl.text.trim();

      // 1. Inserir em users (sem auth — o paciente ativa a conta por email)
      await db.from('users').insert({
        'id':            newId,
        'email':         emailStr,
        'name':          nomeStr,
        'role':          'patient',
        'nif':           nifStr.isEmpty     ? null : nifStr,
        'phone':         telStr.isEmpty     ? null : telStr,
        'address':       moradaStr.isEmpty  ? null : moradaStr,
        'date_of_birth': dataNascStr.isEmpty ? null : _parseDatePt(dataNascStr),
      });

      // 2. Inserir em patients
      await db.from('patients').insert({
        'user_id':       newId,
        'health_number': utenteStr,
      });

      // 3. Criar preferências por omissão
      await db.from('user_preferences').insert({
        'user_id':             newId,
        'email_notifications': false,
        'push_notifications':  false,
        'reminder_24h':        false,
        'appointment_alerts':  false,
      });

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paciente criado! Email de ativação enviado.'),
          backgroundColor: Color(0xFF27AE60),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GestaoPacientesPage()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar paciente: $e')),
      );
    }
  }

  /// Converte "DD/MM/AAAA" → "AAAA-MM-DD" para o Postgres.
  /// Devolve null se o formato não for reconhecido.
  String? _parseDatePt(String raw) {
    final parts = raw.split('/');
    if (parts.length == 3) {
      final d = parts[0].padLeft(2, '0');
      final m = parts[1].padLeft(2, '0');
      final y = parts[2];
      if (y.length == 4) return '$y-$m-$d';
    }
    return null;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return TemplatePortalRecepcao(
      currentIndex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const GestaoPacientesPage()),
            ),
            child: const Text(
              '< Voltar atrás',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _azul, fontFamily: 'Poppins'),
            ),
          ),
          const SizedBox(height: 4),

          const Text(
            'Novo Paciente',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 24),

          // Nome Completo
          _buildInputRow(icon: 'Person.svg',       hint: 'Nome Completo',  ctrl: _nomeCtrl),

          // NIF + Data Nascimento
          Row(
            children: [
              Expanded(child: _buildInputRow(icon: 'Nif.svg',            hint: 'NIF',          ctrl: _nifCtrl,      keyboardType: TextInputType.number)),
              const SizedBox(width: 20),
              Expanded(child: _buildInputRow(icon: 'Blue_Schedule.svg',  hint: 'DD/MM/AAAA',   ctrl: _dataNascCtrl, keyboardType: TextInputType.datetime)),
            ],
          ),

          // Telemóvel + Nº Utente
          Row(
            children: [
              Expanded(child: _buildInputRow(icon: 'Telemóvel.svg',      hint: 'Telemóvel',    ctrl: _telemovelCtrl, keyboardType: TextInputType.phone)),
              const SizedBox(width: 20),
              Expanded(child: _buildInputRow(icon: 'Cardinal.svg',       hint: 'Nº Utente',    ctrl: _numUtenteCtrl)),
            ],
          ),

          // Morada + E-mail
          _buildInputRow(icon: 'Casa.svg',  hint: 'Morada',  ctrl: _moradaCtrl),
          _buildInputRow(icon: 'Carta.svg', hint: 'E-mail',  ctrl: _emailCtrl, keyboardType: TextInputType.emailAddress),

          const SizedBox(height: 16),

          // Info banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFD6EDE7),
              borderRadius: BorderRadius.only(topRight: Radius.circular(6), bottomRight: Radius.circular(6)),
              border: Border(left: BorderSide(color: Color(0xFF38B29B), width: 4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/imagens_portal_recepcao/Info.svg',
                  width: 16, height: 16,
                  colorFilter: const ColorFilter.mode(Color(0xFF7A97A9), BlendMode.srcIn),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'O paciente receberá um email para ativar a conta.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF546E7A), fontFamily: 'Poppins'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Botão Criar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _criarPaciente,
              style: ElevatedButton.styleFrom(
                backgroundColor: _azul,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Criar Paciente',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Poppins'),
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Botão Cancelar
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _isLoading
                  ? null
                  : () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const GestaoPacientesPage()),
                      ),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _azul, fontFamily: 'Poppins'),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInputRow({
    required String icon,
    required String hint,
    required TextEditingController ctrl,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _azul, width: 1.5)),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/imagens_portal_recepcao/$icon',
            width: 18, height: 18,
            colorFilter: const ColorFilter.mode(_azul, BlendMode.srcIn),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF90A4AE)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}