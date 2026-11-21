import 'package:flutter/material.dart';

class FormaPagamento {
  final String chave;
  final String rotulo;
  final IconData icone;

  const FormaPagamento(this.chave, this.rotulo, this.icone);
}

const List<FormaPagamento> formasPagamento = [
  FormaPagamento('dinheiro', 'Dinheiro', Icons.payments_outlined),
  FormaPagamento('pix', 'Pix', Icons.qr_code_2),
  FormaPagamento('debito', 'Cartão de débito', Icons.credit_card),
  FormaPagamento('credito', 'Cartão de crédito', Icons.credit_score),
];

String rotuloForma(String chave) {
  for (final f in formasPagamento) {
    if (f.chave == chave) return f.rotulo;
  }
  return chave;
}

IconData iconeForma(String chave) {
  for (final f in formasPagamento) {
    if (f.chave == chave) return f.icone;
  }
  return Icons.payments_outlined;
}
