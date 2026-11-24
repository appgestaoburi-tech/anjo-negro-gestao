import 'package:flutter/material.dart';
import '../../config/tema.dart';
import '../../models/pacote.dart';
import '../../repositories/pacote_repository.dart';
import '../../utils/dinheiro.dart';
import '../../utils/erros.dart';
import 'formulario_pacote_screen.dart';

class PacotesScreen extends StatefulWidget {
  const PacotesScreen({super.key});

  @override
  State<PacotesScreen> createState() => _PacotesScreenState();
}

class _PacotesScreenState extends State<PacotesScreen> {
  final _repo = PacoteRepository();
  late final Stream<List<Pacote>> _stream = _repo.observar();
  String? _erroInicial;

  @override
  void initState() {
    super.initState();
    _prepararIniciais();
  }

  Future<void> _prepararIniciais() async {
    try {
      await _repo.garantirIniciais();
    } catch (e) {
      if (mounted) setState(() => _erroInicial = mensagemDeErro(e));
    }
  }

  Future<void> _abrir({Pacote? pacote}) async {
    final salvou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FormularioPacoteScreen(repo: _repo, pacote: pacote),
      ),
    );

    if (salvou == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pacote salvo com sucesso!')),
      );
    }
  }

  Future<void> _alternarAtivo(Pacote p) async {
    try {
      await _repo.definirAtivo(p.id, !p.ativo);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagemDeErro(e))),
      );
    }
  }

  Widget _cartao(Pacote p) {
    final semPreco = p.precoCentavos <= 0;

    return Opacity(
      opacity: p.ativo ? 1 : 0.7,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
        decoration: BoxDecoration(
          color: cartao,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: semPreco ? Colors.orangeAccent : bordaCartao,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${p.duracaoTexto} • ${p.resumo}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Máximo por mês: '
                    '${p.itens.map((i) => '${i.maxPorMes} ${i.servicoNome}').join(', ')}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        semPreco
                            ? 'DEFINA O PREÇO'
                            : Dinheiro.formatar(p.precoCentavos),
                        style: TextStyle(
                          color: semPreco ? Colors.orangeAccent : dourado,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        p.ativo ? 'ATIVO' : 'INATIVO',
                        style: TextStyle(
                          color: p.ativo ? Colors.greenAccent : Colors.white38,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white70),
              onSelected: (opcao) {
                if (opcao == 'editar') {
                  _abrir(pacote: p);
                } else {
                  _alternarAtivo(p);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'editar', child: Text('Editar')),
                PopupMenuItem(
                  value: 'ativo',
                  child: Text(p.ativo ? 'Desativar' : 'Ativar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PACOTES')),
      body: StreamBuilder<List<Pacote>>(
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

          final lista = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: [
              if (_erroInicial != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _erroInicial!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: Text(
                  'Pacotes sem preço ou inativos não aparecem para venda.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              if (lista.isEmpty)
                const Center(child: Text('Nenhum pacote cadastrado.')),
              for (final p in lista) _cartao(p),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: dourado,
        foregroundColor: Colors.black,
        onPressed: () => _abrir(),
        icon: const Icon(Icons.add),
        label: const Text('NOVO PACOTE'),
      ),
    );
  }
}
