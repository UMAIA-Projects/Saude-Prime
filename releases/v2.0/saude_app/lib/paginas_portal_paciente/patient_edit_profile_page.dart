import 'package:saude_app/paginas_portal_paciente/portal_paciente.dart';

class PatientEditProfileScreen extends StatefulWidget {
  const PatientEditProfileScreen({super.key});

  @override
  State<PatientEditProfileScreen> createState() =>
      _PatientEditProfileScreenState();
}

class _PatientEditProfileScreenState extends State<PatientEditProfileScreen> {
  static const Color _verde = Color(0xFF1A8070);

  final _supabase = Supabase.instance.client;

  // Controllers dos campos editáveis
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _moradaController = TextEditingController();

  // Campos não editáveis (apenas leitura)
  String _nif = '';
  String _email = '';

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _moradaController.dispose();
    super.dispose();
  }

  /// Carrega os dados atuais do utilizador autenticado
  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _supabase
          .from('users')
          .select('name, email, nif, phone, address')
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          _nomeController.text = data['name'] ?? '';
          _telefoneController.text = data['phone'] ?? '';
          _moradaController.text = data['address'] ?? '';
          _nif = data['nif'] ?? '—';
          _email = data['email'] ?? '—';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarErro('Erro ao carregar dados: $e');
      }
    }
  }

  /// Guarda as alterações na tabela `users`
  Future<void> _guardarAlteracoes() async {
    final nome = _nomeController.text.trim();
    final telefone = _telefoneController.text.trim();
    final morada = _moradaController.text.trim();

    if (nome.isEmpty) {
      _mostrarErro('O nome não pode estar vazio.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('users').update({
        'name': nome,
        'phone': telefone.isEmpty ? null : telefone,
        'address': morada.isEmpty ? null : morada,
      }).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!',
                style: TextStyle(fontFamily: 'Poppins')),
            backgroundColor: Color(0xFF1A8070),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _mostrarErro('Erro ao guardar alterações: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: Colors.red,
      ),
    );
  }

  InputDecoration _inputDecoration(IconData icon, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
        color: Color(0xFFB2B2B2),
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF1A1A1A), size: 22),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF1A8070), width: 1.5),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF1A8070), width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePortalPaciente(
      currentIndex: 4,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A8070)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    '< Voltar atrás',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A8070),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Editar Perfil',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),

                const SizedBox(height: 24),


                // Nome
                TextField(
                  controller: _nomeController,
                  style: const TextStyle(
                      fontFamily: 'Poppins', fontSize: 15),
                  decoration:
                      _inputDecoration(Icons.person_outline, 'Nome completo'),
                  cursorColor: _verde,
                  textCapitalization: TextCapitalization.words,
                ),

                const SizedBox(height: 8),

                // Telemóvel
                TextField(
                  controller: _telefoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                      fontFamily: 'Poppins', fontSize: 15),
                  decoration:
                      _inputDecoration(Icons.phone_outlined, 'Telemóvel'),
                  cursorColor: _verde,
                ),

                const SizedBox(height: 8),

                // Morada
                TextField(
                  controller: _moradaController,
                  style: const TextStyle(
                      fontFamily: 'Poppins', fontSize: 15),
                  decoration:
                      _inputDecoration(Icons.home_outlined, 'Morada'),
                  cursorColor: _verde,
                ),

                const SizedBox(height: 28),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NÃO EDITÁVEL',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9E9E9E),
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // NIF (da BD)
                      Row(
                        children: [
                          const Icon(Icons.credit_card_off_outlined,
                              size: 18, color: Color(0xFFB2B2B2)),
                          const SizedBox(width: 10),
                          Text(
                            _nif,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: Color(0xFFB2B2B2),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: Color(0xFFE0E0E0)),
                      const Text(
                        'Para alterar o NIF, contacta a clínica.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Color(0xFFB2B2B2),
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Email (da BD)
                      Row(
                        children: [
                          const Icon(Icons.mail_outline,
                              size: 18, color: Color(0xFFB2B2B2)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _email,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: Color(0xFFB2B2B2),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: Color(0xFFE0E0E0)),
                      const Text(
                        'Para alterar o email, contacta o suporte.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Color(0xFFB2B2B2),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _guardarAlteracoes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _verde,
                      disabledBackgroundColor:
                          _verde.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Guardar Alterações',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 14),

                Center(
                  child: GestureDetector(
                    onTap: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A),
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
    );
  }
}
