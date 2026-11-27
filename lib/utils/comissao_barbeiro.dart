import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comanda.dart';
import 'comissao_calculo.dart';

/// Calcula a comissão com os percentuais do barbeiro neste momento.
/// O administrador principal não gera comissão (retorna nulo).
ResultadoComissao? comissaoDoBarbeiro(
  Comanda c,
  DocumentSnapshot<Map<String, dynamic>> barbeiro,
) {
  if (!barbeiro.exists) {
    throw Exception('Cadastro do barbeiro não encontrado.');
  }

  final b = barbeiro.data() ?? <String, dynamic>{};
  if (b['permissaoTotal'] == true) return null;

  final padrao = (b['comissaoBp'] as num?)?.toInt();
  if (padrao == null) {
    throw Exception(
      'Defina a comissão de ${c.barbeiroNome} em Funcionários '
      'antes de finalizar.',
    );
  }

  final categorias = <String, int>{};
  final brutas = b['comissaoCategoriasBp'];
  if (brutas is Map) {
    brutas.forEach((k, v) {
      if (v is num) categorias[k.toString()] = v.toInt();
    });
  }

  return calcularComissao(
    comanda: c,
    servicoPadraoBp: padrao,
    categoriasBp: categorias,
    produtosBp: (b['comissaoProdutosBp'] as num?)?.toInt(),
  );
}
