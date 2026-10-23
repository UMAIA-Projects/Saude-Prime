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
  DateTime? _dataNascimento;
  final _telemovelCtrl = TextEditingController();
  final _numUtenteCtrl = TextEditingController();
  final _moradaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _nifCtrl.dispose();
    _telemovelCtrl.dispose();
    _numUtenteCtrl.dispose();
    _moradaCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  // Validation

  String? _validar() {
    if (_nomeCtrl.text.trim().isEmpty) return 'O nome é obrigatório.';
    if (_emailCtrl.text.trim().isEmpty) return 'O e-mail é obrigatório.';
    if (_nifCtrl.text.trim().isEmpty) return 'O NIF é obrigatório.';
    if (_numUtenteCtrl.text.trim().isEmpty) return 'O número de utente é obrigatório.';
    return null;
  }

  // Submit

  Future<void> _criarPaciente() async {
    final erro = _validar();
    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final emailStr    = _emailCtrl.text.trim();
      final nifStr      = _nifCtrl.text.trim();
      final utenteStr   = _numUtenteCtrl.text.trim();

      // 1. Validação Prévia de Duplicados (Evita criação parcial)
      
      // Verificar E-mail e NIF na tabela users
      final userCheck = await db
          .from('users')
          .select('id, email, nif')
          .or('email.eq.$emailStr,nif.eq.$nifStr')
          .maybeSingle();
      
      if (userCheck != null) {
        setState(() => _isLoading = false);
        if (userCheck['email'] == emailStr) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Este e-mail já está registado.')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Este NIF já está registado.')));
        }
        return;
      }

      // Verificar Número de Utente na tabela patients
      final patientCheck = await db
          .from('patients')
          .select('user_id')
          .eq('health_number', utenteStr)
          .maybeSingle();

      if (patientCheck != null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Este número de utente já está registado.')));
        return;
      }

      // 2. Processo de Inserção (Agora com segurança de que os dados são únicos)
      final newId = const Uuid().v4();
      final nomeStr     = _nomeCtrl.text.trim();
      final telStr      = _telemovelCtrl.text.trim();
      final moradaStr   = _moradaCtrl.text.trim();
      final dataNascStr = _dataNascimento != null
          ? '${_dataNascimento!.year}-${_dataNascimento!.month.toString().padLeft(2, '0')}-${_dataNascimento!.day.toString().padLeft(2, '0')}'
          : null;

      // 1. Inserir em users (sem auth - o paciente ativa a conta por email)
      await db.from('users').insert({
        'id':            newId,
        'email':         emailStr,
        'name':          nomeStr,
        'role':          'patient',
        'nif':           nifStr,
        'phone':         telStr.isEmpty     ? null : telStr,
        'address':       moradaStr.isEmpty  ? null : moradaStr,
        'date_of_birth': dataNascStr,
      });

      // 2. Inserir em patients
      await db.from('patients').insert({
        'user_id': newId,
        'health_number': utenteStr,
      });

      // 3. Criar preferências por omissão
      await db.from('user_preferences').insert({
        'user_id': newId,
        'email_notifications': false,
        'push_notifications': false,
        'reminder_24h': false,
        'appointment_alerts': false,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao criar paciente: $e')));
    }
  }

  // Build

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
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _azul,
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

          // Nome Completo
          _buildInputRow(
            icon: 'Person.svg',
            hint: 'Nome Completo',
            ctrl: _nomeCtrl,
          ),

          // NIF + Data Nascimento
          Row(
            children: [
              Expanded(child: _buildInputRow(icon: 'Nif.svg', hint: 'NIF', ctrl: _nifCtrl, keyboardType: TextInputType.number)),
              const SizedBox(width: 20),
              Expanded(
                child: _DatePickerField(
                  azul: _azul,
                  onDateChanged: (d) => setState(() => _dataNascimento = d),
                ),
              ),
            ],
          ),

          // Telemóvel + Nº Utente
          Row(
            children: [
              Expanded(
                child: _buildInputRow(
                  icon: 'Telemóvel.svg',
                  hint: 'Telemóvel',
                  ctrl: _telemovelCtrl,
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildInputRow(
                  icon: 'Cardinal.svg',
                  hint: 'Nº Utente',
                  ctrl: _numUtenteCtrl,
                ),
              ),
            ],
          ),

          // Morada + E-mail
          _buildInputRow(icon: 'Casa.svg', hint: 'Morada', ctrl: _moradaCtrl),
          _buildInputRow(
            icon: 'Carta.svg',
            hint: 'E-mail',
            ctrl: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 16),

          // Botão Criar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _criarPaciente,
              style: ElevatedButton.styleFrom(
                backgroundColor: _azul,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
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

          // Botão Cancelar
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _isLoading
                  ? null
                  : () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GestaoPacientesPage(),
                      ),
                    ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _azul,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
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
            width: 18,
            height: 18,
            colorFilter: const ColorFilter.mode(_azul, BlendMode.srcIn),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: keyboardType,
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

// Date Picker Field

class _DatePickerField extends StatefulWidget {
  final Color azul;
  final ValueChanged<DateTime?>? onDateChanged;
 
  const _DatePickerField({
    required this.azul,
    this.onDateChanged,
  });
 
  @override
  State<_DatePickerField> createState() => _DatePickerFieldState();
}
 
class _DatePickerFieldState extends State<_DatePickerField> {
  DateTime? _selectedDate;
 
  String get _label => _selectedDate == null
      ? 'Data Nasc.'
      : '${_selectedDate!.day.toString().padLeft(2, '0')}/'
        '${_selectedDate!.month.toString().padLeft(2, '0')}/'
        '${_selectedDate!.year}';
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime(1990, 1, 1),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
          widget.onDateChanged?.call(picked);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: widget.azul, width: 1.5)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(Icons.calendar_today_outlined, color: widget.azul, size: 18),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: _selectedDate == null ? Colors.grey.shade400 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
