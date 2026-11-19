import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../config/tema.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _senha = TextEditingController();

  bool _carregando = false;
  bool _mostrarSenha = false;
  String? _erro;

  Future<void> _entrar() async {
    final email = _email.text.trim();
    final senha = _senha.text;

    if (email.isEmpty || senha.isEmpty) {
      setState(() => _erro = 'Informe seu e-mail e sua senha.');
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );
    } on FirebaseAuthException catch (e) {
      var mensagem = 'Não foi possível entrar.';

      if (e.code == 'invalid-credential' ||
          e.code == 'user-not-found' ||
          e.code == 'wrong-password') {
        mensagem = 'E-mail ou senha incorretos.';
      } else if (e.code == 'invalid-email') {
        mensagem = 'O e-mail informado é inválido.';
      } else if (e.code == 'too-many-requests') {
        mensagem = 'Muitas tentativas. Tente novamente mais tarde.';
      } else if (e.code == 'network-request-failed') {
        mensagem = 'Verifique sua conexão com a internet.';
      }

      if (mounted) setState(() => _erro = mensagem);
    } catch (_) {
      if (mounted) setState(() => _erro = 'Erro ao conectar com o servidor.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.content_cut, color: dourado, size: 76),
                  const SizedBox(height: 16),
                  const Text(
                    'ANJO NEGRO',
                    style: TextStyle(
                      color: dourado,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'GESTÃO',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      letterSpacing: 7,
                    ),
                  ),
                  const SizedBox(height: 45),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Acesse sua conta',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _senha,
                    obscureText: !_mostrarSenha,
                    onSubmitted: (_) => _entrar(),
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _mostrarSenha
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _mostrarSenha = !_mostrarSenha);
                        },
                      ),
                    ),
                  ),
                  if (_erro != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _erro!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _carregando ? null : _entrar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dourado,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _carregando
                          ? const CircularProgressIndicator(
                              color: Colors.black,
                            )
                          : const Text(
                              'ENTRAR',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 35),
                  const Text(
                    'BARBEARIA ANJO NEGRO',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
