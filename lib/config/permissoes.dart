class PermissaoInfo {
  final String chave;
  final String rotulo;

  const PermissaoInfo(this.chave, this.rotulo);
}

const List<PermissaoInfo> permissoesDisponiveis = [
  PermissaoInfo('gerenciar_catalogo', 'Gerenciar catálogo de serviços'),
  PermissaoInfo('gerenciar_produtos', 'Gerenciar produtos e estoque'),
  PermissaoInfo('aprovar_descontos', 'Aprovar descontos acima de 15%'),
  PermissaoInfo('ver_caixa', 'Ver o caixa'),
  PermissaoInfo('lancar_despesas', 'Lançar despesas'),
  PermissaoInfo('ver_relatorios', 'Ver relatórios gerais'),
  PermissaoInfo('gerenciar_vales', 'Aprovar vales e adiantamentos'),
];
