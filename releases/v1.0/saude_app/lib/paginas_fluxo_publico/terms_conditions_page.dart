import 'package:flutter/material.dart';
import 'package:saude_app/paginas_fluxo_publico/template/template_fluxo_publico.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TemplateFluxoPublico(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.chevron_left,
                    color: Color(0xFF64D68A),
                    size: 18,
                  ),
                  Text(
                    'Voltar atrás',
                    style: TextStyle(
                      color: Color(0xFF64D68A),
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFF64D68A),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Termos e\nCondições',
              style: TextStyle(
                color: Colors.black,
                fontSize: 40,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Estes Termos e Condições regem a utilização desta aplicação clínica, '
              'desenvolvida exclusivamente para fins académicos e de avaliação no âmbito '
              'da unidade curricular de Engenharia de Software. Ao utilizar este sistema, '
              'o utilizador compreende e aceita que se trata de um protótipo, pelo que '
              'qualquer informação, diagnóstico ou dado clínico gerado é estritamente '
              'simulado e não substitui, em circunstância alguma, o aconselhamento médico '
              'profissional.',
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.80),
                fontSize: 10,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w300,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Todos os dados inseridos na plataforma destinam-se apenas a efeitos de '
              'demonstração técnica e testes do projeto. A equipa de desenvolvimento não '
              'assume qualquer responsabilidade por falhas no sistema, perda de informações '
              'ou uso indevido da aplicação, garantindo que os dados recolhidos não serão '
              'partilhados com terceiros nem utilizados para fins comerciais.',
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.80),
                fontSize: 10,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w300,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}