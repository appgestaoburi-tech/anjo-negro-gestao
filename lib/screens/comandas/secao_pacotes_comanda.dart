import 'package:flutter/material.dart';
import '../../config/tema.dart';
import '../../models/comanda.dart';
import '../../models/pacote.dart';
import '../../models/perfil_usuario.dart';
import '../../repositories/pacote_repository.dart';
import '../../repositories/pacote_uso_repository.dart';
import '../../repositories/pacote_venda_repository.dart';
import '../../utils/dinheiro.dart';
import '../../utils/erros.dart';
import 'cartao_uso_pacote.dart';

class SecaoPacotesComanda extends StatelessWidget {
  final Comanda comanda;
  final PerfilUsuario perfil;

  const SecaoPacotesComanda({
    super.key,
    required this.comanda,
    required this.perfil,
  });

  void _aviso(BuildContext context, String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> _vender(BuildContext context) async {
    final pacote = await showModalBottomSheet<Pacote>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cartao,
      builder: (_) => const _SeletorPacote(),
    );

    if (pacote == null || !context.mounted) return;

    try {
      await PacoteVendaRepository().adicionarNaComanda(comanda.id, pacote);
    } catch (e) {
      if (!context.mounted) return;
      _aviso(context, mensagemDeErro(e));
    }
  }

  Future<void> _finalizar(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cartao,
        title: const Text(
          'Finalizar atendimento',
          style: TextStyle(color: dourado),
        ),
        content: const Text(
          'Os usos do pacote serão confirmados e a comissão será '
          'registrada. Não há valor a cobrar do cliente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('VOLTAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: dourado,
              foregroundColor: Colors.black,
            ),
            child: const Text('FINALIZAR'),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;

    try {
      await PacoteUsoRepository().finalizarCoberta(comanda.id, perfil);
      if (!context.mounted) return;
      _aviso(context, 'Atendimento finalizado.');
    } catch (e) {
      if (!context.mounted) return;
      _aviso(context, mensagemDeErro(e));
    }
  }

  Future<void> _reabrir(BuildContext context) async {
    try {
      await PacoteUsoRepository().reabrirCoberta(comanda.id, perfil);
      if (!context.mounted) return;
      _aviso(context, 'Atendimento reaberto.');
    } catch (e) {
      if (!context.mounted) return;
      _aviso(context, mensagemDeErro(e));
    }
  }

  Widget _titulo() {
    return const Padding(
      padding: EdgeInsets.only(top: 24, bottom: 10),
      child: Text(
        'PACOTES',
        style: TextStyle(
          color: dourado,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = comanda;

    // Atendimento finalizado sem cobrança: o administrador pode reabrir.
    if (!c.aberta) {
      if (c.status == 'paga' && c.coberta && perfil.permissaoTotal) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _titulo(),
            OutlinedButton.icon(
              onPressed: () => _reabrir(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orangeAccent,
                side: const BorderSide(color: Colors.orangeAccent),
              ),
              icon: const Icon(Icons.lock_open),
              label: const Text('REABRIR ATENDIMENTO'),
            ),
          ],
        );
      }
      return const SizedBox.shrink();
    }

    final temCliente = c.clienteId.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo(),
        if (!temCliente)
          const Text(
            'Para vender pacote ou usar o pacote de um cliente, abra a '
            'comanda escolhendo um cliente cadastrado.',
            style: TextStyle(color: Colors.white54),
          )
        else ...[
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _vender(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: dourado,
                side: const BorderSide(color: dourado),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.card_membership),
              label: const Text(
                'VENDER PACOTE',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          CartaoUsoPacote(comanda: c, perfil: perfil),
        ],
        if (c.coberta) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _finalizar(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: dourado,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text(
                'FINALIZAR ATENDIMENTO (PACOTE)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SeletorPacote extends StatelessWidget {
  const _SeletorPacote();

  @override
  Widget build(BuildContext context) {
    final altura = MediaQuery.of(context).size.height * 0.7;

    return SizedBox(
      height: altura,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'ESCOLHA O PACOTE',
              style: TextStyle(
                color: dourado,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Pacote>>(
              stream: PacoteRepository().observar(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: dourado),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Erro ao carregar os pacotes.'),
                  );
                }

                final lista = (snapshot.data ?? [])
                    .where((p) => p.ativo && p.precoCentavos > 0)
                    .toList();

                if (lista.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Nenhum pacote ativo para venda. O administrador '
                        'define o preço e ativa em Pacotes.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: lista.length,
                  itemBuilder: (context, i) {
                    final p = lista[i];

                    return ListTile(
                      title: Text(
                        p.nome,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${p.duracaoTexto} • ${p.resumo}'),
                      trailing: Text(
                        Dinheiro.formatar(p.precoCentavos),
                        style: const TextStyle(
                          color: dourado,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () => Navigator.pop(context, p),
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
