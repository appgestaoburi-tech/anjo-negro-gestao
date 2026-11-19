import 'package:cloud_firestore/cloud_firestore.dart';

class Funcionario {
  final String uid;
  final String nome;
  final String email;
  final String cargo;
  final bool ativo;
  final bool permissaoTotal;
  final int comissaoBp; // 5000 = 50,00%
  final Map<String, bool> permissoes;

  const Funcionario({
    required this.uid,
    required this.nome,
    required this.email,
    required this.cargo,
    required this.ativo,
    required this.permissaoTotal,
    required this.comissaoBp,
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
    return Funcionario(
      uid: doc.id,
      nome: (d['nome'] ?? '').toString(),
      email: (d['email'] ?? '').toString(),
      cargo: (d['cargo'] ?? '').toString().toLowerCase().trim(),
      ativo: d['ativo'] == true,
      permissaoTotal: d['permissaoTotal'] == true,
      comissaoBp: (d['comissaoBp'] as num?)?.toInt() ?? 0,
      permissoes: perms,
    );
  }

  String get rotuloCargo {
    if (cargo == 'admin' || cargo == 'administrador') return 'Administrador';
    if (cargo == 'admin_equipe') return 'Administrador de equipe';
    return 'Colaborador';
  }

  String get comissaoTexto {
    if (comissaoBp % 100 == 0) return '${comissaoBp ~/ 100}%';
    return '${(comissaoBp / 100).toStringAsFixed(2).replaceAll('.', ',')}%';
  }
}
