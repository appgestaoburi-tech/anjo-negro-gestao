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
      title: 'Anjo Negro Gestão',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF101010),
        primaryColor: const Color(0xFFD6AD55),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD6AD55),
          secondary: Color(0xFFD6AD55),
          surface: Color(0xFF1C1C1C),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF222222),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF383838)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFD6AD55),
              width: 1.5,
            ),
          ),
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIconColor: const Color(0xFFD6AD55),
        ),
      ),
      home: const InicialScreen(),
    );
  }
}

// --------------------------------------------------
// CONTROLE INICIAL DE AUTENTICAÇÃO
// --------------------------------------------------

class InicialScreen extends StatelessWidget {
  const InicialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CarregandoScreen();
        }

        if (snapshot.data == null) {
          return const LoginScreen();
        }

        return PerfilScreen(user: snapshot.data!);
      },
    );
  }
}

class CarregandoScreen extends StatelessWidget {
  const CarregandoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFD6AD55),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// LOGIN
// --------------------------------------------------

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final senhaController = TextEditingController();

  bool carregando = false;
  bool mostrarSenha = false;
  String? erro;

  Future<void> entrar() async {
    final email = emailController.text.trim();
    final senha = senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      setState(() => erro = 'Informe seu e-mail e sua senha.');
      return;
    }

    setState(() {
      carregando = true;
      erro = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );
    } on FirebaseAuthException catch (e) {
      String mensagem = 'Não foi possível entrar.';

      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential') {
        mensagem = 'E-mail ou senha incorretos.';
      } else if (e.code == 'wrong-password') {
        mensagem = 'Senha incorreta.';
      } else if (e.code == 'invalid-email') {
        mensagem = 'E-mail inválido.';
      } else if (e.code == 'too-many-requests') {
        mensagem = 'Muitas tentativas. Tente novamente mais tarde.';
      } else if (e.code == 'network-request-failed') {
        mensagem = 'Verifique sua conexão com a internet.';
      }

      if (mounted) {
        setState(() => erro = mensagem);
      }
    } catch (e) {
      if (mounted) {
        setState(() => erro = 'Erro ao conectar. Verifique sua internet.');
      }
    } finally {
      if (mounted) {
        setState(() => carregando = false);
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
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
                  const Icon(
                    Icons.content_cut,
                    size: 75,
                    color: Color(0xFFD6AD55),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'ANJO NEGRO',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: Color(0xFFD6AD55),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'GESTÃO',
                    style: TextStyle(
                      fontSize: 15,
                      letterSpacing: 7,
                      color: Colors.white70,
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
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: senhaController,
                    obscureText: !mostrarSenha,
                    onSubmitted: (_) => entrar(),
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          mostrarSenha
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => mostrarSenha = !mostrarSenha);
                        },
                      ),
                    ),
                  ),
                  if (erro != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      erro!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: carregando ? null : entrar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD6AD55),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: carregando
                          ? const CircularProgressIndicator(
                              color: Colors.black,
                            )
                          : const Text(
                              'ENTRAR',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
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

// --------------------------------------------------
// VERIFICAÇÃO DO PERFIL NO FIRESTORE
// --------------------------------------------------

class PerfilScreen extends StatelessWidget {
  final User user;

  const PerfilScreen({super.key, required this.user});

  Future<Map<String, dynamic>> carregarPerfil() async {
    final documento = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();

    if (!documento.exists) {
      throw Exception('Seu cadastro não foi encontrado.');
    }

    final dados = documento.data()!;

    if (dados['ativo'] != true) {
      throw Exception('Seu acesso está desativado.');
    }

    final cargo = (dados['cargo'] ?? '').toString().toLowerCase();

    if (cargo != 'admin' &&
        cargo != 'administrador' &&
        cargo != 'colaborador') {
      throw Exception('Seu perfil não possui um cargo válido.');
    }

    return dados;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: carregarPerfil(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CarregandoScreen();
        }

        if (snapshot.hasError) {
          return AcessoNegadoScreen(
            mensagem: snapshot.error.toString().replaceFirst('Exception: ', ''),
          );
        }

        final dados = snapshot.data!;
        final cargo = (dados['cargo'] ?? '').toString().toLowerCase();
        final nome = (dados['nome'] ?? 'Usuário').toString();
        final permissaoTotal = dados['permissaoTotal'] == true;

        return PainelScreen(
          nome: nome,
          cargo: cargo,
          permissaoTotal: permissaoTotal,
        );
      },
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
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                color: Color(0xFFD6AD55),
                size: 65,
              ),
              const SizedBox(height: 20),
              const Text(
                'ACESSO NÃO AUTORIZADO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFD6AD55),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                mensagem,
                textAlign: TextAlign.center,
              ),
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

// --------------------------------------------------
// PAINEL ADMINISTRATIVO
// --------------------------------------------------

class PainelScreen extends StatelessWidget {
  final String nome;
  final String cargo;
  final bool permissaoTotal;

  const PainelScreen({
    super.key,
    required this.nome,
    required this.cargo,
    required this.permissaoTotal,
  });

  @override
  Widget build(BuildContext context) {
    final primeiroNome = nome.trim().split(' ').first;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF191919),
        title: const Text(
          'ANJO NEGRO',
          style: TextStyle(
            color: Color(0xFFD6AD55),
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout, color: Color(0xFFD6AD55)),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, $primeiroNome!',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                cargo == 'admin' ? 'Administrador' : 'Colaborador',
                style: const TextStyle(
                  color: Color(0xFFD6AD55),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 25),

              const Text(
                'VISÃO GERAL',
                style: TextStyle(
                  color: Color(0xFFD6AD55),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 13),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: const [
                  IndicadorCard(
                    titulo: 'Entradas do dia',
                    valor: '—',
                    icone: Icons.attach_money,
                  ),
                  IndicadorCard(
                    titulo: 'Comandas abertas',
                    valor: '—',
                    icone: Icons.receipt_long,
                  ),
                  IndicadorCard(
                    titulo: 'Clientes atendidos',
                    valor: '—',
                    icone: Icons.people_outline,
                  ),
                  IndicadorCard(
                    titulo: 'Resultado estimado',
                    valor: '—',
                    icone: Icons.trending_up,
                  ),
                ],
              ),

              const SizedBox(height: 28),
              const Text(
                'GESTÃO DA BARBEARIA',
                style: TextStyle(
                  color: Color(0xFFD6AD55),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 13),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  ModuloCard(
                    titulo: 'Nova comanda',
                    icone: Icons.add_shopping_cart,
                    onTap: () => abrirModulo(context, 'Nova comanda'),
                  ),
                  ModuloCard(
                    titulo: 'Clientes',
                    icone: Icons.people,
                    onTap: () => abrirModulo(context, 'Clientes'),
                  ),
                  ModuloCard(
                    titulo: 'Estoque',
                    icone: Icons.inventory_2_outlined,
                    onTap: () => abrirModulo(context, 'Estoque'),
                  ),
                  ModuloCard(
                    titulo: 'Caixa',
                    icone: Icons.point_of_sale,
                    onTap: () => abrirModulo(context, 'Caixa'),
                  ),
                  ModuloCard(
                    titulo: 'Relatórios',
                    icone: Icons.bar_chart,
                    onTap: () => abrirModulo(context, 'Relatórios'),
                  ),
                  if (permissaoTotal)
                    ModuloCard(
                      titulo: 'Configurações',
                      icone: Icons.settings,
                      onTap: () => abrirModulo(context, 'Configurações'),
                    ),
                ],
              ),
              const SizedBox(height: 25),
              const Center(
                child: Text(
                  'ANJO NEGRO GESTÃO',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 11,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// COMPONENTES VISUAIS
// --------------------------------------------------

class IndicadorCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;

  const IndicadorCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF3B3324)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icone, color: const Color(0xFFD6AD55), size: 25),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD6AD55),
            ),
          ),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class ModuloCard extends StatelessWidget {
  final String titulo;
  final IconData icone;
  final VoidCallback onTap;

  const ModuloCard({
    super.key,
    required this.titulo,
    required this.icone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
 
