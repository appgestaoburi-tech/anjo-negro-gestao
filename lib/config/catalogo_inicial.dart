class ServicoInicial {
  final String id;
  final String nome;
  final String categoria;
  final int precoCentavos;
  final bool aPartir;

  const ServicoInicial(
    this.id,
    this.nome,
    this.categoria,
    this.precoCentavos, {
    this.aPartir = false,
  });
}

const List<String> categoriasServicos = [
  'Principais',
  'Adicionais',
  'Química',
  'Coloração',
];

const List<ServicoInicial> servicosIniciais = [
  ServicoInicial('corte-freestyle', 'Corte Freestyle', 'Principais', 4500,
      aPartir: true),
  ServicoInicial('corte-cabelo', 'Corte de Cabelo', 'Principais', 3500),
  ServicoInicial('barba', 'Barba', 'Principais', 4000),
  ServicoInicial('cabelo-barba', 'Cabelo + Barba', 'Principais', 6000),
  ServicoInicial('sobrancelha', 'Sobrancelha', 'Adicionais', 1000),
  ServicoInicial('pezinho', 'Pezinho', 'Adicionais', 1000),
  ServicoInicial('mascara-negra', 'Máscara Negra', 'Adicionais', 3000),
  ServicoInicial('epilacao-cera', 'Epilação com Cera', 'Adicionais', 1500),
  ServicoInicial('alisamento', 'Alisamento', 'Química', 4000, aPartir: true),
  ServicoInicial('botox', 'Botox', 'Química', 4000, aPartir: true),
  ServicoInicial('progressiva', 'Progressiva', 'Química', 5000, aPartir: true),
  ServicoInicial('luzes', 'Luzes', 'Coloração', 7000, aPartir: true),
  ServicoInicial('descoloracao-global', 'Descoloração Global', 'Coloração',
      10000,
      aPartir: true),
  ServicoInicial(
      'pigmentacao-cabelo', 'Pigmentação (Cabelo)', 'Coloração', 1500),
  ServicoInicial(
      'pigmentacao-barba', 'Pigmentação (Barba)', 'Coloração', 1500),
];
