import 'package:flutter/material.dart';
import '../../config/formas_pagamento.dart';
import '../../config/tema.dart';
import '../../utils/dinheiro.dart';

class ResultadoPagamento {
  final String forma;
  final int valorCentavos;
  final int recebidoCentavos;

  const ResultadoPagamento({
    required this.forma,
    required this.valorCentavos,
    required this.recebidoCentavos,
  });
}

class DialogPagamento extends StatefulWidget {
  final int saldoCentavos;

  const DialogPagamento({super.key, required this.saldoCentavos});

  @override
  State<DialogPagamento> createState() => _DialogPagamentoState();
}

class _DialogPagamentoState extends State<DialogPagamento> {
  final _valor = TextEditingController();
  final _recebido = TextEditingController();

  String _forma = 'dinheiro';
  bool _confirmou = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    final s = widget.saldoCentavos;
    _valor.text = '${s ~/ 100},${(s % 100).toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _valor.dispose();
    _recebido.dispose();
    super.dispose();
  }

  void _confirmar() {
    final valor = Dinheiro.paraCentavos(_valor.text);

    if (valor == null || valor <= 0) {
      setState(() => _erro = 'Informe um valor válido.');
      return;
    }
    if (valor > widget.saldoCentavos) {
      setState(() {
        _erro = 'O valor passa do saldo '
            '(${Dinheiro.formatar(widget.saldoCentavos)}).';
      });
      return;
    }

    var recebido = 0;
    if (_forma == 'dinheiro' && _recebido.text.trim().isNotEmpty) {
      final r = Dinheiro.paraCentavos(_recebido.text);
      if (r == null || r < valor) {
        setState(() {
          _erro = 'O valor recebido não pode ser menor que o pagamento.';
        });
        return;
      }
      recebido = r;
    }

    if (!_confirmou) {
      setState(() => _erro = 'Marque a confirmação de recebimento.');
      return;
    }

    Navigator.pop(
      context,
      ResultadoPagamento(
        forma: _forma,
        valorCentavos: valor,
        recebidoCentavos: recebido,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final valor = Dinheiro.paraCentavos(_valor.text) ?? 0;
    final restante = widget.saldoCentavos - valor;
    final recebido = Dinheiro.paraCentavos(_recebido.text) ?? 0;
    final troco = (_forma == 'dinheiro' && recebido > valor && valor > 0)
        ? recebido - valor
        : 0;

    String? dica;
    if (_forma == 'pix') {
      dica = 'Confira no app do banco que o Pix entrou antes de confirmar.';
    } else if (_forma == 'debito' || _forma == 'credito') {
      dica = 'Confirme que a maquininha aprovou a transação.';
    }

    return AlertDialog(
      backgroundColor: cartao,
      title: const Text('Receber pagamento', style: TextStyle(color: dourado)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saldo a receber: ${Dinheiro.formatar(widget.saldoCentavos)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: dourado,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in formasPagamento)
                  ChoiceChip(
                    avatar: Icon(
                      f.icone,
                      size: 18,
                      color: _forma == f.chave ? Colors.black : Colors.white70,
                    ),
                    label: Text(f.rotulo),
                    selected: _forma == f.chave,
                    selectedColor: dourado,
                    labelStyle: TextStyle(
                      color: _forma == f.chave ? Colors.black : Colors.white,
                    ),
                    onSelected: (_) => setState(() {
                      _forma = f.chave;
                      _erro = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _valor,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() => _erro = null),
              decoration: const InputDecoration(
                labelText: 'Valor deste pagamento (R\$)',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            if (valor > 0 && restante > 0) ...[
              const SizedBox(height: 6),
              Text(
                'Pagamento parcial: restará ${Dinheiro.formatar(restante)}.',
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 13,
                ),
              ),
            ],
            if (_forma == 'dinheiro') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _recebido,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() => _erro = null),
                decoration: const InputDecoration(
                  labelText: 'Valor recebido do cliente (opcional)',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
              if (troco > 0) ...[
                const SizedBox(height: 6),
                Text(
                  'Troco: ${Dinheiro.formatar(troco)}',
                  style: const TextStyle(
                    color: dourado,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
            if (dica != null) ...[
              const SizedBox(height: 10),
              Text(
                dica,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
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
                'Confirmo que o valor foi recebido.',
                style: TextStyle(fontSize: 14),
              ),
            ),
            if (_erro != null) ...[
              const SizedBox(height: 6),
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
          child: const Text('REGISTRAR'),
        ),
      ],
    );
  }
}
