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
  late Future> perfilFuture;

  @override
  void initState() {
    super.initState();
    perfilFuture = carregarPerfil();
  }

  Future> carregarPerfil() async {
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
    return FutureBuilder>(
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

  void abrirModulo(BuildContext context, String nomeModulo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Módulo "$nomeModulo" em desenvolvimento.')),
    );
  }

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

const List> servicosIniciais = [
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

  CollectionReference> get colecao =>
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
      final uidUser = FirebaseAuth.instance.currentUser?.uid ?? 'desconhecido';
      debugPrint('DEBUG - UID Autenticado: $uidUser');
      debugPrint('DEBUG - Permissão Total do Admin: ${widget.permissaoTotal}');

      final existentes = await colecao.limit(1).get();
      debugPrint('DEBUG - Consulta executada. Documentos encontrados: ${existentes.docs.length}');

      if (existentes.docs.isEmpty) {
        debugPrint('DEBUG - Coleção vazia. Cadastrando os 15 serviços iniciais...');
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
        debugPrint('DEBUG - 15 serviços cadastrados com sucesso no Firestore!');
      }
    } catch (e, stackTrace) {
      debugPrint('ERRO REAL NO FIREBASE (CATÁLOGO): $e');
      debugPrint('$stackTrace');
      if (mounted) {
        setState(() {
          erroPreparacao = 'Erro detalhado do Firebase:\n$e';
        });
      }
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

  Future<void> alterarStatus(String id, bool ativo) async {
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
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(color: dourado),
            ),
          if (erroPreparacao != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: SelectableText(
                  erroPreparacao!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>>(
              stream: categoriaSelecionada == 'Todas'
                  ? colecao.orderBy('ordem').snapshots()
                  : colecao
                      .where('categoria', isEqualTo: categoriaSelecionada)
                      .orderBy('ordem')
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: dourado),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: SelectableText(
                        'Erro ao carregar serviços:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  );
                }

                final documentos = snapshot.data?.docs ?? [];

                if (documentos.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum serviço cadastrado.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: documentos.length,
                  itemBuilder: (context, index) {
                    final doc = documentos[index];
                    final dados = doc.data();
                    final id = doc.id;
                    final nome = dados['nome'] ?? '';
                    final categoria = dados['categoria'] ?? '';
                    final preco = dados['preco'] ?? 0;
                    final tipoPreco = dados['tipoPreco'] ?? 'fixo';
                    final ativo = dados['ativo'] ?? true;

                    return Card(
                      color: cartao,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFF3B3324)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        title: Text(
                          nome,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: ativo ? Colors.white : Colors.white38,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text(
                              'Categoria: $categoria',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'R\$ ${formatarPreco(preco)}${tipoPreco == 'a_partir' ? ' a partir' : ''}',
                              style: const TextStyle(
                                color: dourado,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        trailing: widget.permissaoTotal
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      ativo
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: ativo ? dourado : Colors.white38,
                                    ),
                                    tooltip: ativo ? 'Desativar' : 'Ativar',
                                    onPressed: () =>
                                        alterarStatus(id, ativo),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.white70),
                                    tooltip: 'Editar',
                                    onPressed: () => abrirFormulario(
                                      id: id,
                                      dados: dados,
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================
// DIALOG DE FORMULÁRIO DE SERVIÇO
// ==================================================

class FormularioServicoDialog extends StatefulWidget {
  final String? id;
  final Map<String, dynamic>? dados;

  const FormularioServicoDialog({super.key, this.id, this.dados});

  @override
  State<FormularioServicoDialog> createState() =>
      _FormularioServicoDialogState();
}

class _FormularioServicoDialogState extends State<FormularioServicoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nomeController;
  late TextEditingController precoController;
  String categoriaSelecionada = 'Principais';
  String tipoPrecoSelecionado = 'fixo';
  bool salvando = false;

  @override
  void initState() {
    super.initState();
    nomeController = TextEditingController(text: widget.dados?['nome'] ?? '');
    precoController = TextEditingController(
      text: widget.dados?['preco'] != null
          ? widget.dados!['preco'].toString()
          : '',
    );
    if (widget.dados?['categoria'] != null &&
        categoriasServicos.contains(widget.dados!['categoria'])) {
      categoriaSelecionada = widget.dados!['categoria'];
    }
    if (widget.dados?['tipoPreco'] != null) {
      tipoPrecoSelecionado = widget.dados!['tipoPreco'];
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    precoController.dispose();
    super.dispose();
  }
  

  Future<void> salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => salvando = true);

    try {
      final preco = double.tryParse(
            precoController.text.replaceAll(',', '.'),
          ) ??
          0.0;
      final colecao = FirebaseFirestore.instance.collection('servicos');

      if (widget.id == null) {
        final totalDocs = await colecao.get();
        await colecao.add({
          'nome': nomeController.text.trim(),
          'categoria': categoriaSelecionada,
          'preco': preco,
          'tipoPreco': tipoPrecoSelecionado,
          'ativo': true,
          'descricao': '',
          'imagemUrl': '',
          'ordem': totalDocs.docs.length,
          'criadoEm': FieldValue.serverTimestamp(),
          'atualizadoEm': FieldValue.serverTimestamp(),
        });
      } else {
        await colecao.doc(widget.id).update({
          'nome': nomeController.text.trim(),
          'categoria': categoriaSelecionada,
          'preco': preco,
          'tipoPreco': tipoPrecoSelecionado,
          'atualizadoEm': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar serviço: $e')),
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
        widget.id == null ? 'Novo Serviço' : 'Editar Serviço',
        style: const TextStyle(color: dourado),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome do serviço'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: categoriaSelecionada,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: categoriasServicos
                    .map(
                      (cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setState(() => categoriaSelecionada = v ?? 'Principais'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: precoController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Preço (R\$)',
                  prefixText: 'R\$ ',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Informe o preço';
                  if (double.tryParse(v.replaceAll(',', '.')) == null) {
                    return 'Valor inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: tipoPrecoSelecionado,
                decoration: const InputDecoration(labelText: 'Tipo de Preço'),
                items: const [
                  DropdownMenuItem(value: 'fixo', child: Text('Preço Fixo')),
                  DropdownMenuItem(
                    value: 'a_partir',
                    child: Text('A partir de'),
                  ),
                ],
                onChanged: (v) =>
                    setState(() => tipoPrecoSelecionado = v ?? 'fixo'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: salvando ? null : () => Navigator.pop(context),
          child: const Text('CANCELAR', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: dourado,
            foregroundColor: Colors.black,
          ),
          onPressed: salvando ? null : salvar,
          child: salvando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                ),
              : const Text('SALVAR', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
