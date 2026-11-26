import 'package:flutter/material.dart';
import '../../config/tema.dart';
import '../../models/comanda.dart';
import '../../utils/datas.dart';
import '../../utils/dinheiro.dart';
import '../../utils/percentual.dart';

class TituloSecao extends StatelessWidget {
  final String texto;

  const TituloSecao(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        color: dourado,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
  }
}

class BotaoComanda extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;
  final bool destaque;
  final IconData icone;

  const BotaoComanda({
    super.key,
    required this.texto,
    required this.onPressed,
    this.destaque = false,
    this.icone = Icons.add,
  });

  @override
  Widget build(BuildContext context) {
    final rotulo = Text(
      texto,
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return SizedBox(
      height: 50,
      child: destaque
          ? ElevatedButton.icon(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: dourado,
                foregroundColor: Colors.black,
                shape: forma,
              ),
              icon: Icon(icone),
              label: rotulo,
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: dourado,
                side: const BorderSide(color: dourado),
                shape: forma,
              ),
              icon: Icon(icone),
              label: rotulo,
            ),
    );
  }
}

class CabecalhoComanda extends StatelessWidget {
  final Comanda comanda;

  const CabecalhoComanda({super.key, required this.comanda});

  Widget _linha(IconData icone, String rotulo, String valor) {
    return Row(
      children: [
        Icon(icone, color: dourado, size: 20),
        const SizedBox(width: 10),
        Text('$rotulo: ', style: const TextStyle(color: Colors.white54)),
        Expanded(
          child: Text(
            valor,
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = comanda;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cartao,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: bordaCartao),
      ),
      child: Column(
        children: [
          _linha(Icons.person_outline, 'Cliente', c.nomeCliente),
          const SizedBox(height: 8),
          _linha(Icons.content_cut, 'Barbeiro', c.barbeiroNome),
          const SizedBox(height: 8),
          _linha(Icons.schedule, 'Aberta em', formatarDataHora(c.criadoEm)),
          if (!c.aberta) ...[
            const SizedBox(height: 8),
            _linha(Icons.info_outline, 'Situação', c.rotuloStatus),
          ],
        ],
      ),
    );
  }
}

class BarraTotalComanda extends StatelessWidget {
  final Comanda comanda;

  const BarraTotalComanda({super.key, required this.comanda});

  Widget _linhaValor(String rotulo, int centavos, {bool negativo = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          rotulo,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        Text(
          '${negativo ? '− ' : ''}${Dinheiro.formatar(centavos)}',
          style: TextStyle(
            color: negativo ? Colors.orangeAccent : Colors.white70,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = comanda;
    final detalhado = c.subtotalProdutosCentavos > 0 || c.descontoCentavos > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: cartao,
        border: Border(top: BorderSide(color: bordaCartao)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (detalhado) ...[
              _linhaValor('Serviços', c.subtotalServicosCentavos),
              if (c.subtotalProdutosCentavos > 0) ...[
                const SizedBox(height: 2),
                _linhaValor('Produtos', c.subtotalProdutosCentavos),
              ],
              if (c.descontoCentavos > 0) ...[
                const SizedBox(height: 2),
                _linhaValor(
                  'Desconto (${bpParaTexto(c.descontoBp)})',
                  c.descontoCentavos,
                  negativo: true,
                ),
              ],
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  Dinheiro.formatar(c.totalCentavos),
                  style: const TextStyle(
                    color: dourado,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
            if (c.pagoCentavos > 0) ...[
              const SizedBox(height: 6),
              _linhaValor('Pago', c.pagoCentavos),
              if (c.saldoCentavos > 0) ...[
                const SizedBox(height: 2),
                _linhaValor('Saldo a receber', c.saldoCentavos),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
