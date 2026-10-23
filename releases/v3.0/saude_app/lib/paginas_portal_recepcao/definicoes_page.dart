import 'package:saude_app/paginas_portal_recepcao/portal_recepcao.dart';
import 'package:saude_app/paginas_fluxo_publico/login_page.dart';
import 'package:saude_app/paginas_fluxo_publico/change_password.dart';

class DefinicoesPage extends StatefulWidget {
  const DefinicoesPage({super.key});

  @override
  State<DefinicoesPage> createState() => _DefinicoesPageState();
}

class _DefinicoesPageState extends State<DefinicoesPage> {
  static const Color _teal = Color(0xFF42BCA3);
  static const Color _azul = Color(0xFF6B9CE8);

  bool _isLoading = true;
  bool _isSaving = false;
  bool _modoEdicao = false;

  bool _notificacoesMarcacao = true;
  bool _alertasFila = true;
  bool _newsletterOptin = false;

  String _iniciais = '??';

  late final TextEditingController _nomeCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _telemovelCtrl;
  late final TextEditingController _moradaCtrl;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _telemovelCtrl = TextEditingController();
    _moradaCtrl = TextEditingController();
    _carregarDados();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _telemovelCtrl.dispose();
    _moradaCtrl.dispose();
    super.dispose();
  }

  String _calcularIniciais(String nome) {
    final partes = nome.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '??';
    if (partes.length == 1) return partes[0][0].toUpperCase();
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }

  Future<void> _carregarDados() async {
    final userId = db.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final userData = await db
          .from('users')
          .select('name, email, phone, address')
          .eq('id', userId)
          .single();

      final prefData = await db
          .from('user_preferences')
          .select('appointment_alerts, push_notifications, newsletter_optin')
          .eq('user_id', userId)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _nomeCtrl.text = userData['name'] ?? '';
        _emailCtrl.text = userData['email'] ?? '';
        _telemovelCtrl.text = userData['phone'] ?? '';
        _moradaCtrl.text = userData['address'] ?? '';
        _iniciais = _calcularIniciais(_nomeCtrl.text);

        if (prefData != null) {
          _notificacoesMarcacao = prefData['appointment_alerts'] ?? true;
          _alertasFila = prefData['push_notifications'] ?? true;
          _newsletterOptin = prefData['newsletter_optin'] ?? false;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar perfil: $e')));
    }
  }

  Future<void> _guardarAlteracoes() async {
    final userId = db.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isSaving = true);
    try {
      await db
          .from('users')
          .update({
            'name': _nomeCtrl.text.trim(),
            'phone': _telemovelCtrl.text.trim(),
            'address': _moradaCtrl.text.trim(),
          })
          .eq('id', userId);

      await db.from('user_preferences').upsert({
        'user_id': userId,
        'appointment_alerts': _notificacoesMarcacao,
        'push_notifications': _alertasFila,
        'newsletter_optin': _newsletterOptin,
      });

      if (!mounted) return;
      setState(() {
        _iniciais = _calcularIniciais(_nomeCtrl.text);
        _modoEdicao = false;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao guardar: $e')));
    }
  }

  void _toggleEdicao() {
    if (_modoEdicao) {
      _guardarAlteracoes();
    } else {
      setState(() => _modoEdicao = true);
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

                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (r) => false,
                );
              } catch (e) {
                if (!mounted) return;
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
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFFD32F2F),
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
                color: _teal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await db.auth.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (r) => false,
              );
            },
            child: const Text(
              'Sair',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFFD32F2F),
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
    return TemplatePortalRecepcao(
      currentIndex: 4,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 86,
                        height: 86,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6B9CE8),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _iniciais,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                            fontFamily: 'Poppins',
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
                              color: _teal,
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
                        width: 220,
                        child: _CampoEdicao(
                          controller: _nomeCtrl,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      )
                    : Text(
                        _nomeCtrl.text,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: 'Poppins',
                        ),
                      ),
                const SizedBox(height: 2),

                // Email (só leitura - gerido pelo Supabase Auth)
                Text(
                  _emailCtrl.text,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7A97A9),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 12),

                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0DDF8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Rececionista',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7B66FF),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Botão Editar / Guardar
                GestureDetector(
                  onTap: _isSaving ? null : _toggleEdicao,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _modoEdicao ? _teal : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: _teal, width: 1.5),
                    ),
                    child: _isSaving
                        ? const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
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
                                color: _modoEdicao ? Colors.white : _teal,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _modoEdicao
                                    ? 'Guardar Alterações'
                                    : 'Editar Perfil',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _modoEdicao ? Colors.white : _teal,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Dados Pessoais
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Dados Pessoais',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _azul,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildCardBox(
                  child: Column(
                    children: [
                      _DadoRow(
                        label: 'Telemóvel',
                        controller: _telemovelCtrl,
                        modoEdicao: _modoEdicao,
                      ),
                      const _Divider(),
                      _DadoRow(
                        label: 'Morada',
                        controller: _moradaCtrl,
                        modoEdicao: _modoEdicao,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Notificações
                _buildCardBox(
                  child: Column(
                    children: [
                      _buildSwitchItem(
                        'Notificações de Marcação',
                        _notificacoesMarcacao,
                        (v) => setState(() => _notificacoesMarcacao = v),
                      ),
                      const _Divider(),
                      _buildSwitchItem(
                        'Alertas de Fila',
                        _alertasFila,
                        (v) => setState(() => _alertasFila = v),
                      ),
                      const _Divider(),
                      _buildSwitchItem(
                        'Subscrição da Newsletter',
                        _newsletterOptin,
                        (v) => setState(() => _newsletterOptin = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Alterar Palavra-Passe + Eliminar Conta
                _buildCardBox(
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChangePassword(),
                            ),
                          );
                        },
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.lock_outline,
                                color: Color(0xFF42BCA3),
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Alterar Palavra-Passe',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.black38,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const _Divider(),
                      InkWell(
                        onTap: _eliminarConta,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.delete_outline,
                                color: Color(0xFFD32F2F),
                                size: 18,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Eliminar Conta',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFD32F2F),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Color(0xFFD32F2F),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Terminar Sessão
                GestureDetector(
                  onTap: _confirmarLogout,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0xFFFFCDD2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/imagens_portal_recepcao/Door.svg',
                          width: 18,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFFD32F2F),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Terminar Sessão',
                          style: TextStyle(
                            color: Color(0xFFD32F2F),
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _buildCardBox({required Widget child}) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
    ),
    child: child,
  );

  Widget _buildSwitchItem(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: _teal,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.grey.shade300,
        ),
      ],
    ),
  );
}

// Auxiliary widgets 

class _CampoEdicao extends StatelessWidget {
  final TextEditingController controller;
  final TextStyle style;
  final TextAlign textAlign;

  const _CampoEdicao({
    required this.controller,
    required this.style,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: textAlign,
      style: style,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 4),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF42BCA3), width: 1.2),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF42BCA3), width: 1.8),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFB2DFDB), width: 1.0),
        ),
      ),
    );
  }
}

class _DadoRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool modoEdicao;

  const _DadoRow({
    required this.label,
    required this.controller,
    required this.modoEdicao,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF80CBC4),
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            child: modoEdicao
                ? _CampoEdicao(
                    controller: controller,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                  )
                : Text(
                    controller.text.isEmpty ? '-' : controller.text,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                  ),
          ),
          if (modoEdicao)
            const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF42BCA3)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Divider(
    color: Color(0xFFEEEEEE),
    height: 1,
    thickness: 0.5,
    indent: 16,
    endIndent: 16,
  );
}
