
import 'package:flutter/material.dart';

void main() {
  runApp(const AnjoNegroApp());
}

class AnjoNegroApp extends StatelessWidget {
  const AnjoNegroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Anjo Negro Gestão',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0B0B),
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4AF57),
          brightness: Brightness.dark,
        ),
      ),
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
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool esconderSenha = true;

  final dourado = const Color(0xFFD4AF57);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void entrar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Tela inicial criada! A conexão com o Firebase será a próxima etapa.',
        ),
        backgroundColor: Color(0xFF806329),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 25,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: dourado,
                      width: 2,
                    ),
                    color: const Color(0xFF181818),
                  ),
                  child: Icon(
                    Icons.content_cut,
                    color: dourado,
                    size: 55,
                  ),
                ),

                const SizedBox(height: 25),

                Text(
                  'ANJO NEGRO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: dourado,
                    fontSize: 31,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'GESTÃO',
                  style: TextStyle(
                    color: dourado,
                    fontSize: 18,
                    letterSpacing: 7,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'SISTEMA DE GESTÃO DA BARBEARIA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 48),

                campo(
                  titulo: 'E-MAIL',
                  dica: 'Digite seu e-mail',
                  icone: Icons.email_outlined,
                  controller: emailController,
                ),

                const SizedBox(height: 22),

                campo(
                  titulo: 'SENHA',
                  dica: 'Digite sua senha',
                  icone: Icons.lock_outline,
                  controller: passwordController,
                  senha: true,
                ),

                const SizedBox(height: 35),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: entrar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dourado,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'ENTRAR',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 45),

                const Text(
                  'ANJO NEGRO GESTÃO',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Organização, controle e resultado.',
                  style: TextStyle(
                    color: dourado.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget campo({
    required String titulo,
    required String dica,
    required IconData icone,
    required TextEditingController controller,
    bool senha = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(
            color: dourado,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: controller,
          obscureText: senha && esconderSenha,
          keyboardType: senha
              ? TextInputType.text
              : TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: dica,
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: Icon(icone, color: dourado),
            suffixIcon: senha
                ? IconButton(
                    onPressed: () {
                      setState(() {
                        esconderSenha = !esconderSenha;
                      });
                    },
                    icon: Icon(
                      esconderSenha
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: dourado,
                    ),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFF181818),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF65502B),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: dourado,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
