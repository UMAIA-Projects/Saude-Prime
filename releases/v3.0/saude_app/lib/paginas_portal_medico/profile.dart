import 'package:saude_app/paginas_portal_medico/portal_medico.dart';
import 'package:saude_app/paginas_fluxo_publico/login_page.dart';
import 'package:saude_app/paginas_fluxo_publico/change_password.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  // Controladores editáveis
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _contactoCtrl;

  // Dados profissionais (só leitura)
  String _especialidade = '-';
  String _licenca = '-';
  String _instituicao = '-';

  // Iniciais para o avatar
  String _initials = '?';

  // Notificações (user_preferences)
  bool _notifMarcacao = true;    // appointment_alerts
  bool _alertasFila = true;      // push_notifications (fila)
  bool _notifDocumentos = false; // email_notifications (documentos)
  bool _newsletterOptin = false; // newsletter_optin

  // Estatísticas
  int _consultasHoje = 0;
  int _consultasSemana = 0;
  int _pacientesAtivos = 0;

  // Estado UI
  bool _loading = true;
  bool _saving = false;
  bool _modoEdicao = false;
  String? _error;

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

  // Helpers
  String _toInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  // Carrega todos os dados do perfil
  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final userId = db.auth.currentUser?.id;
      if (userId == null) throw Exception('Sem sessão ativa');

      // 1. Dados pessoais
      final userRow = await db
          .from('users')
          .select('name, email, phone')
          .eq('id', userId)
          .single();

      final userName = userRow['name'] as String? ?? '';
      final userEmail = userRow['email'] as String? ?? '';
      final userPhone = userRow['phone'] as String? ?? '';

      // 2. Dados profissionais
      final doctorRow = await db
          .from('doctors')
          .select('license_number, specialties(name)')
          .eq('user_id', userId)
          .maybeSingle();

      final licenca = doctorRow?['license_number'] as String? ?? '-';
      final especialidade =
          (doctorRow?['specialties'] as Map?)?['name'] as String? ?? '-';

      // 3. Preferências de notificações
      Map<String, dynamic>? prefs;
      try {
        prefs = await db
            .from('user_preferences')
            .select(
                'appointment_alerts, push_notifications, email_notifications, newsletter_optin')
            .eq('user_id', userId)
            .single();
      } catch (_) {
        // Pode não existir ainda - usa defaults
      }

      // 4. Estatísticas: consultas hoje
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weekStartStr =
          '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';

      final statsHoje = await db
          .from('appointments')
          .select('id')
          .eq('doctor_id', userId)
          .eq('scheduled_date', todayStr)
          .neq('status', 'canceled')
          .isFilter('deleted_at', null);

      final statsSemana = await db
          .from('appointments')
          .select('id')
          .eq('doctor_id', userId)
          .gte('scheduled_date', weekStartStr)
          .lte('scheduled_date', todayStr)
          .neq('status', 'canceled')
          .isFilter('deleted_at', null);

      // Pacientes distintos com consulta concluída com este médico
      final statsPacientes = await db
          .from('appointments')
          .select('patient_id')
          .eq('doctor_id', userId)
          .eq('status', 'completed')
          .isFilter('deleted_at', null);

      final Set<dynamic> uniquePatients = {};
      for (final r in statsPacientes as List) {
        uniquePatients.add(r['patient_id']);
      }

      // Instituição via clinic_settings (optional)
      String instituicao = '-';
      try {
        final setting = await db
            .from('clinic_settings')
            .select('setting_value')
            .eq('setting_key', 'clinic_name')
            .maybeSingle();
        if (setting != null) {
          instituicao = setting['setting_value'] as String? ?? '-';
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _nomeCtrl.text = userName;
        _emailCtrl.text = userEmail;
        _contactoCtrl.text = userPhone;
        _initials = _toInitials(userName);
        _licenca = licenca;
        _especialidade = especialidade;
        _instituicao = instituicao;

        if (prefs != null) {
          _notifMarcacao   = prefs['appointment_alerts']  as bool? ?? true;
          _alertasFila     = prefs['push_notifications']  as bool? ?? true;
          _notifDocumentos = prefs['email_notifications'] as bool? ?? false;
          _newsletterOptin = prefs['newsletter_optin']    as bool? ?? false;
        }

        _consultasHoje = (statsHoje as List).length;
        _consultasSemana = (statsSemana as List).length;
        _pacientesAtivos = uniquePatients.length;

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao carregar perfil: $e';
        _loading = false;
      });
    }
  }

  // Guardar alterações pessoais
  Future<void> _guardarAlteracoes() async {
    final userId = db.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _saving = true);
    try {
      await db
          .from('users')
          .update({
            'name': _nomeCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'phone': _contactoCtrl.text.trim(),
          })
          .eq('id', userId);

      setState(() {
        _initials = _toInitials(_nomeCtrl.text.trim());
        _modoEdicao = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggleEdicao() {
    if (_modoEdicao) {
      _guardarAlteracoes();
    } else {
      setState(() => _modoEdicao = true);
    }
  }

  // Guardar preferência de notificação
  Future<void> _savePreference(String column, bool value) async {
    final userId = db.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await db.from('user_preferences').upsert({
        'user_id': userId,
        column: value,
      }, onConflict: 'user_id');
    } catch (_) {
      // ignora silenciosamente - toggle já foi atualizado na UI
    }
  }

  // Eliminar conta
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

                await db.from('users').update(
                    {'deleted_at': DateTime.now().toIso8601String()}).eq('id', userId);
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
                      content: Text('Erro ao eliminar conta: $e',
                          style: const TextStyle(fontFamily: 'Poppins')),
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

  // Logout
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
                color: Color(0xFF3DBDAD),
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
    if (_loading) {
      return const TemplatePortalMedico(
        currentIndex: 4,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF3DBDAD)),
        ),
      );
    }

    if (_error != null) {
      return TemplatePortalMedico(
        currentIndex: 4,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                style: const TextStyle(
                  color: Color(0xFFC62828),
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _loadProfile,
                child: const Text(
                  'Tentar novamente',
                  style: TextStyle(
                    color: Color(0xFF3DBDAD),
                    fontFamily: 'Poppins',
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return TemplatePortalMedico(
      currentIndex: 4,
      userInitials: _initials,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: const Color(0xFF46AA9F),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF7CDACF),
                      width: 3,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2246AA9F),
                        blurRadius: 20,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                if (_modoEdicao)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3DBDAD),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 13,
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
                    letterSpacing: -0.3,
                  ),
                ),

          const SizedBox(height: 3),

          // Email
          _modoEdicao
              ? SizedBox(
                  width: 240,
                  child: _CampoEdicao(
                    controller: _emailCtrl,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6A9890),
                      fontFamily: 'Poppins',
                    ),
                  ),
                )
              : Text(
                  _emailCtrl.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6A9890),
                    fontFamily: 'Poppins',
                  ),
                ),

          const SizedBox(height: 10),

          // Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Badge(
                label: 'Médico',
                bg: const Color(0xFF98D1FF),
                fg: const Color(0xFF1A3B8B),
              ),
              const SizedBox(width: 8),
              _Badge(
                label: _especialidade,
                bg: const Color(0xFFD8F2EF),
                fg: const Color(0xFF1A6B62),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Estatísticas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 16,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _StatCol(valor: '$_consultasHoje', label: 'Hoje'),
                _VertDivider(),
                _StatCol(valor: '$_consultasSemana', label: 'Esta semana'),
                _VertDivider(),
                _StatCol(valor: '$_pacientesAtivos', label: 'Pacientes'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Botão Editar / Guardar
          GestureDetector(
            onTap: _saving ? null : _toggleEdicao,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _modoEdicao ? const Color(0xFF3DBDAD) : Colors.white,
                borderRadius: BorderRadius.circular(35),
                border: Border.all(color: const Color(0xFF3DBDAD), width: 2),
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
                          color: _modoEdicao
                              ? Colors.white
                              : const Color(0xFF3DBDAD),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _modoEdicao ? 'Guardar Alterações' : 'Editar Perfil',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _modoEdicao
                                ? Colors.white
                                : const Color(0xFF3DBDAD),
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
            ),
            child: Column(
              children: [
                _DadoRow(
                  label: 'Nome',
                  controller: _nomeCtrl,
                  modoEdicao: _modoEdicao,
                  editavel: true,
                ),
                const _Divider(),
                _DadoRow(
                  label: 'Email',
                  controller: _emailCtrl,
                  modoEdicao: _modoEdicao,
                  editavel: true,
                ),
                const _Divider(),
                _DadoRow(
                  label: 'Contacto',
                  controller: _contactoCtrl,
                  modoEdicao: _modoEdicao,
                  editavel: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Dados Profissionais
          const _SecaoTitulo(label: 'DADOS PROFISSIONAIS'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                _DadoTexto(label: 'Especialidade', valor: _especialidade),
                const _Divider(),
                _DadoTexto(label: 'Nº Licença', valor: _licenca),
                const _Divider(),
                _DadoTexto(label: 'Instituição', valor: _instituicao),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Notificações
          const _SecaoTitulo(label: 'NOTIFICAÇÕES'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                _ToggleRow(
                  label: 'Notificações de Marcação',
                  value: _notifMarcacao,
                  onChanged: (v) {
                    setState(() => _notifMarcacao = v);
                    _savePreference('appointment_alerts', v);
                  },
                ),
                const _Divider(),
                _ToggleRow(
                  label: 'Alertas de Fila',
                  value: _alertasFila,
                  onChanged: (v) {
                    setState(() => _alertasFila = v);
                    _savePreference('push_notifications', v);
                  },
                ),
                const _Divider(),
                _ToggleRow(
                  label: 'Novos Documentos',
                  value: _notifDocumentos,
                  onChanged: (v) {
                    setState(() => _notifDocumentos = v);
                    _savePreference('email_notifications', v);
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
            ),
            child: Column(
              children: [
                _AcaoRow(
                  icon: Icons.lock_outline,
                  label: 'Alterar Palavra-Passe',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChangePassword(),
                      ),
                    );
                  },
                ),
                const _Divider(),
                _AcaoRow(
                  icon: Icons.delete_outline,
                  label: 'Eliminar Conta',
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
                border: Border.all(color: const Color(0xFFFFCDD2), width: 1.5),
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


// Widgets auxiliares (mantidos idênticos ao original + ajustes mínimos)
class _Badge extends StatelessWidget {
  final String label;
  final Color bg, fg;
  const _Badge({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
          fontFamily: 'Poppins',
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String valor, label;
  const _StatCol({required this.valor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            valor,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A8070),
              fontFamily: 'Poppins',
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.black.withValues(alpha: 0.45),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: const Color(0xFFEEEEEE));
}

class _SecaoTitulo extends StatelessWidget {
  final String label;
  const _SecaoTitulo({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF3DBDAD),
          fontFamily: 'Poppins',
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

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
}

class _DadoRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool modoEdicao;
  final bool editavel;
  const _DadoRow({
    required this.label,
    required this.controller,
    required this.modoEdicao,
    this.editavel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            child: (editavel && modoEdicao)
                ? _CampoEdicao(
                    controller: controller,
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
          if (editavel && modoEdicao)
            const Icon(Icons.edit_outlined, size: 15, color: Color(0xFF3DBDAD)),
        ],
      ),
    );
  }
}

class _DadoTexto extends StatelessWidget {
  final String label, valor;
  const _DadoTexto({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            child: Text(
              valor,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const Icon(Icons.lock_outline, size: 14, color: Color(0xFFCCCCCC)),
        ],
      ),
    );
  }
}

class _AcaoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  const _AcaoRow(
      {required this.icon, required this.label, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? const Color(0xFFC62828) : const Color(0xFF3DBDAD);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDestructive ? const Color(0xFFC62828) : Colors.black,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: isDestructive
                    ? const Color(0xFFC62828)
                    : Colors.black.withValues(alpha: 0.25),
                size: 22),
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Transform.scale(
            scale: 0.80,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: const Color(0xFF3DBDAD),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return const Divider(
      color: Color(0xFFF0F0F0),
      height: 1,
      thickness: 1,
      indent: 20,
      endIndent: 20,
    );
  }
}
