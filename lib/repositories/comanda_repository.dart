import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cliente.dart';
import '../models/comanda.dart';
import '../models/perfil_usuario.dart';
import '../models/produto.dart';
import '../models/servico.dart';

class ComandaRepository {
  ComandaRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('comandas');

  CollectionReference<Map<String, dynamic>> get _produtos =>
      _firestore.collection('produtos');

  /// Administrador vê todas as abertas; os demais, só as próprias.
  Stream<List<Comanda>> observarAbertas(PerfilUsuario perfil) {
    Query<Map<String, dynamic>> consulta =
        _col.where('status', isEqualTo: 'aberta');

    if (!perfil.permissaoTotal) {
      consulta = consulta.where('barbeiroUid', isEqualTo: perfil.uid);
    }

    return consulta.snapshots().map((snap) {
      final lista = snap.docs.map(Comanda.doDocumento).toList();
      lista.sort((a, b) => b.numero.compareTo(a.numero));
      return lista;
    });
  }

  Stream<Comanda?> observarUma(String id) {
    return _col
        .doc(id)
        .snapshots()
        .map((d) => d.exists ? Comanda.doDocumento(d) : null);
  }

  /// Abre a comanda e gera o número sequencial em uma única transação.
  Future<String> criar(PerfilUsuario perfil, {Cliente? cliente}) async {
    final contador = _firestore.collection('contadores').doc('comandas');
    final novaRef = _col.doc();

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(contador);
      final numero =
          snap.exists ? ((snap.data()?['proximo'] as num?)?.toInt() ?? 1) : 1;

      if (snap.exists) {
        tx.update(contador, {'proximo': numero + 1});
      } else {
        tx.set(contador, {'proximo': 2});
      }

      tx.set(novaRef, {
        'numero': numero,
        'status': 'aberta',
        'barbeiroUid': perfil.uid,
        'barbeiroNome': perfil.nome,
        'clienteId': cliente?.id ?? '',
        'clienteNome': cliente?.nome ?? '',
        'servicos': <Map<String, dynamic>>[],
        'produtos': <Map<String, dynamic>>[],
        'subtotalServicosCentavos': 0,
        'subtotalProdutosCentavos': 0,
        'descontoCentavos': 0,
        'totalCentavos': 0,
        'pagoCentavos': 0,
        'criadoEm': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    });

    return novaRef.id;
  }

  /// Recalcula subtotais e total a partir das listas de itens.
  Map<String, dynamic> _camposAtualizados(
    List<ItemComanda> servicos,
    List<ItemProduto> produtos,
    int descontoCentavos,
  ) {
    final subServicos = servicos.fold<int>(0, (s, i) => s + i.precoCentavos);
    final subProdutos = produtos.fold<int>(0, (s, i) => s + i.totalCentavos);

    return {
      'servicos': servicos.map((i) => i.paraMapa()).toList(),
      'produtos': produtos.map((i) => i.paraMapa()).toList(),
      'subtotalServicosCentavos': subServicos,
      'subtotalProdutosCentavos': subProdutos,
      'totalCentavos': subServicos + subProdutos - descontoCentavos,
      'atualizadoEm': FieldValue.serverTimestamp(),
    };
  }

  Future<void> _alterar(
    String id,
    Map<String, dynamic> Function(Comanda c) monta,
  ) async {
    await _firestore.runTransaction((tx) async {
      final ref = _col.doc(id);
      final snap = await tx.get(ref);

      if (!snap.exists) throw Exception('Comanda não encontrada.');

      final c = Comanda.doDocumento(snap);
      if (!c.aberta) throw Exception('Esta comanda não está mais aberta.');

      tx.update(ref, monta(c));
    });
  }

  // ---------------- Serviços ----------------

  Future<void> adicionarServico(String comandaId, Servico s) {
    final item = ItemComanda(
      id: _col.doc().id,
      servicoId: s.id,
      nome: s.nome,
      categoria: s.categoria,
      precoCatalogoCentavos: s.precoCentavos,
      precoCentavos: s.precoCentavos,
      aPartir: s.aPartir,
    );

    return _alterar(
      comandaId,
      (c) => _camposAtualizados(
        [...c.servicos, item],
        c.produtos,
        c.descontoCentavos,
      ),
    );
  }

  Future<void> removerServico(String comandaId, String itemId) {
    return _alterar(
      comandaId,
      (c) => _camposAtualizados(
        c.servicos.where((i) => i.id != itemId).toList(),
        c.produtos,
        c.descontoCentavos,
      ),
    );
  }

  /// Só serviços "a partir de" podem ter o preço alterado, e só para cima.
  Future<void> ajustarPreco(String comandaId, String itemId, int novo) {
    return _alterar(comandaId, (c) {
      final servicos = c.servicos.map((i) {
        if (i.id != itemId) return i;
        if (!i.aPartir) throw Exception('O preço deste serviço é fixo.');
        if (novo < i.precoCatalogoCentavos) {
          throw Exception('O valor não pode ser menor que o do catálogo.');
        }
        return i.comPreco(novo);
      }).toList();

      return _camposAtualizados(servicos, c.produtos, c.descontoCentavos);
    });
  }

  // ---------------- Produtos ----------------

  /// Confere a quantidade desejada contra o estoque atual do produto.
  void _validarEstoque(Produto p, int desejada) {
    if (!p.ativo) throw Exception('Este produto está desativado.');
    if (p.estoqueQtd <= 0) throw Exception('Produto sem estoque.');
    if (desejada > p.estoqueQtd) {
      throw Exception(
        'Estoque insuficiente: há apenas ${p.estoqueQtd} '
        'unidade(s) de ${p.nome}.',
      );
    }
  }

  /// O estoque NÃO é alterado aqui: a baixa acontece só na finalização.
  /// A conferência usa o estoque atual lido do servidor.
  Future<void> adicionarProduto(String comandaId, Produto p) async {
    await _firestore.runTransaction((tx) async {
      final comandaRef = _col.doc(comandaId);
      final produtoRef = _produtos.doc(p.id);

      final comandaSnap = await tx.get(comandaRef);
      final produtoSnap = await tx.get(produtoRef);

      if (!comandaSnap.exists) throw Exception('Comanda não encontrada.');
      if (!produtoSnap.exists) throw Exception('Produto não encontrado.');

      final c = Comanda.doDocumento(comandaSnap);
      final atual = Produto.doDocumento(produtoSnap);

      if (!c.aberta) throw Exception('Esta comanda não está mais aberta.');

      final produtos = [...c.produtos];
      final indice = produtos.indexWhere((x) => x.produtoId == atual.id);
      final quantidadeAtual = indice >= 0 ? produtos[indice].quantidade : 0;

      _validarEstoque(atual, quantidadeAtual + 1);

      if (indice >= 0) {
        produtos[indice] =
            produtos[indice].comQuantidade(quantidadeAtual + 1);
      } else {
        produtos.add(
          ItemProduto(
            id: _col.doc().id,
            produtoId: atual.id,
            nome: atual.nome,
            precoCentavos: atual.precoVendaCentavos,
            quantidade: 1,
          ),
        );
      }

      tx.update(
        comandaRef,
        _camposAtualizados(c.servicos, produtos, c.descontoCentavos),
      );
    });
  }

  /// Aumentar a quantidade exige estoque suficiente; diminuir é sempre livre.
  Future<void> alterarQuantidadeProduto(
    String comandaId,
    String itemId,
    int quantidade,
  ) async {
    await _firestore.runTransaction((tx) async {
      final comandaRef = _col.doc(comandaId);
      final comandaSnap = await tx.get(comandaRef);

      if (!comandaSnap.exists) throw Exception('Comanda não encontrada.');

      final c = Comanda.doDocumento(comandaSnap);
      if (!c.aberta) throw Exception('Esta comanda não está mais aberta.');

      final indice = c.produtos.indexWhere((i) => i.id == itemId);
      if (indice < 0) throw Exception('Produto não encontrado na comanda.');

      final item = c.produtos[indice];

      if (quantidade > item.quantidade) {
        final produtoSnap = await tx.get(_produtos.doc(item.produtoId));
        if (!produtoSnap.exists) throw Exception('Produto não encontrado.');
        _validarEstoque(Produto.doDocumento(produtoSnap), quantidade);
      }

      final produtos = <ItemProduto>[];
      for (final i in c.produtos) {
        if (i.id != itemId) {
          produtos.add(i);
        } else if (quantidade >= 1) {
          produtos.add(i.comQuantidade(quantidade));
        }
      }

      tx.update(
        comandaRef,
        _camposAtualizados(c.servicos, produtos, c.descontoCentavos),
      );
    });
  }

  Future<void> removerProduto(String comandaId, String itemId) {
    return _alterar(
      comandaId,
      (c) => _camposAtualizados(
        c.servicos,
        c.produtos.where((i) => i.id != itemId).toList(),
        c.descontoCentavos,
      ),
    );
  }

  // ---------------- Cancelamento ----------------

  /// Cancela sem apagar: o histórico fica registrado.
  Future<void> cancelar(
    String id,
    PerfilUsuario perfil, {
    String motivo = '',
  }) async {
    await _firestore.runTransaction((tx) async {
      final ref = _col.doc(id);
      final snap = await tx.get(ref);

      if (!snap.exists) throw Exception('Comanda não encontrada.');

      final c = Comanda.doDocumento(snap);
      if (!c.aberta) throw Exception('Esta comanda não está mais aberta.');
      if (c.pagoCentavos > 0) {
        throw Exception(
          'Não é possível cancelar uma comanda com pagamento registrado.',
        );
      }

      tx.update(ref, {
        'status': 'cancelada',
        'motivoCancelamento': motivo,
        'canceladoPor': perfil.uid,
        'canceladoEm': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    });
  }
}
