import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'config/tema.dart';
import 'screens/inicial_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AnjoNegroApp());
}

class AnjoNegroApp extends StatelessWidget {
  const AnjoNegroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anjo Negro Gestão',
      debugShowCheckedModeBanner: false,
      theme: criarTema(),
      home: const InicialScreen(),
    );
  }
}
