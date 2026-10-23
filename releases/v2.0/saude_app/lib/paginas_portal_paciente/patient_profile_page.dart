import 'package:saude_app/paginas_portal_paciente/portal_paciente.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _verde = Color(0xFF1A8070);

  // Supabase client
  final _supabase = Supabase.instance.client;

  // Estado de carregamento
  bool _isLoading = true;
  bool _isSavingPrefs = false;

  // Dados do utilizador carregados da BD
  String _nome = '';
  String _email = '';
  String _iniciais = '';
  String _nif = '';
  String _telemovel = '';
  String _morada = '';

  // Preferências de notificações
  bool _notifEmail = true;
  bool _notifSMS = false;
  bool _lembrete24h = true;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  /// Carrega os dados do utilizador autenticado a partir das tabelas `users` e `user_preferences`
  Future<void> _carregarPerfil() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Buscar dados do utilizador
      final userData = await _supabase
          .from('users')
          .select('name, email, nif, phone, address')
          .eq('id', userId)
          .single();

      // Buscar preferências de notificações
      final prefsData = await _supabase
          .from('user_preferences')
          .select('email_notifications, push_notifications, reminder_24h')
          .eq('user_id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _nome = userData['name'] ?? '';
          _email = userData['email'] ?? '';
          _nif = userData['nif'] ?? '—';
          _telemovel = userData['phone'] ?? '—';
          _morada = userData['address'] ?? '—';

          // Gerar iniciais a partir do nome
          final partes = _nome.trim().split(' ');
          _iniciais = partes.length >= 2
              ? '${partes.first[0]}${partes.last[0]}'.toUpperCase()
              : _nome.isNotEmpty
                  ? _nome[0].toUpperCase()
                  : '?';

          if (prefsData != null) {
            _notifEmail = prefsData['email_notifications'] ?? true;
            _notifSMS = prefsData['push_notifications'] ?? false;
            _lembrete24h = prefsData['reminder_24h'] ?? true;
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar perfil: $e',
                style: const TextStyle(fontFamily: 'Poppins')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Guarda uma preferência de notificação na tabela `user_preferences`
  Future<void> _guardarPreferencia(String campo, bool valor) async {
    setState(() => _isSavingPrefs = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('user_preferences').upsert(
        {
          'user_id': userId,
          campo: valor,
        },
        onConflict: 'user_id',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao guardar preferência: $e',
                style: const TextStyle(fontFamily: 'Poppins')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingPrefs = false);
    }
  }

  /// Faz logout via Supabase Auth e navega para o ecrã de login
  Future<void> _confirmarLogout() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Terminar Sessão',
          style: TextStyle(
              fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: const Text(
          'Tem a certeza que pretende sair?',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _supabase.auth.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (r) => false,
                );
              }
            },
            child: const Text('Sair',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFFC62828),
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  /// Elimina a conta do utilizador (soft delete via `deleted_at`) e faz logout
  Future<void> _eliminarConta() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Eliminar Conta',
          style: TextStyle(
              fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: const Text(
          'Tem a certeza que pretende eliminar a sua conta?\nEsta ação é permanente e não pode ser revertida.',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final userId = _supabase.auth.currentUser?.id;
                if (userId == null) return;

                // Soft delete: marcar deleted_at
                await _supabase
                    .from('users')
                    .update({'deleted_at': DateTime.now().toIso8601String()})
                    .eq('id', userId);

                await _supabase.auth.signOut();

                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (r) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao eliminar conta: $e',
                          style: const TextStyle(fontFamily: 'Poppins')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Eliminar',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFFC62828),
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
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
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1A8070),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _iniciais,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _nome,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _email,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Color(0xFF777777),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 8),
                        decoration: BoxDecoration(
                          color: _verde,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'Paciente',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const PatientEditProfileScreen()),
                      ).then((_) => _carregarPerfil()); // recarrega ao voltar
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFFB2DFDB), width: 1.5),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Editar Perfil',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF1A8070),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'DADOS PESSOAIS',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A8070),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _DadosRow(
                          label: 'NIF', valor: _nif, divisor: true),
                      _DadosRow(
                          label: 'Telemóvel',
                          valor: _telemovel,
                          divisor: true),
                      _DadosRow(
                          label: 'Morada', valor: _morada, divisor: false),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    const Text(
                      'NOTIFICAÇÕES',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A8070),
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (_isSavingPrefs) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1A8070)),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _ToggleRow(
                        label: 'Notificações por email',
                        value: _notifEmail,
                        onChanged: (v) {
                          setState(() => _notifEmail = v);
                          _guardarPreferencia('email_notifications', v);
                        },
                        divisor: true,
                      ),
                      _ToggleRow(
                        label: 'Notificações por SMS',
                        value: _notifSMS,
                        onChanged: (v) {
                          setState(() => _notifSMS = v);
                          _guardarPreferencia('push_notifications', v);
                        },
                        divisor: true,
                      ),
                      _ToggleRow(
                        label: 'Lembrete 24h antes',
                        value: _lembrete24h,
                        onChanged: (v) {
                          setState(() => _lembrete24h = v);
                          _guardarPreferencia('reminder_24h', v);
                        },
                        divisor: false,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                const _SecaoTitulo(label: 'SEGURANÇA'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x0F000000),
                          blurRadius: 16,
                          offset: Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    children: [
                      _AcaoRow(
                        label: 'Alterar Password',
                        icon: Icons.lock_outline,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ChangePassword()),
                          );
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFE0E0E0)),
                      _AcaoRow(
                        label: 'Eliminar Conta',
                        icon: Icons.delete_outline,
                        onTap: _eliminarConta,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                GestureDetector(
                  onTap: _confirmarLogout,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F0),
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(
                          color: const Color(0xFFFFCDD2), width: 1.5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_outlined,
                            color: Color(0xFFC62828), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Terminar Sessão',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFC62828),
                              fontFamily: 'Poppins'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
    );
  }
}


class _SecaoTitulo extends StatelessWidget {
  final String label;
  const _SecaoTitulo({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A8070),
            fontFamily: 'Poppins',
            letterSpacing: 1.1,
          )),
    );
  }
}

class _AcaoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AcaoRow(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: label == 'Eliminar Conta'
                  ? const Color(0xFFC62828)
                  : const Color(0xFF3DBDAD),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontSize: 13,
                    color: label == 'Eliminar Conta'
                        ? const Color(0xFFC62828)
                        : Colors.black87,
                    fontFamily: 'Poppins',
                  )),
            ),
            const Icon(Icons.chevron_right, color: Colors.black54, size: 20),
          ],
        ),
      ),
    );
  }
}

class _DadosRow extends StatelessWidget {
  final String label;
  final String valor;
  final bool divisor;

  const _DadosRow({
    required this.label,
    required this.valor,
    required this.divisor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  valor,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (divisor) const Divider(height: 1, color: Color(0xFFE0E0E0)),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool divisor;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.divisor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFF1A8070),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFB2DFDB),
                trackOutlineColor:
                    WidgetStateProperty.all(Colors.transparent),
              ),
            ],
          ),
        ),
        if (divisor) const Divider(height: 1, color: Color(0xFFE0E0E0)),
      ],
    );
  }
}
