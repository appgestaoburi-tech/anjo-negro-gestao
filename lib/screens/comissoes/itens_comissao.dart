import 'package:flutter/material.dart';
import '../../config/formas_pagamento.dart';
import '../../config/tema.dart';
import '../../models/comissao.dart';
import '../../utils/datas.dart';
import '../../utils/dinheiro.dart';
import '../../utils/percentual.dart';

class TileComissao extends StatelessWidget {
  final Comissao comissao;
  final bool estorno;

  const TileComissao({super.key, required this.comissao, this.estorno = false});

  @override
  Widget build(BuildContext context) {
    final c = comissao;
    final cor = estorno ? Colors.redAccent : dourado;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cartao,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: bordaCartao),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: dourado,
        collapsedIconColor: Colors.white54,
        title: Text(
          '#${c.comandaNumero} • '
          '${c.clienteNome.isEmpty ? 'Sem cadastro' : c.clienteNome}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          '${formatarDiaIso(c.dia)}${estorno ? ' • comanda estornada' : ''}',
          style: TextStyle(
            color: estorno ? Colors.redAccent : Colors.white54,
            fontSize: 12,
          ),
        ),
        trailing: Text(
          '${estorno ? '− ' : ''}${Dinheiro.formatar(c.totalCentavos)}',
          style: TextStyle(color: cor, fontWeight: FontWeight.bold),
        ),
        children: [
          for (final l in c.linhas)
            ListTile(
              dense: true,
              title: Text(l.nome, style: const TextStyle(fontSize: 13)),
              subtitle: Text(
                'base ${Dinheiro.formatar(l.baseCentavos)} x '
                '${bpParaTexto(l.bp)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              trailing: Text(
                Dinheiro.formatar(l.comissaoCentavos),
                style: const TextStyle(fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

class ItemPagamentoComissao extends StatelessWidget {
  final PagamentoComissao pagamento;
  final bool podeEstornar;
  final VoidCallback onEstornar;

  const ItemPagamentoComissao({
    super.key,
    required this.pagamento,
    required this.podeEstornar,
    required this.onEstornar,
  });

  @override
  Widget build(BuildContext context) {
    final p = pagamento;

    final detalhes = <String>[
      formatarDataHora(p.criadoEm?.toDate()),
      rotuloForma(p.forma),
      'por ${p.pagoPorNome}',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      decoration: BoxDecoration(
        color: cartao,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: bordaCartao),
      ),
      child: Row(
        children: [
          Icon(
            Icons.payments_outlined,
            color: p.estornado ? Colors.white38 : dourado,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Dinheiro.formatar(p.valorCentavos),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: p.estornado ? Colors.white38 : Colors.white,
                    decoration:
                        p.estornado ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detalhes.join(' • '),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                if (p.estornado)
                  Text(
                    'ESTORNADO por ${p.estornadoPorNome}',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (podeEstornar && !p.estornado)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white70),
              onSelected: (_) => onEstornar(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'estornar', child: Text('Estornar')),
              ],
            )
          else
            const SizedBox(width: 10),
        ],
      ),
    );
  }
}
