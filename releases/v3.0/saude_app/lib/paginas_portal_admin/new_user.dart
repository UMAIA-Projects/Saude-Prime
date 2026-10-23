import 'package:saude_app/paginas_portal_admin/portal_admin.dart';

class NewUserPage extends StatefulWidget {
  const NewUserPage({super.key});

  @override
  State<NewUserPage> createState() => _NewUserPageState();
}

class _NewUserPageState extends State<NewUserPage> {
  static const Color _rosa      = Color(0xFFB9124A);
  static const Color _rosaClaro = Color(0xFFD4537E);

  // Form Controllers
  late TextEditingController _nomeController;
  late TextEditingController _nifController;
  late TextEditingController _phoneController;
  late TextEditingController _healthNumberController;
  late TextEditingController _moradaController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  // State Variables
  String?  _tipoSelecionado;
  final List<String> _tipos = ['Paciente', 'Rececionista', 'Médico', 'Admin'];
  bool     _isLoading       = false;
  String?  _errorMessage;
  DateTime? _dataNascimento;
  bool     _passwordVisible = false;
  int?     _especialidadeSelecionada;

  // Especialidades dinâmicas
  List<Map<String, dynamic>> _especialidades = [];
  bool _loadingEspecialidades = false;


  @override
  void initState() {
    super.initState();
    _nomeController        = TextEditingController();
    _nifController         = TextEditingController();
    _phoneController       = TextEditingController();
    _healthNumberController = TextEditingController();
    _moradaController      = TextEditingController();
    _emailController       = TextEditingController();
    _passwordController    = TextEditingController();
    _carregarEspecialidades();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _nifController.dispose();
    _phoneController.dispose();
    _healthNumberController.dispose();
    _moradaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _carregarEspecialidades() async {
    setState(() => _loadingEspecialidades = true);
    try {
      final res = await db.from('specialties').select('id, name').order('name');
      setState(() {
        _especialidades = List<Map<String, dynamic>>.from(res);
        _loadingEspecialidades = false;
      });
    } catch (e) {
      setState(() => _loadingEspecialidades = false);
    }
  }

  InputDecoration _inputDecoration(IconData icon, String hint,
      {double leftPadding = 4, double iconSize = 18}) {
    return InputDecoration(
      prefixIcon: Padding(
        padding: EdgeInsets.only(left: leftPadding, right: 8),
        child: Icon(icon, color: _rosaClaro, size: iconSize),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 0),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontFamily: 'Poppins'),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFD4537E), width: 1.2),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFB9124A), width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      isDense: true,
    );
  }

  String _normalizarIdentificador(String valor) =>
      valor.replaceAll(RegExp(r'\s+'), '');

  String _mensagemConflitoDuplicado(String campo) {
    switch (campo) {
      case 'email':
        return 'Este e-mail já está registado no sistema.';
      case 'nif':
        return 'Este NIF já está registado no sistema.';
      case 'health_number':
        return 'Este número de utente já está registado.';
      default:
        return 'Já existe um utilizador com estes dados.';
    }
  }

  Future<void> _verificarDuplicadosLocal({
    required String email,
    required String nif,
    String? healthNumber,
  }) async {
    final emails = await db
        .from('users')
        .select('id')
        .ilike('email', email)
        .isFilter('deleted_at', null);
    if ((emails as List).isNotEmpty) {
      throw AuthException(_mensagemConflitoDuplicado('email'));
    }

    final nifs = await db
        .from('users')
        .select('id')
        .eq('nif', nif)
        .isFilter('deleted_at', null);
    if ((nifs as List).isNotEmpty) {
      throw AuthException(_mensagemConflitoDuplicado('nif'));
    }

    if (healthNumber != null && healthNumber.isNotEmpty) {
      final utentes = await db
          .from('patients')
          .select('user_id')
          .eq('health_number', healthNumber);
      if ((utentes as List).isNotEmpty) {
        throw AuthException(_mensagemConflitoDuplicado('health_number'));
      }
    }
  }

  Future<void> _verificarDuplicados({
    required String email,
    required String nif,
    String? healthNumber,
  }) async {
    final nifNorm = _normalizarIdentificador(nif);
    final healthNorm = healthNumber != null && healthNumber.isNotEmpty
        ? _normalizarIdentificador(healthNumber)
        : null;

    try {
      final conflict = await db.rpc(
        'check_new_user_duplicates',
        params: {
          'p_email':         email.trim().toLowerCase(),
          'p_nif':             nifNorm,
          'p_health_number': healthNorm,
        },
      );

      if (conflict is String && conflict.isNotEmpty) {
        throw AuthException(_mensagemConflitoDuplicado(conflict));
      }
    } on PostgrestException catch (e) {
      final fnEmFalta = e.code == 'PGRST202' ||
          e.message.contains('check_new_user_duplicates');
      if (!fnEmFalta) rethrow;

      await _verificarDuplicadosLocal(
        email: email,
        nif: nifNorm,
        healthNumber: healthNorm,
      );
    }
  }

  Future<void> _restaurarSessaoAdmin({
    required String adminUserId,
    required String refreshToken,
    required String accessToken,
  }) async {
    await db.auth.setSession(refreshToken, accessToken: accessToken);
    if (db.auth.currentUser?.id != adminUserId) {
      throw const AuthException(
        'Não foi possível restaurar a sessão de administrador.',
      );
    }
  }

  String _mensagemErroBaseDados(PostgrestException e) {
    if (e.code == '23505') {
      return 'Dados duplicados: e-mail, NIF ou número de utente já existem.';
    }
    if (e.code == '42501') {
      return 'Sem permissão para criar utilizador. Inicie sessão novamente como admin.';
    }
    return 'Erro na base de dados: ${e.message}';
  }

  bool _validarFormulario() {
    if (_nomeController.text.isEmpty) {
      setState(() => _errorMessage = 'Nome é obrigatório');
      return false;
    }
    if (_emailController.text.isEmpty) {
      setState(() => _errorMessage = 'E-mail é obrigatório');
      return false;
    }
    if (!_emailController.text.contains('@')) {
      setState(() => _errorMessage = 'E-mail inválido');
      return false;
    }
    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Palavra-passe é obrigatória');
      return false;
    }
    if (_passwordController.text.length < 6) {
      setState(() => _errorMessage = 'Palavra-passe deve ter pelo menos 6 caracteres');
      return false;
    }
    if (_tipoSelecionado == null) {
      setState(() => _errorMessage = 'Selecione um tipo de utilizador');
      return false;
    }
    if (_nifController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'NIF é obrigatório');
      return false;
    }
    if (_tipoSelecionado != 'Paciente' &&
        _healthNumberController.text.trim().isNotEmpty) {
      setState(() => _errorMessage =
          'Número de utente só se aplica a pacientes - deixe o campo vazio.');
      return false;
    }
    if (_tipoSelecionado == 'Paciente' && _healthNumberController.text.isEmpty) {
      setState(() => _errorMessage = 'Número de utente é obrigatório para pacientes');
      return false;
    }
    if (_tipoSelecionado == 'Médico' && _especialidadeSelecionada == null) {
      setState(() => _errorMessage = 'Selecione uma especialidade para médicos');
      return false;
    }
    setState(() => _errorMessage = null);
    return true;
  }

  Future<void> _criarUtilizador() async {
    if (!_validarFormulario()) return;

    final adminSession = db.auth.currentSession;
    if (adminSession == null) {
      setState(() => _errorMessage = 'Sessão expirada. Inicie sessão novamente.');
      return;
    }

    final adminUserId = adminSession.user.id;
    final adminRefreshToken = adminSession.refreshToken;
    if (adminRefreshToken == null || adminRefreshToken.isEmpty) {
      setState(() => _errorMessage = 'Sessão inválida. Inicie sessão novamente.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final roleMap = {
        'Paciente':     'patient',
        'Rececionista': 'receptionist',
        'Médico':       'doctor',
        'Admin':        'admin',
      };
      final role = roleMap[_tipoSelecionado]!;
      final email = _emailController.text.trim().toLowerCase();
      final nif = _normalizarIdentificador(_nifController.text);
      final healthNumber = _normalizarIdentificador(_healthNumberController.text);

      // 1. Validar duplicados ANTES de qualquer criação
      await _verificarDuplicados(
        email: email,
        nif: nif,
        healthNumber: role == 'patient' ? healthNumber : null,
      );

      // 2. Criar conta no Auth (Supabase faz login automático)
      final AuthResponse res = await db.auth.signUp(
        email:    email,
        password: _passwordController.text.trim(),
        data: {
          'name': _nomeController.text.trim(),
          'role': role,
        },
      );

      final user = res.user;
      final identities = user?.identities ?? [];
      if (user == null || identities.isEmpty) {
        // Se falhar o signUp, restauramos a sessão do admin antes de lançar erro
        await _restaurarSessaoAdmin(
          adminUserId: adminUserId,
          refreshToken: adminRefreshToken,
          accessToken: adminSession.accessToken,
        );
        throw const AuthException('Este e-mail já está registado no sistema.');
      }

      final userId = user.id;

      // 3. Restaurar IMEDIATAMENTE a sessão do admin
      await _restaurarSessaoAdmin(
        adminUserId: adminUserId,
        refreshToken: adminRefreshToken,
        accessToken: adminSession.accessToken,
      );

      // 4. Upsert na tabela public.users com TODOS os dados
      // Nota: O trigger handle_new_user já inseriu os dados básicos, por isso usamos upsert
      await db.from('users').upsert({
        'id':            userId,
        'email':         email,
        'name':          _nomeController.text.trim(),
        'nif':           nif,
        'date_of_birth': _dataNascimento?.toIso8601String().split('T')[0],
        'phone':         _phoneController.text.isEmpty ? null : _phoneController.text.trim(),
        'address':       _moradaController.text.isEmpty ? null : _moradaController.text.trim(),
        'role':          role,
        // Mantemos o created_at original se existir, ou usamos agora
      });

      // 5. Inserir dados específicos conforme o role
      if (role == 'patient') {
        await db.from('patients').insert({
          'user_id':       userId,
          'health_number': healthNumber,
          'insurance_id':  null,
        });
      } else if (role == 'doctor') {
        await db.from('doctors').insert({
          'user_id':                   userId,
          'specialty_id':              _especialidadeSelecionada,
          'license_number':            'OM-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
          'default_slot_duration_min': 30,
        });
      }

      // 6. Criar preferências de utilizador
      await db.from('user_preferences').insert({
        'user_id':             userId,
        'email_notifications': true,
        'push_notifications':  true,
        'reminder_24h':        true,
        'appointment_alerts':  true,
      });
      

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Utilizador criado com sucesso!'),
          backgroundColor: Color(0xFFB9124A),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UsersListPage()),
      );
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
        );
      }
    } on PostgrestException catch (e) {
      setState(() => _errorMessage = _mensagemErroBaseDados(e));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erro ao criar utilizador: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (db.auth.currentUser?.id != adminUserId) {
        try {
          await _restaurarSessaoAdmin(
            adminUserId: adminUserId,
            refreshToken: adminRefreshToken,
            accessToken: adminSession.accessToken,
          );
        } catch (_) {}
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmarCancelar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 45),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        title: const Text('Cancelar criação?',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        content: const Text(
          'Tem a certeza que deseja cancelar?\nOs dados introduzidos serão perdidos.',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black54, height: 1.3),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 17, 20, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD4537E)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  child: const Text('Não',
                      style: TextStyle(fontFamily: 'Poppins', color: Color(0xFFD4537E),
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB9124A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  child: const Text('Sim',
                      style: TextStyle(fontFamily: 'Poppins', color: Colors.white,
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const UsersListPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePortalAdmin(
      currentIndex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Novo Utilizador',
            style: TextStyle(
              fontFamily: 'Poppins', fontSize: 24,
              fontWeight: FontWeight.w900, color: Colors.black,
            ),
          ),
          Container(
            width: 60, height: 3,
            margin: const EdgeInsets.only(top: 4, bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFD4537E), borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Nome Completo
          TextField(
            controller: _nomeController,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
            decoration: _inputDecoration(Icons.person_outline, 'Nome Completo'),
            cursorColor: _rosa,
          ),
          const SizedBox(height: 16),

          // NIF + Data Nasc
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _nifController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                  decoration: _inputDecoration(Icons.credit_card_outlined, 'NIF'),
                  cursorColor: _rosa,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DatePickerField(
                  rosa: _rosaClaro,
                  rosaEscuro: _rosa,
                  onDateChanged: (date) => setState(() => _dataNascimento = date),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Telemóvel + Nº Utente
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                  decoration: _inputDecoration(Icons.phone_android_outlined, 'Nº Telemóvel'),
                  cursorColor: _rosa,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _healthNumberController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                  decoration: _inputDecoration(Icons.tag, 'Nº Utente', leftPadding: 10),
                  cursorColor: _rosa,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Morada
          TextField(
            controller: _moradaController,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
            decoration: _inputDecoration(Icons.home_outlined, 'Morada', iconSize: 20),
            cursorColor: _rosa,
          ),
          const SizedBox(height: 16),

          // E-mail
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
            decoration: _inputDecoration(Icons.mail_outline, 'E-mail'),
            cursorColor: _rosa,
          ),
          const SizedBox(height: 16),

          // Palavra-Passe
          TextField(
            controller: _passwordController,
            obscureText: !_passwordVisible,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
            decoration: _inputDecoration(Icons.lock_outline, 'Palavra-passe', iconSize: 20)
                .copyWith(
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _passwordVisible = !_passwordVisible),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    _passwordVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: _rosaClaro, size: 18,
                  ),
                ),
              ),
            ),
            cursorColor: _rosa,
          ),
          const SizedBox(height: 24),

          // Tipo de utilizador
          Row(
            children: [
              const SizedBox(
                width: 32,
                child: Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.manage_accounts_outlined, color: _rosaClaro, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              ...(_tipos.map((tipo) {
                final selecionado = _tipoSelecionado == tipo;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _tipoSelecionado = tipo),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: selecionado ? _rosa : Colors.transparent,
                        border: Border.all(
                          color: selecionado ? _rosa : _rosaClaro, width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tipo,
                        style: TextStyle(
                          fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600,
                          color: selecionado ? Colors.white : _rosaClaro,
                        ),
                      ),
                    ),
                  ),
                );
              })),
            ],
          ),
          const SizedBox(height: 24),

          // Especialidade (só para Médicos)
          if (_tipoSelecionado == 'Médico')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Especialidade',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                        fontWeight: FontWeight.w700, color: Colors.black)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: _rosaClaro, width: 1.2)),
                  ),
                  child: _loadingEspecialidades
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _rosa))),
                      )
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                    isExpanded: true,
                    underline: const SizedBox(),
                    value: _especialidadeSelecionada,
                    hint: const Text('Selecione uma especialidade',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey)),
                    items: _especialidades.map((esp) {
                      return DropdownMenuItem<int>(
                        value: esp['id'],
                        child: Text(esp['name'], style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _especialidadeSelecionada = v),
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black87),
                  ),
                ),
                ),
                const SizedBox(height: 24),
              ],
            ),

          const SizedBox(height: 16),

          // Mensagem de erro
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_errorMessage!,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.red.shade700)),
              ),
            ),

          // Botão Criar
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _criarUtilizador,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4537E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 0,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.white), strokeWidth: 2,
                      ),
                    )
                  : const Text('Criar Utilizador',
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700,
                          fontSize: 15, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: _confirmarCancelar,
              child: const Text('Cancelar',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 14,
                      fontWeight: FontWeight.w700, color: _rosaClaro)),
            ),
          ),
        ],
      ),
    );
  }
}

// Date Picker
class _DatePickerField extends StatefulWidget {
  final Color rosa;
  final Color rosaEscuro;
  final Function(DateTime?)? onDateChanged;

  const _DatePickerField({
    required this.rosa,
    required this.rosaEscuro,
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
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: widget.rosa, width: 1.2)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const SizedBox(
              width: 32,
              child: Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.calendar_today_outlined, color: Color(0xFFD4537E), size: 18),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _label,
              style: TextStyle(
                fontFamily: 'Poppins', fontSize: 13,
                color: _selectedDate == null ? Colors.grey.shade400 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}