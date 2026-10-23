import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:saude_app/paginas_fluxo_publico/fluxo_publico.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      title: 'Saude Prime++',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Poppins'),
      locale: const Locale('pt', 'PT'),
      supportedLocales: const [
        Locale('pt', 'PT'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const LandingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
