import 'package:flutter/material.dart';
import '../../config/tema.dart';
import '../../models/cliente.dart';
import '../../models/pacote_cliente.dart';
import '../../repositories/pacote_cliente_repository.dart';
import '../../utils/datas.dart';
import '../../utils/dinheiro.dart';
import 'pacote_cliente_detalhe_screen.dart';

class PacotesClientesScreen extends StatefulWidget {
  const PacotesClientesScreen({super.key});

  @override
  State<PacotesClientesScreen> createState() => _PacotesClientesScreenState();
}

class _PacotesClientesScreenState extends State<PacotesClientesScreen> {
  final _repo = PacoteClienteRepository();
  late final Stream<List<PacoteCliente>> _stream = _repo.observarTodos();
  final _busca = TextEditingController();

  String _termo = '';
  String _filtro = 'ativos'; // ativos | encerrados | todos

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  bool _combina(PacoteCliente p) {
    if (_termo.isEmpty) return true;
    final q = Cliente.normalizar(_termo);
    if (Cliente.normalizar(p.clienteNome).contains(q)) return true;
    final digitos = _termo.replaceAll(RegExp(r'\D'), '');
    return digitos.isNotEmpty && p.clienteTelefone.contains(digitos);
  }

  bool _passaFiltro(PacoteCliente p, DateTime agora) {
    if (_filtro == 'todos') return true;
    final ativo = p.situacao(agora) == 'ativo';
    return _filtro == 'ativos' ? ativo : !ativo;
  }

  Color _cor(String situacao) {
    switch (situacao) {
      case 'ativo':
        return Colors.greenAccent;
      case 'vencido':
        return Colors.orangeAccent;
      case 'concluido':
        return dourado;
      default:
        return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PACOTES DOS CLIENTES')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                for (final f in const [
                  ['ativos', 'ATIVOS'],
                  ['encerrados', 'ENCERRADOS'],
                  ['todos', 'TODOS'],
                ])
                  ChoiceChip(
                    label: Text(f[1]),
                    selected: _filtro == f[0],
                    selectedColor: dourado,
                    labelStyle: TextStyle(
                      color: _filtro == f[0] ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setState(() => _filtro = f[0]),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<PacoteCliente>>(
              stream: _stream,
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
                        'Erro ao carregar os pacotes:\n\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  );
                }

                final agora = DateTime.now();
                final lista = (snapshot.data ?? [])
                    .where((p) => _passaFiltro(p, agora) && _combina(p))
                    .toList();

                if (lista.isEmpty) {
                  return const Center(
                    child: Text('Nenhum pacote encontrado.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  itemCount: lista.length,
                  itemBuilder: (context, i) {
                    final p = lista[i];
                    final situacao = p.situacao(agora);

                    return InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PacoteClienteDetalheScreen(pacoteId: p.id),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(13),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 11),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cartao,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: bordaCartao),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    p.clienteNome,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Text(
                                  PacoteCliente.rotuloSituacao(situacao),
                                  style: TextStyle(
                                    color: _cor(situacao),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${p.nome}'
                              '${p.clienteTelefone.isEmpty ? '' : ' • ${p.telefoneFormatado}'}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Usos: ${p.usosTotal} de ${p.totalUsos} • '
                              'Vence em ${formatarDia(p.fimData.subtract(const Duration(days: 1)))}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'A prestar: ${Dinheiro.formatar(p.aPrestarCentavos)}',
                              style: const TextStyle(
                                color: dourado,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
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
    );
  }
}
