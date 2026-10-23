import 'package:saude_app/paginas_portal_recepcao/portal_recepcao.dart';

class EditarPacientePage extends StatefulWidget {
  final String pacienteId;
  const EditarPacientePage({super.key, required this.pacienteId});

  @override
  State<EditarPacientePage> createState() => _EditarPacientePageState();
}

class _EditarPacientePageState extends State<EditarPacientePage> {
  bool _isLoading = true;
  bool _isSaving = false;

  final _formKey = GlobalKey<FormState>();
  
  // Controladores de texto para os inputs
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _telemovelCtrl;
  late final TextEditingController _moradaCtrl;
  late final TextEditingController _nifCtrl;
  late final TextEditingController _snsCtrl;

  // Variáveis para gerir a lista dinâmica de Seguros de saúde da BD
  List<Map<String, dynamic>> _listaSeguros = [];
  int? _selectedInsuranceId;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController();
    _telemovelCtrl = TextEditingController();
    _moradaCtrl = TextEditingController();
    _nifCtrl = TextEditingController();
    _snsCtrl = TextEditingController();
    _carregarDadosFormulario();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _telemovelCtrl.dispose();
    _moradaCtrl.dispose();
    _nifCtrl.dispose();
    _snsCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosFormulario() async {
    try {
      // 1. Descarrega os seguros disponíveis do sistema para preencher a Dropdown
      final List<dynamic> segurosData = await db.from('insurances').select('id, name').order('name');
      _listaSeguros = List<Map<String, dynamic>>.from(segurosData);

      // 2. Descarrega a informação atual deste utente específico
      final utente = await db.from('users').select('''
        name, phone, address, nif,
        patients ( health_number, insurance_id )
      ''').eq('id', widget.pacienteId).single();

      final pData = utente['patients'];

      if (mounted) {
        setState(() {
          _nomeCtrl.text = utente['name'] ?? '';
          _telemovelCtrl.text = utente['phone'] ?? '';
          _moradaCtrl.text = utente['address'] ?? '';
          _nifCtrl.text = utente['nif'] ?? '';
          _snsCtrl.text = pData?['health_number'] ?? '';
          _selectedInsuranceId = pData?['insurance_id'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar formulário: $e');
    }
  }

  Future<void> _guardarDados() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Passo A: Atualizar a tabela base 'users' (Dados comuns)
      await db.from('users').update({
        'name': _nomeCtrl.text.trim(),
        'phone': _telemovelCtrl.text.trim(),
        'address': _moradaCtrl.text.trim(),
        'nif': _nifCtrl.text.trim(),
      }).eq('id', widget.pacienteId);

      // Passo B: Atualizar a tabela filha 'patients' (Dados médicos específicos)
      await db.from('patients').update({
        'health_number': _snsCtrl.text.trim(),
        'insurance_id': _selectedInsuranceId, // Pode passar nulo se for Particular
      }).eq('user_id', widget.pacienteId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paciente atualizado com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Volta para trás enviando 'true' para sinalizar recarga de lista
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar alterações: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Editar Dados do Utente', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16)),
        elevation: 0, backgroundColor: Colors.white, foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B6BE0)))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nomeCtrl,
                      decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder(), labelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Insira o nome completo' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nifCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'NIF', border: OutlineInputBorder(), labelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                            validator: (v) => v == null || v.trim().length != 9 ? 'NIF Inválido (9 dígitos)' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _snsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Nº Utente SNS', border: OutlineInputBorder(), labelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Insira o número SNS' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _telemovelCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Telemóvel / Telefone', border: OutlineInputBorder(), labelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                    ),
                    const SizedBox(height: 16),
                    
                    // --- Dropdown Dinâmico de Seguros de Saúde ---
                    DropdownButtonFormField<int>(
                      value: _selectedInsuranceId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Plano de Saúde / Seguro', border: OutlineInputBorder(), labelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                      items: [
                        const DropdownMenuItem<int>(value: null, child: Text('Particular (Sem Seguro)', style: TextStyle(fontFamily: 'Poppins', fontSize: 13))),
                        ..._listaSeguros.map((insurance) => DropdownMenuItem<int>(
                              value: insurance['id'] as int,
                              child: Text(insurance['name'].toString(), style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                            )),
                      ],
                      onChanged: (val) => setState(() => _selectedInsuranceId = val),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _moradaCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Morada Completa', border: OutlineInputBorder(), labelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                    ),
                    const SizedBox(height: 32),
                    
                    ElevatedButton(
                      onPressed: _isSaving ? null : _guardarDados,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B6BE0),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Salvar Alterações', style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14)),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}