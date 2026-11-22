import 'package:flutter/material.dart';
import '../../config/formas_pagamento.dart';
import '../../config/tema.dart';
import '../../models/comanda.dart';
import '../../models/pagamento.dart';
import '../../models/perfil_usuario.dart';
import '../../repositories/pagamento_repository.dart';
import '../../utils/datas.dart';
import '../../utils/dinheiro.dart';
import '../../utils/erros.dart';
import 'dialogo_pagamento.dart';

class SecaoPagamento extends StatefulWidget {
  final Comanda comanda;
  final PerfilUsuario perfil;

  const SecaoPagamento({
    super.key,
    required this.comanda,
    required this.perfil,
  });

  @override
  State<SecaoPagamento> createState() => _SecaoPagamentoState();
}

class _SecaoPagamentoState extends State<SecaoPagamento> {
  final _repo = PagamentoRepository();
  late final Stream<List<Pagamento>> _stream =
      _repo.observarDaComanda(widget.comanda.id, widget.perfil);

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> _registrar() async {
    final c = widget.comanda;

    final r = await showDialog<ResultadoPagamento>(
      context: context,
       builder: (_) => DialogPagamento(
        saldoCentavos: c.saldoCentavos,
        comandaNumero: c.numero,
      ),
    );

    if (r == null || !mounted) return;

    try {
      await _repo.registrar(
        comandaId: c.id,
        forma: r.forma,
        valorCentavos: r.valorCentavos,
        recebidoCentavos: r.recebidoCentavos,
        perfil: widget.perfil,
      );
      _aviso(
        r.valorCentavos == c.saldoCentavos
            ? 'Comanda paga!'
            : 'Pagamento parcial registrado.',
      );
    } catch (e) {
      _aviso(mensagemDeErro(e));
    }
  }

  Future<void> _estornar(Pagamento p) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (_) => const _DialogEstorno(),
    );

    if (motivo == null || !mounted) return;

    try {
      await _repo.estornar(p.id, widget.perfil, motivo: motivo);
      _aviso('Pagamento estornado.');
    } catch (e) {
      _aviso(mensagemDeErro(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.comanda;

    return StreamBuilder<List<Pagamento>>(
      stream: _stream,
      builder: (context, snapshot) {
        final pagamentos = snapshot.data ?? [];

        if (c.totalCentavos <= 0 && pagamentos.isEmpty) {
          return const SizedBox.shrink();
        }

        final podeReceber = c.aberta &&
            c.totalCentavos > 0 &&
            c.saldoCentavos > 0 &&
            !c.descontoPendente;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text(
              'PAGAMENTO',
              style: TextStyle(
                color: dourado,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            if (c.status == 'paga')
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF302719),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: dourado),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: dourado),
                    SizedBox(width: 10),
                    Text(
                      'COMANDA PAGA',
                      style: TextStyle(
                        color: dourado,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            if (snapshot.hasError)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'Não foi possível carregar os pagamentos.',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            for (final p in pagamentos) _itemPagamento(p),
            if (c.descontoPendente && c.aberta)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'O pagamento será liberado depois da decisão sobre o '
                  'desconto.',
                  style: TextStyle(color: Colors.orangeAccent, fontSize: 13),
                ),
              ),
            if (podeReceber)
              SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _registrar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dourado,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.payments_outlined),
                  label: Text(
                    c.pagoCentavos > 0
                        ? 'RECEBER O RESTANTE'
                        : 'RECEBER PAGAMENTO',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _itemPagamento(Pagamento p) {
    final admin = widget.perfil.permissaoTotal;

    final detalhes = <String>[
      formatarDataHora(p.criadoEm),
      'por ${p.registradoPorNome}',
      if (p.trocoCentavos > 0) 'troco ${Dinheiro.formatar(p.trocoCentavos)}',
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
            iconeForma(p.forma),
            color: p.estornado ? Colors.white38 : dourado,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${rotuloForma(p.forma)} • ${Dinheiro.formatar(p.valorCentavos)}',
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
                    'ESTORNADO por ${p.estornadoPorNome}'
                    '${p.motivoEstorno.isEmpty ? '' : ' (${p.motivoEstorno})'}',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (admin && !p.estornado)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white70),
              onSelected: (_) => _estornar(p),
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

class _DialogEstorno extends StatefulWidget {
  const _DialogEstorno();

  @override
  State<_DialogEstorno> createState() => _DialogEstornoState();
}

class _DialogEstornoState extends State<_DialogEstorno> {
  final _motivo = TextEditingController();

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: cartao,
      title: const Text('Estornar pagamento', style: TextStyle(color: dourado)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'O pagamento continua no histórico, marcado como estornado. '
            'Se a comanda estiver paga, ela será reaberta e o estoque dos '
            'produtos voltará.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _motivo,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Motivo (opcional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('VOLTAR'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _motivo.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          child: const Text('ESTORNAR'),
        ),
      ],
    );
  }
}
