import 'package:flutter/material.dart';
import '../../config/formas_pagamento.dart';
import '../../config/tema.dart';
import '../../utils/dinheiro.dart';

class EntradaPagamentoComissao {
  final String forma;
  final String observacoes;

  const EntradaPagamentoComissao(this.forma, this.observacoes);
}

class DialogPagarComissao extends StatefulWidget {
  final String nome;
  final int valorCentavos;
  final String periodo;

  const DialogPagarComissao({
    super.key,
    required this.nome,
    required this.valorCentavos,
    required this.periodo,
  });

  @override
  State<DialogPagarComissao> createState() => _DialogPagarComissaoState();
}

class _DialogPagarComissaoState extends State<DialogPagarComissao> {
  final _observacoes = TextEditingController();
  String _forma = 'dinheiro';
  bool _confirmou = false;
  String? _erro;

  @override
  void dispose() {
    _observacoes.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (!_confirmou) {
      setState(() => _erro = 'Marque a confirmação do pagamento.');
      return;
    }
    Navigator.pop(
      context,
      EntradaPagamentoComissao(_forma, _observacoes.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: cartao,
      title: const Text('Pagar comissão', style: TextStyle(color: dourado)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.nome}: ${Dinheiro.formatar(widget.valorCentavos)}',
              style: const TextStyle(
                color: dourado,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (widget.periodo.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Período: ${widget.periodo}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
            const SizedBox(height: 14),
            const Text('Forma de pagamento:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in formasPagamento.where(
                  (f) => f.chave == 'dinheiro' || f.chave == 'pix',
                ))
                  ChoiceChip(
                    label: Text(f.rotulo),
                    selected: _forma == f.chave,
                    selectedColor: dourado,
                    labelStyle: TextStyle(
                      color: _forma == f.chave ? Colors.black : Colors.white,
                    ),
                    onSelected: (_) => setState(() => _forma = f.chave),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _observacoes,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
              ),
            ),
            const SizedBox(height: 6),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: dourado,
              checkColor: Colors.black,
              value: _confirmou,
              onChanged: (v) => setState(() {
                _confirmou = v == true;
                _erro = null;
              }),
              title: const Text(
                'Confirmo que o valor foi pago ao funcionário.',
                style: TextStyle(fontSize: 14),
              ),
            ),
            const Text(
              'O pagamento será lançado no caixa como despesa.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            if (_erro != null) ...[
              const SizedBox(height: 8),
              Text(_erro!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: _confirmar,
          style: ElevatedButton.styleFrom(
            backgroundColor: dourado,
            foregroundColor: Colors.black,
          ),
          child: const Text('PAGAR'),
        ),
      ],
    );
  }
}
