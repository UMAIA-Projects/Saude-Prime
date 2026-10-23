import 'package:saude_app/paginas_portal_admin/portal_admin.dart';

class SendNewsletterPage extends StatefulWidget {
  const SendNewsletterPage({super.key});

  @override
  State<SendNewsletterPage> createState() => _SendNewsletterPageState();
}

class _SendNewsletterPageState extends State<SendNewsletterPage> {
  final _subjectController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSending = false;

  static const Color _pink         = Color(0xFFD4537E);

  @override
  void dispose() {
    _subjectController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String _buildHtmlTemplate(String message) {
    final formattedMessage = message.replaceAll('\n', '<br>');
    return '''
    <div style="font-family: 'Arial', sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #E0ECEB; border-radius: 10px; overflow: hidden;">
      <div style="background-color: #1A8070; padding: 20px; text-align: center;">
        <h1 style="color: white; margin: 0;">Saúde Prime ++</h1>
      </div>
      <div style="padding: 30px; background-color: #FAFAFA; color: #333333; line-height: 1.6;">
        <h2 style="color: #1A8070;">Olá!</h2>
        <p>$formattedMessage</p>
      </div>
      <div style="background-color: #D5E2E3; padding: 15px; text-align: center; font-size: 12px; color: #787878;">
        <p>Recebeu este e-mail porque ativou a subscrição da Newsletter no seu portal.</p>
        <p>Equipa Saúde Prime ++ | 2026</p>
      </div>
    </div>
    ''';
  }

  Future<void> _dispararNewsletter() async {
    final subject = _subjectController.text.trim();
    final content = _contentController.text.trim();

    if (subject.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preenche o assunto e a mensagem.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final htmlMockup = _buildHtmlTemplate(content);
      final response = await Supabase.instance.client.functions.invoke(
        'send-newsletter',
        body: {
          'subject': subject,
          'html_content': htmlMockup,
        },
      );

      if (mounted) {
        if (response.data != null && response.data is Map && response.data['error'] != null) {
          throw Exception(response.data['error']);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Newsletter disparada com sucesso!'),
            backgroundColor: Color(0xFF1A8070),
            duration: Duration(seconds: 4),
          ),
        );
        _subjectController.clear();
        _contentController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePortalAdmin(
      currentIndex: 4,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nova Campanha',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: _pink),
            ),
            const SizedBox(height: 8),
            const Text(
              'A mensagem será enviada para todos os utentes subscritos.',
              style: TextStyle(color: Colors.grey, fontFamily: 'Poppins', fontSize: 13),
            ),
            const SizedBox(height: 30),
            const Text('Assunto do E-mail', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                hintText: 'Ex: Novas campanhas de rastreio...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A8070), width: 2)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Mensagem', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Escreva aqui o conteúdo da newsletter...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A8070), width: 2)),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSending ? null : _dispararNewsletter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Enviar Newsletter',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}