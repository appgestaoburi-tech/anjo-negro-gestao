import 'package:flutter/material.dart';
import '../../config/tema.dart';
import '../../models/comanda.dart';
import '../../models/pacote.dart';
import '../../models/perfil_usuario.dart';
import '../../repositories/pacote_repository.dart';
import '../../repositories/pacote_venda_repository.dart';
import '../../utils/dinheiro.dart';
import '../../utils/erros.dart';

class SecaoPacotesComanda extends StatelessWidget {
  final Comanda comanda;
  final PerfilUsuario perfil;

  const SecaoPacotesComanda({
    super.key,
    required this.comanda,
    required this.perfil,
  });

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagemDeErro(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!comanda.aberta) return const SizedBox.shrink();

    final temCliente = comanda.clienteId.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'PACOTES',
          style: TextStyle(
            color: dourado,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        if (!temCliente)
          const Text(
            'Para vender pacote, abra a comanda escolhendo um cliente '
            'cadastrado.',
            style: TextStyle(color: Colors.white54),
          )
        else
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
