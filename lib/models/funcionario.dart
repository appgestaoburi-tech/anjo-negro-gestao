import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/percentual.dart';

class Funcionario {
  final String uid;
  final String nome;
  final String email;
  final String cargo;
  final bool ativo;
  final bool permissaoTotal;
  final int comissaoBp; // padrão de serviços: 5000 = 50,00%
  final int? comissaoProdutosBp; // nulo = ainda não definido
  final Map<String, int> comissaoCategoriasBp; // exceções por categoria
  final Map<String, bool> permissoes;

  const Funcionario({
    required this.uid,
    required this.nome,
    required this.email,
    required this.cargo,
    required this.ativo,
    required this.permissaoTotal,
    required this.comissaoBp,
    required this.comissaoProdutosBp,
    required this.comissaoCategoriasBp,
    required this.permissoes,
  });

  factory Funcionario.doDocumento(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};

    final perms = <String, bool>{};
    final brutas = d['permissoes'];
    if (brutas is Map) {
      brutas.forEach((k, v) {
        if (v == true) perms[k.toString()] = true;
      });
    }

    final cats = <String, int>{};
    final brutasCats = d['comissaoCategoriasBp'];
    if (brutasCats is Map) {
      brutasCats.forEach((k, v) {
        if (v is num) cats[k.toString()] = v.toInt();
      });
    }

    return Funcionario(
      uid: doc.id,
      nome: (d['nome'] ?? '').toString(),
      email: (d['email'] ?? '').toString(),
      cargo: (d['cargo'] ?? '').toString().toLowerCase().trim(),
      ativo: d['ativo'] == true,
      permissaoTotal: d['permissaoTotal'] == true,
      comissaoBp: (d['comissaoBp'] as num?)?.toInt() ?? 0,
      comissaoProdutosBp: (d['comissaoProdutosBp'] as num?)?.toInt(),
      comissaoCategoriasBp: cats,
      permissoes: perms,
    );
  }

  String get rotuloCargo {
    if (cargo == 'admin' || cargo == 'administrador') return 'Administrador';
    if (cargo == 'admin_equipe') return 'Administrador de equipe';
    return 'Colaborador';
  }

  String get comissaoTexto => bpParaTexto(comissaoBp);

  String get comissaoProdutosTexto =>
      comissaoProdutosBp == null ? 'não definida' : bpParaTexto(comissaoProdutosBp!);
}
