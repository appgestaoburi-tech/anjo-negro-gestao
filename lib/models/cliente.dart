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

  /// "15/03"
  String get diaMes {
    final p = nascimento.split('-');
    if (p.length != 3) return '';
    return '${p[2]}/${p[1]}';
  }

  // ---------------- Aniversários ----------------

  static DateTime _dataNoAno(int ano, int mes, int dia) {
    // 29/02 em ano não bissexto é tratado como 28/02.
    if (mes == 2 && dia == 29) {
      final bissexto = (ano % 4 == 0 && ano % 100 != 0) || ano % 400 == 0;
      if (!bissexto) return DateTime(ano, 2, 28);
    }
    return DateTime(ano, mes, dia);
  }

  DateTime? _proximoAniversario(DateTime agora) {
    final p = nascimento.split('-');
    if (p.length != 3) return null;
    final mes = int.tryParse(p[1]);
    final dia = int.tryParse(p[2]);
    if (mes == null || dia == null) return null;

    final hoje = DateTime(agora.year, agora.month, agora.day);
    var proximo = _dataNoAno(hoje.year, mes, dia);
    if (proximo.isBefore(hoje)) {
      proximo = _dataNoAno(hoje.year + 1, mes, dia);
    }
    return proximo;
  }

  /// Dias até o próximo aniversário (0 = hoje). Nulo se não há data.
  int? diasParaAniversario(DateTime agora) {
    final proximo = _proximoAniversario(agora);
    if (proximo == null) return null;
    final hoje = DateTime.utc(agora.year, agora.month, agora.day);
    final alvo = DateTime.utc(proximo.year, proximo.month, proximo.day);
    return alvo.difference(hoje).inDays;
  }

  /// Idade que o cliente completa no próximo aniversário.
  int? anosAoFazer(DateTime agora) {
    final proximo = _proximoAniversario(agora);
    final ano = int.tryParse(nascimento.split('-').first);
    if (proximo == null || ano == null) return null;
    return proximo.year - ano;
  }

  static String rotuloDias(int dias) {
    if (dias == 0) return 'hoje';
    if (dias == 1) return 'amanhã';
    return 'em $dias dias';
  }

  /// Clientes que fazem aniversário de hoje até [dias] dias, em ordem.
  static List<Cliente> proximosAniversarios(
    List<Cliente> clientes,
    DateTime agora,
    int dias,
  ) {
    final lista = clientes.where((c) {
      final d = c.diasParaAniversario(agora);
      return d != null && d <= dias;
    }).toList();

    lista.sort((a, b) {
      final r = a
          .diasParaAniversario(agora)!
          .compareTo(b.diasParaAniversario(agora)!);
      return r != 0 ? r : normalizar(a.nome).compareTo(normalizar(b.nome));
    });

    return lista;
  }
}
