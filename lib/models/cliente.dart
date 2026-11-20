import 'package:cloud_firestore/cloud_firestore.dart';

class Cliente {
  final String id;
  final String nome;
  final String telefone; // só dígitos
  final String nascimento; // aaaa-mm-dd ou vazio
  final String observacoes;

  const Cliente({
    required this.id,
    required this.nome,
    required this.telefone,
    required this.nascimento,
    required this.observacoes,
  });

  factory Cliente.doDocumento(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return Cliente(
      id: doc.id,
      nome: (d['nome'] ?? '').toString(),
      telefone: (d['telefone'] ?? '').toString(),
      nascimento: (d['nascimento'] ?? '').toString(),
      observacoes: (d['observacoes'] ?? '').toString(),
    );
  }

  /// Minúsculas e sem acento, para a pesquisa.
  static String normalizar(String texto) {
    const de = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const para = 'aaaaaeeeeiiiiooooouuuucn';
    var r = texto.toLowerCase().trim();
    for (var i = 0; i < de.length; i++) {
      r = r.replaceAll(de[i], para[i]);
    }
    return r;
  }

  String get telefoneFormatado {
    final t = telefone;
    if (t.length == 11) {
      return '(${t.substring(0, 2)}) ${t.substring(2, 7)}-${t.substring(7)}';
    }
    if (t.length == 10) {
      return '(${t.substring(0, 2)}) ${t.substring(2, 6)}-${t.substring(6)}';
    }
    return t;
  }

  String get nascimentoFormatado {
    final p = nascimento.split('-');
    if (p.length != 3) return '';
    return '${p[2]}/${p[1]}/${p[0]}';
  }
}
