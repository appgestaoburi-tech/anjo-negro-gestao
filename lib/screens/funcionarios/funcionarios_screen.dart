import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../config/catalogo_inicial.dart';
import '../../config/permissoes.dart';
import '../../config/tema.dart';
import '../../models/funcionario.dart';
import '../../models/perfil_usuario.dart';
import '../../repositories/funcionario_repository.dart';
import '../../utils/percentual.dart';

class FuncionariosScreen extends StatefulWidget {
  final PerfilUsuario perfil;

  const FuncionariosScreen({super.key, required this.perfil});

  @override
  State<FuncionariosScreen> createState() => _FuncionariosScreenState();
}

class _FuncionariosScreenState extends State<FuncionariosScreen> {
  final _repo = FuncionarioRepository();

  Future<void> _abrirFormulario({Funcionario? funcionario}) async {
    final resultado = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FormularioFuncionario(
        repo: _repo,
        funcionario: funcionario,
      ),
    );

    if (resultado == null || !mounted) return;

    if (resultado.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Funcionário atualizado.')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cartao,
        title: const Text('Login criado', style: TextStyle(color: dourado)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('O funcionário entra no app com este e-mail:'),
            const SizedBox(height: 10),
            SelectableText(
              resultado,
              style: const TextStyle(
                color: dourado,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'A senha é a que você acabou de definir. '
              'Anote o e-mail e repasse os dois ao funcionário.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: dourado,
              foregroundColor: Colors.black,
            ),
            child: const Text('ENTENDI'),
          ),
        ],
      ),
    );
  }

  Future<void> _alterarAtivo(Funcionario f) async {
    try {
      await _repo.definirAtivo(f.uid, !f.ativo);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível alterar o funcionário.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FUNCIONÁRIOS')),
      body: StreamBuilder<List<Funcionario>>(
        stream: _repo.observar(),
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
                  'Erro ao carregar os funcionários:\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          }

          final lista = snapshot.data ?? [];

          if (lista.isEmpty) {
            return const Center(child: Text('Nenhum funcionário cadastrado.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: lista.length,
            itemBuilder: (context, i) => _item(lista[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: dourado,
        foregroundColor: Colors.black,
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.person_add),
        label: const Text('NOVO FUNCIONÁRIO'),
      ),
    );
  }

  Widget _item(Funcionario f) {
    // O administrador principal não é editado por aqui, para evitar bloqueio.
    final protegido = f.permissaoTotal;
    final semProdutos = !protegido && f.comissaoProdutosBp == null;

    final linhaComissao = protegido
        ? 'Sem comissão'
        : 'Serviços ${f.comissaoTexto}'
            '${f.comissaoCategoriasBp.isEmpty ? '' : ' (+${f.comissaoCategoriasBp.length} exceção)'}'
            ' • Produtos ${f.comissaoProdutosTexto}';

    return Opacity(
      opacity: f.ativo ? 1 : 0.5,
      child: Card(
        color: cartao,
        margin: const EdgeInsets.only(bottom: 11),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
          side: BorderSide(
            color: semProdutos ? Colors.orangeAccent : bordaCartao,
          ),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          leading: const CircleAvatar(
            backgroundColor: Color(0xFF302719),
            child: Icon(Icons.person, color: dourado),
          ),
          title: Text(
            f.nome.isEmpty ? '(sem nome)' : f.nome,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${f.rotuloCargo}${f.ativo ? '' : ' • desativado'}',
                style: const TextStyle(color: Colors.white54),
              ),
              Text(
                linhaComissao,
                style: TextStyle(
                  color: semProdutos ? Colors.orangeAccent : Colors.white54,
                  fontSize: 12,
                ),
              ),
              if (semProdutos)
                const Text(
                  'Defina a comissão de produtos (Editar).',
                  style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                ),
            ],
          ),
          trailing: protegido
              ? null
              : PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  onSelected: (opcao) {
                    if (opcao == 'editar') {
                      _abrirFormulario(funcionario: f);
                    } else {
                      _alterarAtivo(f);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'editar',
                      child: Text('Editar'),
                    ),
                    PopupMenuItem(
                      value: 'ativo',
                      child: Text(f.ativo ? 'Desativar' : 'Reativar'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

String _bpParaCampo(int bp) {
  if (bp % 100 == 0) return '${bp ~/ 100}';
  return (bp / 100).toStringAsFixed(2).replaceAll('.', ',');
}

class _FormularioFuncionario extends StatefulWidget {
  final FuncionarioRepository repo;
  final Funcionario? funcionario;

  const _FormularioFuncionario({required this.repo, this.funcionario});

  @override
  State<_FormularioFuncionario> createState() =>
      _FormularioFuncionarioState();
}

class _FormularioFuncionarioState extends State<_FormularioFuncionario> {
  final _nome = TextEditingController();
  final _senha = TextEditingController();
  final _comissao = TextEditingController();
  final _produtos = TextEditingController();
  final Map<String, TextEditingController> _cats = {
    for (final c in categoriasServicos) c: TextEditingController(),
  };

  String _cargo = 'colaborador';
  final Map<String, bool> _perms = {};
  bool _salvando = false;
  String? _erro;

  bool get _novo => widget.funcionario == null;

  @override
  void initState() {
    super.initState();
    final f = widget.funcionario;
    if (f != null) {
      _nome.text = f.nome;
      _comissao.text = _bpParaCampo(f.comissaoBp);
      if (f.comissaoProdutosBp != null) {
        _produtos.text = _bpParaCampo(f.comissaoProdutosBp!);
      }
      f.comissaoCategoriasBp.forEach((cat, bp) {
        _cats[cat]?.text = _bpParaCampo(bp);
      });
      _cargo = f.cargo == 'admin_equipe' ? 'admin_equipe' : 'colaborador';
      _perms.addAll(f.permissoes);
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _senha.dispose();
    _comissao.dispose();
    _produtos.dispose();
    for (final c in _cats.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    final nome = _nome.text.trim();
    final padraoBp = percentualParaBp(_comissao.text);
    final produtosBp = percentualParaBp(_produtos.text);

    if (nome.isEmpty) {
      setState(() => _erro = 'Informe o nome do funcionário.');
      return;
    }
    if (_novo && _senha.text.length < 6) {
      setState(() => _erro = 'A senha precisa ter pelo menos 6 caracteres.');
      return;
    }
    if (padraoBp == null) {
      setState(() => _erro = 'Confirme a comissão padrão de serviços (0 a 100).');
      return;
    }
    if (produtosBp == null) {
      setState(() => _erro = 'Confirme a comissão de produtos (0 a 100).');
      return;
    }

    final categorias = <String, int>{};
    for (final e in _cats.entries) {
      final texto = e.value.text.trim();
      if (texto.isEmpty) continue;

      final bp = percentualParaBp(texto);
      if (bp == null) {
        setState(() => _erro = 'Percentual inválido em ${e.key} (0 a 100).');
        return;
      }
      categorias[e.key] = bp;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    final permissoes = <String, bool>{
      for (final e in _perms.entries)
        if (e.value) e.key: true,
    };

    try {
      if (_novo) {
        final email = await widget.repo.criar(
          nome: nome,
          senha: _senha.text,
          cargo: _cargo,
          comissaoBp: padraoBp,
          comissaoProdutosBp: produtosBp,
          comissaoCategoriasBp: categorias,
          permissoes: permissoes,
        );
        if (mounted) Navigator.pop(context, email);
      } else {
        await widget.repo.atualizar(
          widget.funcionario!.uid,
          nome: nome,
          cargo: _cargo,
          comissaoBp: padraoBp,
          comissaoProdutosBp: produtosBp,
          comissaoCategoriasBp: categorias,
          permissoes: permissoes,
        );
        if (mounted) Navigator.pop(context, '');
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _erro = e.code == 'weak-password'
            ? 'Senha muito fraca. Use pelo menos 6 caracteres.'
            : 'Erro ao criar o login (${e.code}).';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _erro = 'Não foi possível salvar. Confira as permissões do Firebase.';
      });
    }
  }

  Widget _secao(String texto) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6),
      child: Text(
        texto,
        style: const TextStyle(
          color: dourado,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: cartao,
      title: Text(
        _novo ? 'Novo funcionário' : 'Editar funcionário',
        style: const TextStyle(color: dourado),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nome,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            if (_novo) ...[
              const SizedBox(height: 13),
              TextField(
                controller: _senha,
                decoration: const InputDecoration(
                  labelText: 'Senha de acesso',
                  helperText: 'Mínimo de 6 caracteres',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
            ],
            const SizedBox(height: 13),
            DropdownButtonFormField<String>(
              value: _cargo,
              decoration: const InputDecoration(labelText: 'Cargo'),
              items: const [
                DropdownMenuItem(
                  value: 'colaborador',
                  child: Text('Colaborador'),
                ),
                DropdownMenuItem(
                  value: 'admin_equipe',
                  child: Text('Administrador de equipe'),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _cargo = v);
              },
            ),
            _secao('COMISSÃO DE SERVIÇOS'),
            TextField(
              controller: _comissao,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Padrão para serviços (%)',
                helperText: 'Vale para toda categoria deixada em branco abaixo',
                helperMaxLines: 2,
                prefixIcon: Icon(Icons.percent),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Percentual diferente por categoria (opcional):',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            for (final c in categoriasServicos) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _cats[c],
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '$c (%)',
                  hintText: 'igual ao padrão',
                ),
              ),
            ],
            _secao('COMISSÃO DE PRODUTOS'),
            TextField(
              controller: _produtos,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Produtos vendidos (%)',
                helperText: 'Obrigatório. Use 0 se não houver comissão.',
                helperMaxLines: 2,
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
            ),
            _secao('PERMISSÕES EXTRAS'),
            for (final p in permissoesDisponiveis)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                activeColor: dourado,
                title: Text(p.rotulo, style: const TextStyle(fontSize: 13)),
                value: _perms[p.chave] == true,
                onChanged: (v) => setState(() => _perms[p.chave] = v),
              ),
            if (_erro != null) ...[
              const SizedBox(height: 10),
              Text(_erro!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: _salvando ? null : _salvar,
          style: ElevatedButton.styleFrom(
            backgroundColor: dourado,
            foregroundColor: Colors.black,
          ),
          child: _salvando
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
