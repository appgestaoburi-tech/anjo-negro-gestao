import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../config/tema.dart';
import '../../models/cliente.dart';
import '../../repositories/cliente_repository.dart';
import '../../services/perfil_service.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final _repo = ClienteRepository();
  final _busca = TextEditingController();
  String _termo = '';
  bool _admin = false;

  @override
  void initState() {
    super.initState();
    _carregarPermissao();
  }

  Future<void> _carregarPermissao() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final perfil = await PerfilService().carregar(user.uid);
      if (mounted) setState(() => _admin = perfil.permissaoTotal);
    } catch (_) {
      // Sem permissão confirmada, a exclusão simplesmente não aparece.
    }
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _novo() async {
    final salvou = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FormularioCliente(repo: _repo),
    );
    if (salvou == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente cadastrado!')),
      );
    }
  }

  bool _combina(Cliente c) {
    if (_termo.isEmpty) return true;
    final q = Cliente.normalizar(_termo);
    if (Cliente.normalizar(c.nome).contains(q)) return true;
    final digitos = _termo.replaceAll(RegExp(r'\D'), '');
    return digitos.isNotEmpty && c.telefone.contains(digitos);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CLIENTES')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _busca,
              onChanged: (v) => setState(() => _termo = v.trim()),
              decoration: InputDecoration(
                labelText: 'Pesquisar por nome ou telefone',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _termo.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _busca.clear();
                          setState(() => _termo = '');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Cliente>>(
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
                        'Erro ao carregar os clientes:\n\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  );
                }

                final todos = snapshot.data ?? [];
                final lista = todos.where(_combina).toList();

                if (lista.isEmpty) {
                  return Center(
                    child: Text(
                      todos.isEmpty
                          ? 'Nenhum cliente cadastrado.'
                          : 'Nenhum cliente encontrado.',
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                  itemCount: lista.length,
                  itemBuilder: (context, i) {
                    final c = lista[i];
                    return Card(
                      color: cartao,
                      margin: const EdgeInsets.only(bottom: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                        side: const BorderSide(color: bordaCartao),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 6,
                        ),
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF302719),
                          child: Icon(Icons.person, color: dourado),
                        ),
                        title: Text(
                          c.nome,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          c.telefone.isEmpty
                              ? 'Sem telefone'
                              : c.telefoneFormatado,
                          style: const TextStyle(color: Colors.white54),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.white38,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClienteDetalheScreen(
                              id: c.id,
                              repo: _repo,
                              podeExcluir: _admin,
                            ),
                          ),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: dourado,
        foregroundColor: Colors.black,
        onPressed: _novo,
        icon: const Icon(Icons.person_add),
        label: const Text('NOVO CLIENTE'),
      ),
    );
  }
}

Future<bool> _confirmarExclusao(BuildContext context, String nome) async {
  final resposta = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: cartao,
      title: const Text('Excluir cliente', style: TextStyle(color: dourado)),
      content: Text(
        'Excluir "$nome" definitivamente?\n\n'
        'Esta ação não pode ser desfeita.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          child: const Text('EXCLUIR'),
        ),
      ],
    ),
  );
  return resposta == true;
}

class ClienteDetalheScreen extends StatelessWidget {
  final String id;
  final ClienteRepository repo;
  final bool podeExcluir;

  const ClienteDetalheScreen({
    super.key,
    required this.id,
    required this.repo,
    this.podeExcluir = false,
  });

  Future<void> _excluir(BuildContext context, Cliente c) async {
    final confirmou = await _confirmarExclusao(context, c.nome);
    if (!confirmou || !context.mounted) return;

    final navegador = Navigator.of(context);
    final mensagens = ScaffoldMessenger.of(context);

    try {
      await repo.excluir(c.id);
      navegador.pop();
      mensagens.showSnackBar(
        const SnackBar(content: Text('Cliente excluído.')),
      );
    } catch (_) {
      mensagens.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível excluir. Confira as permissões.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Cliente?>(
      stream: repo.observarUm(id),
      builder: (context, snapshot) {
        final c = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: Text(c?.nome ?? 'CLIENTE'),
            actions: [
              if (c != null)
                IconButton(
                  tooltip: 'Editar',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    final salvou = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => _FormularioCliente(repo: repo, cliente: c),
                    );
                    if (salvou == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cadastro atualizado.')),
                      );
                    }
                  },
                ),
              if (c != null && podeExcluir)
                IconButton(
                  tooltip: 'Excluir cliente',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _excluir(context, c),
                ),
            ],
          ),
          body: c == null
              ? Center(
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? const CircularProgressIndicator(color: dourado)
                      : const Text('Cliente não encontrado.'),
                )
              : ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    _linha(Icons.phone_outlined, 'Telefone',
                        c.telefone.isEmpty ? '—' : c.telefoneFormatado),
                    _linha(Icons.cake_outlined, 'Nascimento',
                        c.nascimento.isEmpty ? '—' : c.nascimentoFormatado),
                    _linha(Icons.notes, 'Observações',
                        c.observacoes.isEmpty ? '—' : c.observacoes),
                    const SizedBox(height: 22),
                    const Text(
                      'HISTÓRICO DE ATENDIMENTOS',
                      style: TextStyle(
                        color: dourado,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cartao,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: bordaCartao),
                      ),
                      child: const Text(
                        'O histórico de comandas, serviços e valores gastos '
                        'aparecerá aqui quando o módulo de comandas for '
                        'ativado (Etapa 3).',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _linha(IconData icone, String rotulo, String valor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cartao,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: bordaCartao),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: dourado),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rotulo,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 3),
                SelectableText(valor, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "dd/mm/aaaa" -> "aaaa-mm-dd". Vazio é válido (''). Inválido retorna null.
String? _nascimentoParaIso(String texto) {
  final s = texto.trim();
  if (s.isEmpty) return '';
  final m = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(s);
  if (m == null) return null;
  final d = int.parse(m[1]!);
  final mes = int.parse(m[2]!);
  final a = int.parse(m[3]!);
  final dt = DateTime(a, mes, d);
  if (dt.year != a || dt.month != mes || dt.day != d) return null;
  if (a < 1900 || dt.isAfter(DateTime.now())) return null;
  return '$a-${mes.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
}

class _FormularioCliente extends StatefulWidget {
  final ClienteRepository repo;
  final Cliente? cliente;

  const _FormularioCliente({required this.repo, this.cliente});

  @override
  State<_FormularioCliente> createState() => _FormularioClienteState();
}

class _FormularioClienteState extends State<_FormularioCliente> {
  final _nome = TextEditingController();
  final _telefone = TextEditingController();
  final _nascimento = TextEditingController();
  final _observacoes = TextEditingController();

  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    if (c != null) {
      _nome.text = c.nome;
      _telefone.text = c.telefone;
      _nascimento.text = c.nascimentoFormatado;
      _observacoes.text = c.observacoes;
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    _nascimento.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final nome = _nome.text.trim();
    final telefone = _telefone.text.replaceAll(RegExp(r'\D'), '');
    final nascimento = _nascimentoParaIso(_nascimento.text);

    if (nome.isEmpty) {
      setState(() => _erro = 'Informe o nome do cliente.');
      return;
    }
    if (telefone.isNotEmpty && telefone.length != 10 && telefone.length != 11) {
      setState(() => _erro = 'Telefone inválido. Use DDD + número.');
      return;
    }
    if (nascimento == null) {
      setState(() => _erro = 'Data inválida. Use o formato dd/mm/aaaa.');
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      final c = widget.cliente;
      if (c == null) {
        await widget.repo.criar(
          nome: nome,
          telefone: telefone,
          nascimento: nascimento,
          observacoes: _observacoes.text.trim(),
        );
      } else {
        await widget.repo.atualizar(
          c.id,
          nome: nome,
          telefone: telefone,
          nascimento: nascimento,
          observacoes: _observacoes.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _erro = 'Não foi possível salvar. Confira a conexão e as permissões.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: cartao,
      title: Text(
        widget.cliente == null ? 'Novo cliente' : 'Editar cliente',
        style: const TextStyle(color: dourado),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nome,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 13),
            TextField(
              controller: _telefone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefone (opcional)',
                helperText: 'DDD + número',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 13),
            TextField(
              controller: _nascimento,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: 'Nascimento (opcional)',
                helperText: 'dd/mm/aaaa',
                prefixIcon: Icon(Icons.cake_outlined),
              ),
            ),
            const SizedBox(height: 13),
            TextField(
              controller: _observacoes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
                prefixIcon: Icon(Icons.notes),
              ),
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
