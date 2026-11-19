class PerfilUsuario {
  final String uid;
  final String nome;
  final String cargo;
  final bool permissaoTotal;
  final Map<String, bool> permissoes;

  const PerfilUsuario({
    required this.uid,
    required this.nome,
    required this.cargo,
    required this.permissaoTotal,
    this.permissoes = const {},
  });

  bool get   String get rotuloCargo {
    if (administrador) return 'Administrador';
    if (cargo == 'admin_equipe') return 'Administrador de equipe';
    return 'Colaborador';
  }

  String get primeiroNome {
    final p = nome.trim().split(' ').first;
    return p.isEmpty ? 'Usuário' : p;
  }

  /// Administrador total pode tudo; os demais, só o que foi liberado.
  bool pode(String permissao) =>
      permissaoTotal || permissoes[permissao] == true;
}
