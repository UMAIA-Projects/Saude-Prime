import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'paginas_fluxo_publico/landing_page.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Versão 0.0: Chaves hardcoded diretamente no código, nesta altura do projeto não tinhamos ainda chamada para o supabase porque ainda estavamos a decidir como implementar a DB no flutter (apesar da lógica da mesma já estar escrita)
  await Supabase.initialize(
    url: 'https://emokyowfdmoodmboleju.supabase.co',
    anonKey: 'sb_publishable_HQxRTp39n9l-t2F1r2w8mQ_3B-ptrmJ',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saúde Prime++',
      theme: ThemeData(
        primarySwatch: Colors.blue, 
        fontFamily: 'Poppins',
      ),
      home: const LandingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}