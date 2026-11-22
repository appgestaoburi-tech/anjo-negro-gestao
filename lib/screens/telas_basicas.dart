import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../config/tema.dart';
import 'configuracoes/configuracoes_screen.dart';

class CarregandoScreen extends StatelessWidget {
  const CarregandoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: dourado)),
    );
  }
}

class AcessoNegadoScreen extends StatelessWidget {
  final String mensagem;

  const AcessoNegadoScreen({super.key, required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, color: dourado, size: 65),
              const SizedBox(height: 20),
              const Text(
                'ACESSO NÃO AUTORIZADO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: dourado,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(mensagem, textAlign: TextAlign.center),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text('VOLTAR AO LOGIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void abrirModulo(BuildContext context, String titulo) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => titulo == 'Configurações'
          ? const ConfiguracoesScreen()
          : ModuloEmConstrucaoScreen(titulo: titulo),
    ),
  );
}

class ModuloEmConstrucaoScreen extends StatelessWidget {
  final String titulo;

  const ModuloEmConstrucaoScreen({super.key, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.construction, color: dourado, size: 65),
              const SizedBox(height: 20),
              Text(
                titulo,
                style: const TextStyle(
                  color: dourado,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Este módulo será disponibilizado '
                'nas próximas etapas do Anjo Negro Gestão.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
