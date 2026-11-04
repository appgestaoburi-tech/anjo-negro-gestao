
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      debugShowCheckedModeBanner: false,
      title: 'Anjo Negro Gestão',
      theme: ThemeData.dark(),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final senha = TextEditingController();

  bool carregando = false;
  String resultado = '';

  Future<void> diagnosticar() async {
    setState(() {
      carregando = true;
      resultado = 'Verificando conexão...';
    });

    try {
      // ETAPA 1: AUTENTICAÇÃO
      final credencial = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email.text.trim(),
        password: senha.text,
      );

      final usuario = credencial.user!;

      final app = Firebase.app();
      final firestore = FirebaseFirestore.instance;

      final caminho = 'usuarios/${usuario.uid}';

      // ETAPA 2: LEITURA DO DOCUMENTO INDIVIDUAL
      String resultadoDocumento;
      bool documentoExiste = false;

      try {
        final documento = await firestore
            .collection('usuarios')
            .doc(usuario.uid)
            .get(const GetOptions(source: Source.server));

        documentoExiste = documento.exists;

        resultadoDocumento = documentoExiste
            ? 'DOCUMENTO INDIVIDUAL: ENCONTRADO'
            : 'DOCUMENTO INDIVIDUAL: NÃO ENCONTRADO';

        if (documentoExiste) {
          resultadoDocumento +=
              '\nDADOS: ${documento.data()}';
        }
      } on FirebaseException catch (e) {
        resultadoDocumento =
            'ERRO NA LEITURA INDIVIDUAL: ${e.code}\n${e.message}';
      }

      // ETAPA 3: LISTAGEM DA COLEÇÃO
      String resultadoLista;

      try {
        final quantidade = await firestore
            .collection('usuarios')
            .get(const GetOptions(source: Source.server));

        resultadoLista =
            'LISTAGEM: PERMITIDA (${quantidade.docs.length} documentos)';
      } on FirebaseException catch (e) {
        resultadoLista =
            'LISTAGEM BLOQUEADA: ${e.code}\n${e.message}';
      }

      // ETAPA 4: MOSTRAR RESULTADO
      final dados = StringBuffer();

      dados.writeln('AUTENTICAÇÃO: OK');
      dados.writeln('');
      dados.writeln('PROJETO: ${app.options.projectId}');
      dados.writeln('APP: ${app.options.appId}');
      dados.writeln('BANCO: (default)');
      dados.writeln('');
      dados.writeln('UID: ${usuario.uid}');
      dados.writeln('CAMINHO: $caminho');
      dados.writeln('');
      dados.writeln(resultadoDocumento);
      dados.writeln('');
      dados.writeln(resultadoLista);

      if (mounted) {
        setState(() {
          resultado = dados.toString();
        });
      }
    } on FirebaseAuthException catch (e) {
      resultado =
          'ERRO DE AUTENTICAÇÃO\n${e.code}\n${e.message}';
    } on FirebaseException catch (e) {
      resultado =
          'ERRO FIREBASE\nCÓDIGO: ${e.code}\nMENSAGEM: ${e.message}';
    } catch (e) {
      resultado = 'ERRO GERAL\n$e';
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    email.dispose();
    senha.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ANJO NEGRO GESTÃO'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.content_cut,
              size: 65,
              color: Color(0xFFD4AF57),
            ),
            const SizedBox(height: 20),
            const Text(
              'DIAGNÓSTICO DE ACESSO',
              style: TextStyle(
                color: Color(0xFFD4AF57),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: senha,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Senha',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: carregando ? null : diagnosticar,
                child: carregando
                    ? const CircularProgressIndicator()
                    : const Text('EXECUTAR DIAGNÓSTICO'),
              ),
            ),
            const SizedBox(height: 25),
            if (resultado.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(
                    color: const Color(0xFFD4AF57),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SelectableText(
                  resultado,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
