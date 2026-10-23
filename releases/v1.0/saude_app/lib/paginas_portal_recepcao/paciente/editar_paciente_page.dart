import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../template/template_portal_recepcao.dart';
import 'model/paciente_model.dart';
import 'widgets/aba_dados_view.dart';
import 'widgets/aba_dados_form.dart';
import 'widgets/aba_consultas_list.dart';
import '../gestao_pacientes_page.dart';

class EditarPacientePage extends StatefulWidget {
  const EditarPacientePage({super.key});

  @override
  State<EditarPacientePage> createState() => _EditarPacientePageState();
}

class _EditarPacientePageState extends State<EditarPacientePage> {
  // Qual aba está ativa? 0 = Dados ou 1 = Consultas
  int _abaAtiva = 0;

  // Se estamos em modo de edição ou leitura
  bool _modoEdicao = false;

  final _nomeCtrl = TextEditingController(text: pacienteMock.nome);
  final _nifCtrl = TextEditingController(text: pacienteMock.nif);
  final _dataNascCtrl = TextEditingController(text: pacienteMock.dataNasc);
  final _telCtrl = TextEditingController(text: pacienteMock.telemovel);
  final _snsCtrl = TextEditingController(text: pacienteMock.sns);
  final _emailCtrl = TextEditingController(text: pacienteMock.email);
  final _moradaCtrl = TextEditingController(text: pacienteMock.morada);

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _nifCtrl.dispose();
    _dataNascCtrl.dispose();
    _telCtrl.dispose();
    _snsCtrl.dispose();
    _emailCtrl.dispose();
    _moradaCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    // TODO: guardar na db quando realmente a tivermos
    setState(() => _modoEdicao = false);
  }

  void _cancelar() {
    _nomeCtrl.text = pacienteMock.nome;
    _nifCtrl.text = pacienteMock.nif;
    _dataNascCtrl.text = pacienteMock.dataNasc;
    _telCtrl.text = pacienteMock.telemovel;
    _snsCtrl.text = pacienteMock.sns;
    _emailCtrl.text = pacienteMock.email;
    _moradaCtrl.text = pacienteMock.morada;
    setState(() => _modoEdicao = false);
  }

  void _mudarAba(int index) {
    setState(() {
      _abaAtiva = index;
      // Sair do modo de edição ao mudar de aba
      if (_modoEdicao) _cancelar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePortalRecepcao(
      currentIndex: 1,
      userInitials: 'MC',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildTitulo(),
          const SizedBox(height: 16),
          _buildTabBar(),
          const SizedBox(height: 20),

          if (_abaAtiva == 0 && !_modoEdicao)
            AbaDadosView(
              paciente: pacienteMock,
              onEditarPressed: () => setState(() => _modoEdicao = true),
            ),

          if (_abaAtiva == 0 && _modoEdicao)
            AbaDadosForm(
              nomeCtrl: _nomeCtrl,
              nifCtrl: _nifCtrl,
              dataNascCtrl: _dataNascCtrl,
              telemovelCtrl: _telCtrl,
              snsCtrl: _snsCtrl,
              emailCtrl: _emailCtrl,
              moradaCtrl: _moradaCtrl,
              onGuardar: _guardar,
              onCancelar: _cancelar,
            ),

          if (_abaAtiva == 1) AbaConsultasList(consultas: consultasMock),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const GestaoPacientesPage(),
              ),
            );
          },
          child: const Text(
            '< Voltar atrás',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF3B6BE0),
              fontFamily: 'Poppins',
            ),
          ),
        ),

        if (_abaAtiva == 0)
          GestureDetector(
            onTap: () {
              if (_modoEdicao) {
                _cancelar();
              } else {
                setState(() => _modoEdicao = true);
              }
            },
            child: Row(
              children: [
                if (!_modoEdicao) ...[
                  SvgPicture.asset(
                    'assets/imagens_portal_recepcao/Edit.svg',
                    width: 16,
                    height: 16,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF3B6BE0),
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  _modoEdicao ? 'Cancelar' : 'Editar',
                  style: TextStyle(
                    fontSize: 13,
                    color: _modoEdicao
                        ? Colors.redAccent
                        : const Color(0xFF3B6BE0),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTitulo() {
    return const Text(
      'Ficha do Paciente',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A3B8B),
        fontFamily: 'Poppins',
      ),
    );
  }

  Widget _buildTabBar() {
    return Row(children: [_buildTab('Dados', 0), _buildTab('Consultas', 1)]);
  }

  Widget _buildTab(String label, int index) {
    final bool ativa = _abaAtiva == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _mudarAba(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: ativa ? const Color(0xFF3B6BE0) : Colors.grey.shade300,
                width: 2.0,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ativa ? const Color(0xFF3B6BE0) : Colors.grey.shade500,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }
}
