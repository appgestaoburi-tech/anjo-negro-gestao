import 'package:flutter/material.dart';
import '../../config/parametros.dart';
import '../../config/tema.dart';
import '../../models/comanda.dart';
import '../../utils/dinheiro.dart';
import '../../utils/percentual.dart';
import 'comanda_widgets.dart';

class SecaoDescontoComanda extends StatelessWidget {
  final Comanda comanda;
  final bool admin;
  final VoidCallback onAlterar;
  final void Function(bool aprovar) onDecidir;
  final VoidCallback onCancelarPedido;

  const SecaoDescontoComanda({
    super.key,
    required this.comanda,
    required this.admin,
    required this.onAlterar,
    required this.onDecidir,
    required this.onCancelarPedido,
  });

  Widget _resumo(Comanda c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cartao,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: bordaCartao),
      ),
      child: c.descontoBp > 0
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${bpParaTexto(c.descontoBp)} de desconto '
                  '(− ${Dinheiro.formatar(c.descontoCentavos)})',
                  style: const TextStyle(
                    color: dourado,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Sobre os serviços: '
                  '${Dinheiro.formatar(c.subtotalServicosCentavos)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                if (c.descontoAprovadoBp > limiteDescontoSemAutorizacaoBp &&
                    c.descontoDecididoPorNome.isNotEmpty)
                  Text(
                    'Autorizado por ${c.descontoDecididoPorNome}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
              ],
            )
          : const Text('Sem desconto.', style: TextStyle(color: Colors.white54)),
    );
  }

  Widget _pedidoPendente(Comanda c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cartao,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.orangeAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            admin
                ? '${c.descontoSolicitadoPorNome} pede '
                    '${bpParaTexto(c.descontoSolicitadoBp)} de desconto.'
                : 'Aguardando autorização do administrador: '
                    '${bpParaTexto(c.descontoSolicitadoBp)}.',
            style: const TextStyle(
              color: Colors.orangeAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          if (admin)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onDecidir(false),
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
                    onPressed: () => onDecidir(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dourado,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('APROVAR'),
                  ),
                ),
              ],
            )
          else
            TextButton(
              onPressed: onCancelarPedido,
              child: const Text('CANCELAR PEDIDO'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = comanda;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _resumo(c),
        if (c.descontoPendente) ...[
          const SizedBox(height: 10),
          _pedidoPendente(c),
        ],
        if (c.descontoRecusado) ...[
          const SizedBox(height: 10),
          Text(
            'Pedido de ${bpParaTexto(c.descontoSolicitadoBp)} recusado'
            '${c.descontoDecididoPorNome.isEmpty ? '' : ' por ${c.descontoDecididoPorNome}'}.',
            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
          ),
        ],
        if (c.aberta && !c.descontoPendente && c.servicos.isNotEmpty) ...[
          const SizedBox(height: 10),
          BotaoComanda(
            texto: c.descontoBp > 0 ? 'ALTERAR DESCONTO' : 'APLICAR DESCONTO',
            onPressed: onAlterar,
            icone: Icons.percent,
          ),
        ],
      ],
    );
  }
}
