import 'package:flutter/material.dart';
import '../../config/tema.dart';
import '../../utils/dinheiro.dart';
import '../../utils/percentual.dart';

class DialogDesconto extends StatefulWidget {
  final int atualBp;
  final int subtotalServicosCentavos;
  final int limiteLivreBp;

  const DialogDesconto({
    super.key,
    required this.atualBp,
    required this.subtotalServicosCentavos,
    required this.limiteLivreBp,
  });

  @override
  State<DialogDesconto> createState() => _DialogDescontoState();
}

class _DialogDescontoState extends State<DialogDesconto> {
  late final TextEditingController _valor;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _valor = TextEditingController(
      text: widget.atualBp == 0
          ? ''
          : bpParaTexto(widget.atualBp).replaceAll('%', ''),
    );
  }

  @override
  void dispose() {
    _valor.dispose();
    super.dispose();
  }

  int get _descontoCentavos {
    final bp = percentualParaBp(_valor.text) ?? 0;
    return (widget.subtotalServicosCentavos * bp + 5000) ~/ 10000;
  }

  void _confirmar() {
    final texto = _valor.text.trim();
    final bp = texto.isEmpty ? 0 : percentualParaBp(texto);

    if (bp == null) {
      setState(() => _erro = 'Informe um percentual entre 0 e 100.');
      return;
    }

    Navigator.pop(context, bp);
  }

  @override
  Widget build(BuildContext context) {
    final bp = percentualParaBp(_valor.text) ?? 0;
    final precisaAutorizacao = bp > widget.limiteLivreBp;

    return AlertDialog(
      backgroundColor: cartao,
      title: const Text('Desconto', style: TextStyle(color: dourado)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'O desconto vale sobre os serviços '
              '(${Dinheiro.formatar(widget.subtotalServicosCentavos)}). '
              'Até ${bpParaTexto(widget.limiteLivreBp)} é aplicado na hora.',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _valor,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() => _erro = null),
              decoration: const InputDecoration(
                labelText: 'Desconto (%)',
                helperText: 'Deixe vazio para remover o desconto',
                prefixIcon: Icon(Icons.percent),
              ),
            ),
            const SizedBox(height: 12),
            if (bp > 0)
              Text(
                'Desconto: − ${Dinheiro.formatar(_descontoCentavos)}',
                style: const TextStyle(
                  color: dourado,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (precisaAutorizacao) ...[
              const SizedBox(height: 8),
              const Text(
                'Acima do limite: será enviado um pedido de autorização '
                'ao administrador.',
                style: TextStyle(color: Colors.orangeAccent, fontSize: 13),
              ),
            ],
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
          child: Text(precisaAutorizacao ? 'PEDIR AUTORIZAÇÃO' : 'APLICAR'),
        ),
      ],
    );
  }
}
