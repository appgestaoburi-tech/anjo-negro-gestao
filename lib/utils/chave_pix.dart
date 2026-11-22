class TipoChavePix {
  final String chave;
  final String rotulo;
  final String dica;

  const TipoChavePix(this.chave, this.rotulo, this.dica);
}

const List<TipoChavePix> tiposChavePix = [
  TipoChavePix('telefone', 'Telefone', 'DDD + número. O +55 é colocado sozinho.'),
  TipoChavePix('cpf', 'CPF', 'Só os 11 números. Pontos e traço são removidos.'),
  TipoChavePix('cnpj', 'CNPJ', 'Só os 14 números. Pontos, barra e traço são removidos.'),
  TipoChavePix('email', 'E-mail', 'Igual ao e-mail cadastrado como chave no banco.'),
  TipoChavePix('aleatoria', 'Chave aleatória', 'Cole a chave inteira, com os hífens.'),
];

final RegExp _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Descobre o tipo de uma chave já salva.
String tipoDaChave(String chave) {
  final c = chave.trim();
  if (c.isEmpty) return 'telefone';
  if (c.contains('@')) return 'email';
  if (c.startsWith('+')) return 'telefone';
  if (_uuid.hasMatch(c)) return 'aleatoria';

  final digitos = c.replaceAll(RegExp(r'\D'), '');
  if (digitos.length == 14) return 'cnpj';
  if (digitos.length == 11) return 'cpf';
  return 'telefone';
}

/// Devolve a chave no formato que o banco exige, ou lança Exception
/// com a mensagem do que está errado.
String normalizarChavePix(String tipo, String texto) {
  final t = texto.trim();
  final digitos = t.replaceAll(RegExp(r'\D'), '');

  switch (tipo) {
    case 'cpf':
      if (digitos.length != 11) {
        throw Exception('O CPF deve ter 11 números.');
      }
      return digitos;

    case 'cnpj':
      if (digitos.length != 14) {
        throw Exception('O CNPJ deve ter 14 números.');
      }
      return digitos;

    case 'telefone':
      var d = digitos;
      if ((d.length == 12 || d.length == 13) && d.startsWith('55')) {
        d = d.substring(2);
      }
      if (d.length != 10 && d.length != 11) {
        throw Exception('Telefone inválido. Informe o DDD e o número.');
      }
      return '+55$d';

    case 'email':
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)) {
        throw Exception('E-mail inválido.');
      }
      return t;

    case 'aleatoria':
      if (!_uuid.hasMatch(t)) {
        throw Exception(
          'Chave aleatória inválida. Cole a chave inteira, com os hífens.',
        );
      }
      return t.toLowerCase();

    default:
      throw Exception('Escolha o tipo da chave.');
  }
}
