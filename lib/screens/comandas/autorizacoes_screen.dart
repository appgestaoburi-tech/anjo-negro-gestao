import 'package:flutter/material.dart';
import '../../config/tema.dart';
import '../../models/comanda.dart';
import '../../models/perfil_usuario.dart';
import '../../repositories/comanda_repository.dart';
import '../../utils/dinheiro.dart';
import '../../utils/erros.dart';
import '../../utils/percentual.dart';

class AutorizacoesScreen extends StatelessWidget {
  final PerfilUsuario perfil;
  final ComandaRepository _repo = ComandaRepository();

  AutorizacoesScreen({super.key, required this.perfil});

  Future<void> _decidir(BuildContext context, Comanda c, bool aprovar) async {
    try {
      await _repo.decidirDesconto(c.id, aprovar, perfil);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(aprovar ? 'Desconto aprovado.' : 'Pedido recusado.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagemDeErro(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AUTORIZAÇÕES')),
      body: StreamBuilder<List<Comanda>>(
        stream: _repo.observarPendentes(),
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
                  'Erro ao carregar os pedidos:\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          }

          final lista = snapshot.data ?? [];

          if (lista.isEmpty) {
            return const Center(
              child: Text('Nenhum pedido de desconto pendente.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lista.length,
            itemBuilder: (context, i) {
              final c = lista[i];
              final valor = (c.subtotalServicosCentavos *
                          c.descontoSolicitadoBp +
                      5000) ~/
                  10000;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cartao,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: dourado),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${c.numero} • ${c.nomeCliente}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Barbeiro: ${c.barbeiroNome}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Serviços: ${Dinheiro.formatar(c.subtotalServicosCentavos)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pede ${bpParaTexto(c.descontoSolicitadoBp)} '
                      '(− ${Dinheiro.formatar(valor)})',
                      style: const TextStyle(
                        color: dourado,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _decidir(context, c, false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                            ),
                            child: const Text('RECUSAR'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _decidir(context, c, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: dourado,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('APROVAR'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
