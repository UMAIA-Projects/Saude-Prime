import 'package:flutter/material.dart';
import 'template/template_fluxo_publico.dart';
import 'login_page.dart';
import 'create_acc_2_page.dart';

class CreateAccScreen1 extends StatelessWidget {
  const CreateAccScreen1({super.key});

  static const Color _verde = Color.fromRGBO(100, 215, 138, 1);

  InputDecoration _inputDecoration(IconData icon, String hint) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: _verde, size: 20),
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 14,
        fontFamily: 'Poppins',
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color.fromRGBO(100, 215, 138, 1), width: 1.5),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color.fromRGBO(100, 215, 138, 1), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TemplateFluxoPublico(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 16, 26, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Voltar atrás
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
              child: const Text(
                '< Voltar atrás',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color.fromRGBO(100, 215, 138, 1),
                  decoration: TextDecoration.underline,
                  decorationColor: Color.fromRGBO(100, 215, 138, 1),
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Criar Conta (1/2)',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 20),

            // Nome Completo
            const Text(
              'Nome Completo',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            TextField(
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              decoration: _inputDecoration(Icons.person_outline, 'Digite o seu nome completo...'),
              cursorColor: _verde,
            ),

            const SizedBox(height: 20),

            // NIF + Data de Nascimento
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NIF',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      TextField(
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                        decoration: _inputDecoration(Icons.credit_card_outlined, '123456789'),
                        cursorColor: _verde,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Data de Nascimento',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      _DatePickerField(verde: _verde),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Nº Telemóvel + Nº Utente Saúde
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nº Telemóvel',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      TextField(
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                        decoration: _inputDecoration(Icons.phone_outlined, '9XX XXX XXX'),
                        cursorColor: _verde,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nº Utente Saúde',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      TextField(
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                        decoration: _inputDecoration(Icons.tag, '000000000'),
                        cursorColor: _verde,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Morada
            const Text(
              'Morada',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            TextField(
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              decoration: _inputDecoration(Icons.home_outlined, 'Rua, nº, cidade, ...'),
              cursorColor: _verde,
            ),

            const SizedBox(height: 28),

            // Continuar
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateAccScreen2())),
                child: const Text(
                  'Continuar >',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color.fromRGBO(100, 215, 138, 1),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Widget auxiliar: campo de data com date picker flutter
class _DatePickerField extends StatefulWidget {
  final Color verde;
  const _DatePickerField({required this.verde});

  @override
  State<_DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<_DatePickerField> {
  DateTime? _selectedDate;

  String get _label {
    if (_selectedDate == null) return 'dd/mm/aaaa';
    final d = _selectedDate!;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.verde,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: widget.verde),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: widget.verde, width: 1.5)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, color: widget.verde, size: 20),
            const SizedBox(width: 8),
            Text(
              _label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: _selectedDate == null ? Colors.grey.shade400 : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}