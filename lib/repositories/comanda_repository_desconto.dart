part of 'comanda_repository.dart';

extension ComandaRepositoryDesconto on ComandaRepository {
  /// Aplica o desconto na hora. O colaborador só pode até o limite livre
  /// ou o percentual já autorizado; o administrador pode qualquer valor.
  Future<void> aplicarDesconto(
    String comandaId,
    int bp,
    PerfilUsuario perfil,
  ) {
    return _alterar(comandaId, (c) {
      if (bp < 0 || bp > 10000) {
        throw Exception('Percentual de desconto inválido.');
      }
      if (bp > 0 && c.servicos.isEmpty) {
        throw Exception('Adicione um serviço antes de aplicar desconto.');
      }

      final admin = perfil.permissaoTotal;
      final liberado =
          bp <= limiteDescontoSemAutorizacaoBp || bp <= c.descontoAprovadoBp;

      if (!admin && !liberado) {
        throw Exception(
          'Desconto acima de ${bpParaTexto(limiteDescontoSemAutorizacaoBp)} '
          'precisa de autorização do administrador.',
        );
      }

      final campos =
          _camposAtualizados(c.servicos, c.produtos, bp, c.pagoCentavos);

      if (admin &&
          bp > limiteDescontoSemAutorizacaoBp &&
          bp > c.descontoAprovadoBp) {
        campos['descontoAprovadoBp'] = bp;
        campos['descontoStatus'] = 'aprovado';
        campos['descontoDecididoPorUid'] = perfil.uid;
        campos['descontoDecididoPorNome'] = perfil.nome;
        campos['descontoDecididoEm'] = FieldValue.serverTimestamp();
      }

      return campos;
    });
  }

  /// Pede autorização ao administrador para um desconto acima do limite.
  Future<void> solicitarDesconto(
    String comandaId,
    int bp,
    PerfilUsuario perfil,
  ) {
    return _alterar(comandaId, (c) {
      if (bp <= limiteDescontoSemAutorizacaoBp || bp > 10000) {
        throw Exception('Pedido de autorização inválido.');
      }
      if (c.servicos.isEmpty) {
        throw Exception('Adicione um serviço antes de pedir desconto.');
      }

      return <String, dynamic>{
        'descontoStatus': 'pendente',
        'descontoSolicitadoBp': bp,
        'descontoSolicitadoPorNome': perfil.nome,
        'atualizadoEm': FieldValue.serverTimestamp(),
      };
    });
  }

  Future<void> cancelarSolicitacao(String comandaId) {
    return _alterar(comandaId, (c) {
      if (!c.descontoPendente) return <String, dynamic>{};
      return <String, dynamic>{
        'descontoStatus': '',
        'descontoSolicitadoBp': 0,
        'atualizadoEm': FieldValue.serverTimestamp(),
      };
    });
  }

  /// Só o administrador decide (e o Firebase também exige isso).
  Future<void> decidirDesconto(
    String comandaId,
    bool aprovar,
    PerfilUsuario perfil,
  ) {
    if (!perfil.permissaoTotal) {
      return Future.error(
        Exception('Somente o administrador pode autorizar descontos.'),
      );
    }

    return _alterar(comandaId, (c) {
      if (!c.descontoPendente) {
        throw Exception('Não há pedido pendente nesta comanda.');
      }

      final decisao = <String, dynamic>{
        'descontoDecididoPorUid': perfil.uid,
        'descontoDecididoPorNome': perfil.nome,
        'descontoDecididoEm': FieldValue.serverTimestamp(),
      };

      if (!aprovar) {
        return <String, dynamic>{
          ...decisao,
          'descontoStatus': 'recusado',
          'atualizadoEm': FieldValue.serverTimestamp(),
        };
      }

      final bp = c.descontoSolicitadoBp;

      return <String, dynamic>{
        ..._camposAtualizados(c.servicos, c.produtos, bp, c.pagoCentavos),
        ...decisao,
        'descontoStatus': 'aprovado',
        'descontoAprovadoBp': bp,
      };
    });
  }
}
