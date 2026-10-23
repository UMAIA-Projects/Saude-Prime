import 'package:saude_app/paginas_portal_admin/portal_admin.dart';
import 'package:saude_app/paginas_fluxo_publico/fluxo_publico.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Color palette
  static const Color _accent = Color(0xFF3DBDAD);
  static const Color _accentLight = Color(0xFF7CDACF);
  static const Color _pink = Color(0xFFD4537E);
  static const Color _pinkLight = Color(0xFFE598B2);

  int _navIndex = 4;

  // Toggle state - loaded from user_preferences
  bool _notifSistema = true;
  bool _relatoriosAuto = false;
  bool _newsletterOptin = false;

  // Edit mode
  bool _modoEdicao = false;

  // Loading / saving / error state
  bool _loading = true;
  String? _error;
  bool _saving = false;

  // User data
  String _userId = '';
  // _iniciais é o único estado que o template precisa de receber ao vivo
  String _iniciais = '--';

  late final TextEditingController _nomeCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _contactoCtrl;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _contactoCtrl = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _contactoCtrl.dispose();
    super.dispose();
  }

  // Calcula iniciais a partir do nome completo
  String _buildIniciais(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    final uteis = parts.where((p) => !p.endsWith('.')).toList();
    if (uteis.length >= 2)
      return '${uteis.first[0]}${uteis.last[0]}'.toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  // Carrega perfil + preferências do Supabase
  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final currentUser = db.auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _error = 'Sessão expirada. Por favor, inicia sessão novamente.';
          _loading = false;
        });
        return;
      }

      _userId = currentUser.id;

      final userData = await db
          .from('users')
          .select('name, email, phone')
          .eq('id', _userId)
          .single();

      final prefData = await db
          .from('user_preferences')
          .select('email_notifications, push_notifications, newsletter_optin')
          .eq('user_id', _userId)
          .maybeSingle();

      final name = userData['name'] as String? ?? '';
      final email = userData['email'] as String? ?? '';
      final phone = userData['phone'] as String? ?? '';

      setState(() {
        _nomeCtrl.text = name;
        _emailCtrl.text = email;
        _contactoCtrl.text = phone;
        _iniciais = _buildIniciais(name); // ← atualiza iniciais ao carregar
        _notifSistema = prefData?['email_notifications'] as bool? ?? true;
        _relatoriosAuto = prefData?['push_notifications'] as bool? ?? false;
        _newsletterOptin = prefData?['newsletter_optin'] as bool? ?? false;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar perfil: $e';
        _loading = false;
      });
    }
  }

  // Guarda alterações no Supabase e atualiza as iniciais imediatamente
  Future<void> _guardarAlteracoes() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await db
          .from('users')
          .update({
            'name': _nomeCtrl.text.trim(),
            'phone': _contactoCtrl.text.trim(),
          })
          .eq('id', _userId);

      await db.from('user_preferences').upsert({
        'user_id': _userId,
        'email_notifications': _notifSistema,
        'push_notifications': _relatoriosAuto,
        'newsletter_optin': _newsletterOptin,
      });

      setState(() {
        // Recalcula as iniciais com o novo nome - o TemplatePortalAdmin
        // recebe este valor via userInitialsOverride e atualiza o círculo
        // no mesmo frame, sem precisar de reload.
        _iniciais = _buildIniciais(_nomeCtrl.text.trim());
        _modoEdicao = false;
        _saving = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao guardar alterações: $e';
        _saving = false;
      });
    }
  }

  void _toggleEdicao() {
    if (_modoEdicao) {
      _guardarAlteracoes();
    } else {
      setState(() => _modoEdicao = true);
    }
  }

  // Guarda preferência de toggle imediatamente (optimistic update)
  Future<void> _savePreference(String key, bool value) async {
    try {
      await db.from('user_preferences').upsert({
        'user_id': _userId,
        key: value,
      });
    } catch (_) {
      // silently ignore - UI já atualizado de forma optimista
    }
  }

  Future<void> _eliminarConta() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Eliminar Conta',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: const Text(
          'Tem a certeza que pretende eliminar a sua conta?\nEsta ação é permanente e não pode ser revertida.',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final userId = db.auth.currentUser?.id;
                if (userId == null) return;

                await db
                    .from('users')
                    .update({'deleted_at': DateTime.now().toIso8601String()})
                    .eq('id', userId);
                await db.auth.signOut();

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
                      content: Text(
                        'Erro ao eliminar conta: $e',
                        style: const TextStyle(fontFamily: 'Poppins'),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFFC62828),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmarLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Terminar Sessão',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: const Text(
          'Tem a certeza que pretende sair?',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: _accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await db.auth.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (r) => false,
                );
              }
            },
            child: const Text(
              'Sair',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFFC62828),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePortalAdmin(
      currentIndex: _navIndex,
      onNavTap: (i) => setState(() => _navIndex = i),
      // Passa as iniciais actuais diretamente - quando o utilizador guarda
      // um novo nome, _iniciais é recalculado no setState de _guardarAlteracoes
      // e o template re-renderiza o círculo no mesmo frame, sem reload.
      userInitialsOverride: _loading ? null : _iniciais,
      child: _loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: CircularProgressIndicator(color: _pink),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Error banner
                if (_error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFCDD2)),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Color(0xFFC62828),
                      ),
                    ),
                  ),

                // Avatar - usa as mesmas iniciais do template
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 93,
                        height: 93,
                        decoration: BoxDecoration(
                          color: _pink,
                          shape: BoxShape.circle,
                          border: Border.all(color: _pinkLight, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33D4537E),
                              blurRadius: 20,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _iniciais,
                          style: const TextStyle(
                            fontSize: 37,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            height: 1,
                          ),
                        ),
                      ),
                      if (_modoEdicao)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Nome
                _modoEdicao
                    ? SizedBox(
                        width: 200,
                        child: _CampoEdicao(
                          controller: _nomeCtrl,
                          textAlign: TextAlign.center,
                          // Atualiza _iniciais em tempo real enquanto o utilizador escreve
                          onChanged: (v) =>
                              setState(() => _iniciais = _buildIniciais(v)),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      )
                    : Text(
                        _nomeCtrl.text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          fontFamily: 'Poppins',
                        ),
                      ),
                const SizedBox(height: 3),

                // Email (só leitura)
                Opacity(
                  opacity: 0.6,
                  child: Text(
                    _emailCtrl.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _pink,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Administrador',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Editar / Guardar button
                GestureDetector(
                  onTap: _saving ? null : _toggleEdicao,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _modoEdicao ? _accent : Colors.white,
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(color: _accentLight, width: 2),
                    ),
                    child: _saving
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _modoEdicao
                                    ? Icons.check_rounded
                                    : Icons.edit_outlined,
                                color: _modoEdicao ? Colors.white : _accent,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _modoEdicao
                                    ? 'Guardar Alterações'
                                    : 'Editar Perfil',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _modoEdicao ? Colors.white : _accent,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 22),

                // Dados Pessoais
                const _SecaoTitulo(label: 'DADOS PESSOAIS'),
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
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _DadoRow(
                        label: 'Nome',
                        controller: _nomeCtrl,
                        modoEdicao: _modoEdicao,
                        onChanged: (v) =>
                            setState(() => _iniciais = _buildIniciais(v)),
                      ),
                      const _Divider(),
                      _DadoRow(
                        label: 'Email',
                        controller: _emailCtrl,
                        modoEdicao: false,
                      ),
                      const _Divider(),
                      _DadoRow(
                        label: 'Contacto',
                        controller: _contactoCtrl,
                        modoEdicao: _modoEdicao,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Administração do Sistema
                const _SecaoTitulo(label: 'NOTIFICAÇÕES'),
                const SizedBox(height: 8),
                // Notificações
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 16,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _ToggleRow(
                        label: 'Notificações do Sistema',
                        value: _notifSistema,
                        onChanged: (v) {
                          setState(() => _notifSistema = v);
                          _savePreference('email_notifications', v);
                        },
                      ),
                      const _Divider(),
                      _ToggleRow(
                        label: 'Relatórios Automáticos',
                        value: _relatoriosAuto,
                        onChanged: (v) {
                          setState(() => _relatoriosAuto = v);
                          _savePreference('push_notifications', v);
                        },
                      ),
                      const _Divider(),
                      _ToggleRow(
                        label: 'Subscrição da Newsletter',
                        value: _newsletterOptin,
                        onChanged: (v) {
                          setState(() => _newsletterOptin = v);
                          _savePreference('newsletter_optin', v);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Segurança
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
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _AcaoRow(
                        label: 'Configurar Newsletter',
                        icon: Icons.mail_outline,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SendNewsletterPage(),
                          ),
                        ),
                      ),
                      _AcaoRow(
                        label: 'Alterar Password',
                        icon: Icons.lock_outline,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChangePassword(),
                          ),
                        ),
                      ),
                      const _Divider(),
                      _AcaoRow(
                        label: 'Eliminar Conta',
                        icon: Icons.delete_outline,
                        onTap: _eliminarConta,
                        isDestructive: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Terminar Sessão
                GestureDetector(
                  onTap: _confirmarLogout,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F0),
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(
                        color: const Color(0xFFFFCDD2),
                        width: 1.5,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout_outlined,
                          color: Color(0xFFC62828),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Terminar Sessão',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFC62828),
                            fontFamily: 'Poppins',
                          ),
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

// Widgets auxiliares

class _SecaoTitulo extends StatelessWidget {
  final String label;
  const _SecaoTitulo({required this.label});
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A8070),
        fontFamily: 'Poppins',
        letterSpacing: 1.1,
      ),
    ),
  );
}

class _CampoEdicao extends StatelessWidget {
  final TextEditingController controller;
  final TextStyle style;
  final TextAlign textAlign;
  final ValueChanged<String>? onChanged;

  const _CampoEdicao({
    required this.controller,
    required this.style,
    this.textAlign = TextAlign.start,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    textAlign: textAlign,
    style: style,
    onChanged: onChanged,
    decoration: const InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(vertical: 4),
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF3DBDAD), width: 1.2),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF3DBDAD), width: 1.8),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFB2DFDB), width: 1.0),
      ),
    ),
  );
}

class _DadoRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool modoEdicao;
  final ValueChanged<String>? onChanged;

  const _DadoRow({
    required this.label,
    required this.controller,
    required this.modoEdicao,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
    child: Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8AADA8),
              fontFamily: 'Poppins',
            ),
          ),
        ),
        Expanded(
          child: modoEdicao
              ? _CampoEdicao(
                  controller: controller,
                  onChanged: onChanged,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    fontFamily: 'Poppins',
                  ),
                )
              : Text(
                  controller.text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    fontFamily: 'Poppins',
                  ),
                ),
        ),
        if (modoEdicao)
          const Icon(Icons.edit_outlined, size: 15, color: Color(0xFF3DBDAD)),
      ],
    ),
  );
}

class _AcaoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  const _AcaoRow({
    this.icon = Icons.circle,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCircleDot = icon == Icons.circle;
    final Color color = isDestructive
        ? const Color(0xFFC62828)
        : const Color(0xFF3DBDAD);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            isCircleDot
                ? Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7CDACF),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF46AA9F),
                        width: 1,
                      ),
                    ),
                  )
                : Icon(icon, color: color, size: 18),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isDestructive
                      ? const Color(0xFFC62828)
                      : Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDestructive ? const Color(0xFFC62828) : Colors.black54,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        Transform.scale(
          scale: 0.80,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF3DBDAD),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFD0D0D0),
          ),
        ),
      ],
    ),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Divider(
    color: Color(0xFFF0F0F0),
    height: 1,
    thickness: 1,
    indent: 20,
    endIndent: 20,
  );
}
