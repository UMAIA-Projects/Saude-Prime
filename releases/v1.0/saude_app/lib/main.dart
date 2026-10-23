import 'package:flutter/material.dart';
import 'paginas_fluxo_publico/landing_page.dart';
import 'paginas_portal_paciente/dashboard_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://emokyowfdmoodmboleju.supabase.co  ',
    anonKey: 'sb_publishable_HQxRTp39n9l-t2F1r2w8mQ_3B-ptrmJ',
  );

  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saude Prime++',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Poppins'),
      home: const DashboardPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
