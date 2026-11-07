

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color dourado = Color(0xFFD6AD55);
const Color fundo = Color(0xFF101010);
const Color cartao = Color(0xFF1C1C1C);

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
        scaffoldBackgroundColor: fundo,
        colorScheme: const ColorScheme.dark(
          primary: dourado,
          secondary: dourado,
          surface: cartao,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: cartao,
          foregroundColor: dourado,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cartao,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIconColor: dourado,
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
            borderSide: const BorderSide(color: dourado, width: 1.5),
          ),
        ),
      ),
      home: const InicialScreen(),
    );
  }
}

// ==================================================
// INICIALIZAÇÃO E AUTENTICAÇÃO
// ==================================================

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

        final user = snapshot.data;

        if (user == null) {
          return const LoginScreen();
        }

        return PerfilScreen(user: user);
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
        child: CircularProgressIndicator(color: dourado),
      ),
    );
  }
}

// ==================================================
// LOGIN
// ==================================================

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

      if (mounted) setState(() => erro = mensagem);
    } catch (e) {
      if (mounted) {
        setState(() => erro = 'Erro ao conectar com o servidor.');
      }
    } finally {
      if (mounted) setState(() => carregando = false);
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
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: carregando ? null : entrar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dourado,
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

// ==================================================
// PERFIL DO USUÁRIO
// ==================================================

class PerfilScreen extends StatefulWidget {
  final User user;

  const PerfilScreen({super.key, required this.user});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late Future<Map<String, dynamic>> perfilFuture;

  @override
  void initState() {
    super.initState();
    perfilFuture = carregarPerfil();
  }

  Future<Map<String, dynamic>> carregarPerfil() async {
    final documento = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.user.uid)
        .get();

    if (!documento.exists) {
      throw Exception('Cadastro de usuário não encontrado.');
    }

    final dados = documento.data()!;

    String? campoAtivo;

    for (final chave in dados.keys) {
      if (chave.trim() == 'ativo') {
        campoAtivo = chave;
        break;
      }
    }

    final ativo = campoAtivo == null ? null : dados[campoAtivo];

    if (ativo != true) {
      final campos = dados.keys.map((chave) => '"$chave"').join(', ');

      throw Exception(
        'ACESSO BLOQUEADO\n'
        'Campo encontrado: "$campoAtivo"\n'
        'Valor recebido: $ativo\n'
        'Tipo: ${ativo?.runtimeType ?? 'null'}\n'
        'Campos existentes: $campos\n'
        'UID: ${widget.user.uid}',
      );
    }

    final cargo = (dados['cargo'] ?? '').toString().toLowerCase().trim();

    if (!['admin', 'administrador', 'colaborador'].contains(cargo)) {
      throw Exception('Seu perfil não possui um cargo válido.');
    }

    return dados;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: perfilFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CarregandoScreen();
        }

        if (snapshot.hasError) {
          return AcessoNegadoScreen(
            mensagem: snapshot.error.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          );
        }

        if (!snapshot.hasData) {
          return const AcessoNegadoScreen(
            mensagem: 'Não foi possível carregar seu cadastro.',
          );
        }

        final dados = snapshot.data!;

        return PainelScreen(
          nome: (dados['nome'] ?? 'Usuário').toString(),
          cargo: (dados['cargo'] ?? '').toString().toLowerCase().trim(),
          permissaoTotal: dados['permissaoTotal'] == true,
        );
      },
    );
  }
}

// ==================================================
// ACESSO NEGADO
// ==================================================

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

// ==================================================
// PAINEL PRINCIPAL
// ==================================================

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
    final administrador = cargo == 'admin' || cargo == 'administrador';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ANJO NEGRO',
          style: TextStyle(
            color: dourado,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout, color: dourado),
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
                administrador ? 'Administrador' : 'Colaborador',
                style: const TextStyle(color: dourado, fontSize: 14),
              ),
              const SizedBox(height: 25),
              const TextoSecao(titulo: 'VISÃO GERAL'),
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
              const TextoSecao(titulo: 'GESTÃO DA BARBEARIA'),
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
                    titulo: 'Catálogo de serviços',
                    icone: Icons.content_cut,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CatalogoScreen(
                          nomeUsuario: nome,
                          permissaoTotal: permissaoTotal,
                        ),
                      ),
                    ),
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

// ==================================================
// COMPONENTES DO PAINEL
// ==================================================

class TextoSecao extends StatelessWidget {
  final String titulo;

  const TextoSecao({super.key, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Text(
      titulo,
      style: const TextStyle(
        color: dourado,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
  }
}

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
        color: cartao,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF3B3324)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icone, color: dourado, size: 25),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: dourado,
            ),
          ),
          Text(
            titulo,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cartao,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF3B3324)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, color: dourado, size: 32),
            const SizedBox(height: 12),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================
// CATÁLOGO DE SERVIÇOS
// ==================================================

const List<Map<String, dynamic>> servicosIniciais = [
  {
    'nome': 'Corte Freestyle',
    'categoria': 'Principais',
    'preco': 45.0,
    'tipoPreco': 'a_partir',
  },
  {
    'nome': 'Corte de Cabelo',
    'categoria': 'Principais',
    'preco': 35.0,
    'tipoPreco': 'fixo',
  },
  {
    'nome': 'Barba',
    'categoria': 'Principais',
    'preco': 40.0,
    'tipoPreco': 'fixo',
  },
  {
    'nome': 'Cabelo + Barba',
    'categoria': 'Principais',
    'preco': 60.0,
    'tipoPreco': 'fixo',
  },
  {
    'nome': 'Sobrancelha',
    'categoria': 'Adicionais',
    'preco': 10.0,
    'tipoPreco': 'fixo',
  },
  {
    'nome': 'Pezinho',
    'categoria': 'Adicionais',
    'preco': 10.0,
    'tipoPreco': 'fixo',
  },
  {
    'nome': 'Máscara Negra',
    'categoria': 'Adicionais',
    'preco': 30.0,
    'tipoPreco': 'fixo',
  },
  {
    'nome': 'Epilação com Cera',
    'categoria': 'Adicionais',
    'preco': 15.0,
    'tipoPreco': 'fixo',
  },
  {
    'nome': 'Alisamento',
    'categoria': 'Química',
    'preco': 40.0,
    'tipoPreco': 'a_partir',
  },
  {
    'nome': 'Botox',
    'categoria': 'Química',
    'preco': 40.0,
    'tipoPreco': 'a_partir',
  },
  {
    'nome': 'Progressiva',
    'categoria': 'Química',
    'preco': 50.0,
    'tipoPreco': 'a_partir',
  },
  {
    'nome': 'Luzes',
    'categoria': 'Coloração',
    'preco': 70.0,
    'tipoPreco': 'a_partir',
  },
  {
    'nome': 'Descoloração Global',
    'categoria': 'Coloração',
    'preco': 100.0,
    'tipoPreco': 'a_partir',
  },
  {
    'nome': 'Pigmentação (Cabelo)',
    'categoria': 'Coloração',
    'preco': 15.0,
    'tipoPreco': 'fixo',
  },
  {
    'nome': 'Pigmentação (Barba)',
    'categoria': 'Coloração',
    'preco': 15.0,
    'tipoPreco': 'fixo',
  },
];

const List<String> categoriasServicos = [
  'Principais',
  'Adicionais',
  'Química',
  'Coloração',
];

class CatalogoScreen extends StatefulWidget {
  final String nomeUsuario;
  final bool permissaoTotal;

  const CatalogoScreen({
    super.key,
    required this.nomeUsuario,
    required this.permissaoTotal,
  });

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  String categoriaSelecionada = 'Todas';
  bool preparando = false;
  String? erroPreparacao;

  CollectionReference<Map<String, dynamic>> get colecao =>
      FirebaseFirestore.instance.collection('servicos');

  @override
  void initState() {
    super.initState();

    if (widget.permissaoTotal) {
      prepararCatalogoInicial();
    }
  }

  Future<void> prepararCatalogoInicial() async {
    if (preparando) return;

    setState(() {
      preparando = true;
      erroPreparacao = null;
    });

    try {
      final existentes = await colecao.limit(1).get();

      if (existentes.docs.isEmpty) {
        final lote = FirebaseFirestore.instance.batch();

        for (final servico in servicosIniciais) {
          final referencia = colecao.doc();

          lote.set(referencia, {
            ...servico,
            'ativo': true,
            'descricao': '',
            'imagemUrl': '',
            'ordem': servicosIniciais.indexOf(servico),
            'criadoEm': FieldValue.serverTimestamp(),
            'atualizadoEm': FieldValue.serverTimestamp(),
          });
        }

        await lote.commit();
      }
    } catch (e) {
      erroPreparacao =
          'Não foi possível preparar o catálogo. Verifique as regras '
          'de acesso do Firebase.';
    } finally {
      if (mounted) {
        setState(() => preparando = false);
      }
    }
  }

  String formatarPreco(dynamic valor) {
    final numero = (valor as num?)?.toDouble() ?? 0;
    return numero.toStringAsFixed(2).replaceAll('.', ',');
  }

  Future<void> abrirFormulario({
    String? id,
    Map<String, dynamic>? dados,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (_) => FormularioServicoDialog(
        id: id,
        dados: dados,
      ),
    );

    if (resultado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Serviço salvo com sucesso!')),
      );
    }
  }

  Future<void> alterarStatus(
    String id,
    bool ativo,
  ) async {
    try {
      await colecao.doc(id).update({
        'ativo': !ativo,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível alterar o serviço.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CATÁLOGO DE SERVIÇOS'),
        actions: [
          if (widget.permissaoTotal)
            IconButton(
              tooltip: 'Novo serviço',
              icon: const Icon(Icons.add),
              onPressed: () => abrirFormulario(),
            ),
        ],
      ),
      body: Column(
        children: [
          if (widget.permissaoTotal)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFF302719),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: dourado),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'GESTÃO DO CATÁLOGO • ADMINISTRADOR',
                      style: TextStyle(
                        color: dourado,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: categoriaSelecionada,
              decoration: const InputDecoration(
                labelText: 'Filtrar categoria',
                prefixIcon: Icon(Icons.filter_list),
              ),
              items: [
                const DropdownMenuItem(
                  value: 'Todas',
                  child: Text('Todas as categorias'),
                ),
                ...categoriasServicos.map(
                  (categoria) => DropdownMenuItem(
                    value: categoria,
                    child: Text(categoria),
                  ),
                ),
              ],
              onChanged: (valor) {
                if (valor != null) {
                  setState(() => categoriaSelecionada = valor);
                }
              },
            ),
          ),
          if (preparando)
            const LinearProgressIndicator(color: dourado),
          if (erroPreparacao != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                erroPreparacao!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: colecao.orderBy('ordem').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: dourado),
                  );
                }

                if (snapshot.hasError) {
                  debugPrint('ERRO AO CARREGAR CATALOGO: ${snapshot.error}');

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: SelectableText(
                        'ERRO REAL AO CARREGAR OS SERVIÇOS:\n\n'
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }

                final documentos = snapshot.data?.docs ?? [];

                final filtrados = documentos.where((documento) {
                  final dados = documento.data();
                  final categoria = dados['categoria'] ?? '';
                  final ativo = dados['ativo'] == true;

                  if (!ativo) return false;

                  return categoriaSelecionada == 'Todas' ||
                      categoria == categoriaSelecionada;
                }).toList();

                if (filtrados.isEmpty) {
                  return const Center(
                    child: Text('Nenhum serviço encontrado.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final documento = filtrados[index];
                    final dados = documento.data();

                    final nome = (dados['nome'] ?? '').toString();
                    final categoria =
                        (dados['categoria'] ?? '').toString();
                    final preco = formatarPreco(dados['preco']);
                    final aPartir = dados['tipoPreco'] == 'a_partir';

                    return Card(
                      color: cartao,
                      margin: const EdgeInsets.only(bottom: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                        side: const BorderSide(
                          color: Color(0xFF3B3324),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ),
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF302719),
                          child: Icon(
                            Icons.content_cut,
                            color: dourado,
                          ),
                        ),
                        title: Text(
                          nome,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          categoria,
                          style: const TextStyle(
                            color: Colors.white54,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'R\$ $preco',
                                  style: const TextStyle(
                                    color: dourado,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (aPartir)
                                  const Text(
                                    'A partir de',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                            if (widget.permissaoTotal)
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white70,
                                ),
                                onSelected: (opcao) {
                                  if (opcao == 'editar') {
                                    abrirFormulario(
                                      id: documento.id,
                                      dados: dados,
                                    );
                                  } else if (opcao == 'desativar') {
                                    alterarStatus(
                                      documento.id,
                                      dados['ativo'] == true,
                                    );
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'editar',
                                    child: Text('Editar serviço'),
                                  ),
                                  PopupMenuItem(
                                    value: 'desativar',
                                    child: Text('Desativar serviço'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.permissaoTotal
          ? FloatingActionButton.extended(
              backgroundColor: dourado,
              foregroundColor: Colors.black,
              onPressed: () => abrirFormulario(),
              icon: const Icon(Icons.add),
              label: const Text('NOVO SERVIÇO'),
            )
          : null,
    );
  }
}

// ==================================================
// FORMULÁRIO DE CADASTRO E EDIÇÃO
// ==================================================

class FormularioServicoDialog extends StatefulWidget {
  final String? id;
  final Map<String, dynamic>? dados;

  const FormularioServicoDialog({
    super.key,
    this.id,
    this.dados,
  });

  @override
  State<FormularioServicoDialog> createState() =>
      _FormularioServicoDialogState();
}

class _FormularioServicoDialogState
    extends State<FormularioServicoDialog> {
  final nomeController = TextEditingController();
  final precoController = TextEditingController();
  final descricaoController = TextEditingController();

  String categoria = 'Principais';
  String tipoPreco = 'fixo';
  bool salvando = false;

  @override
  void initState() {
    super.initState();

    final dados = widget.dados;

    if (dados != null) {
      nomeController.text = (dados['nome'] ?? '').toString();
      precoController.text = (dados['preco'] ?? '').toString();
      descricaoController.text =
          (dados['descricao'] ?? '').toString();
      categoria = (dados['categoria'] ?? 'Principais').toString();
      tipoPreco = (dados['tipoPreco'] ?? 'fixo').toString();
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    precoController.dispose();
    descricaoController.dispose();
    super.dispose();
  }

  Future<void> salvar() async {
    final nome = nomeController.text.trim();
    final precoTexto = precoController.text.trim().replaceAll(',', '.');
    final preco = double.tryParse(precoTexto);

    if (nome.isEmpty || preco == null || preco <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o nome e um preço válido.'),
        ),
      );
      return;
    }

    setState(() => salvando = true);

    try {
      final colecao =
          FirebaseFirestore.instance.collection('servicos');

      final dados = <String, dynamic>{
        'nome': nome,
        'categoria': categoria,
        'preco': preco,
        'tipoPreco': tipoPreco,
        'descricao': descricaoController.text.trim(),
        'ativo': widget.dados?['ativo'] ?? true,
        'imagemUrl': widget.dados?['imagemUrl'] ?? '',
        'atualizadoEm': FieldValue.serverTimestamp(),
      };

      if (widget.id == null) {
        dados['ordem'] = DateTime.now().millisecondsSinceEpoch;
        dados['criadoEm'] = FieldValue.serverTimestamp();
        await colecao.add(dados);
      } else {
        await colecao.doc(widget.id).update(dados);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível salvar. Confira as permissões do Firebase.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: cartao,
      title: Text(
        widget.id == null ? 'Novo serviço' : 'Editar serviço',
        style: const TextStyle(color: dourado),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do serviço',
                  prefixIcon: Icon(Icons.content_cut),
                ),
              ),
              const SizedBox(height: 13),
              DropdownButtonFormField<String>(
                value: categoria,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                ),
                items: categoriasServicos.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (valor) {
                  if (valor != null) setState(() => categoria = valor);
                },
              ),
              const SizedBox(height: 13),
              TextField(
                controller: precoController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Preço (R\$)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 13),
              DropdownButtonFormField<String>(
                value: tipoPreco,
                decoration: const InputDecoration(
                  labelText: 'Tipo de preço',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'fixo',
                    child: Text('Preço fixo'),
                  ),
                  DropdownMenuItem(
                    value: 'a_partir',
                    child: Text('A partir de'),
                  ),
                ],
                onChanged: (valor) {
                  if (valor != null) setState(() => tipoPreco = valor);
                },
              ),
              const SizedBox(height: 13),
              TextField(
                controller: descricaoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'A inclusão de fotos será habilitada em uma próxima etapa.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: salvando
              ? null
              : () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: salvando ? null : salvar,
          style: ElevatedButton.styleFrom(
            backgroundColor: dourado,
            foregroundColor: Colors.black,
          ),
          child: salvando
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Text('SALVAR'),
        ),
      ],
    );
  }
}

// ==================================================
// MÓDULOS PROVISÓRIOS
// ==================================================

void abrirModulo(BuildContext context, String titulo) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ModuloEmConstrucaoScreen(titulo: titulo),
    ),
  );
}

class ModuloEmConstrucaoScreen extends StatelessWidget {
  final String titulo;

  const ModuloEmConstrucaoScreen({
    super.key,
    required this.titulo,
  });

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
              const Icon(
                Icons.construction,
                color: dourado,
                size: 65,
              ),
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
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
