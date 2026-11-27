import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comanda.dart';
import '../models/pacote.dart';
import '../utils/totais_comanda.dart';

class PacoteVendaRepository {
  PacoteVendaRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Adiciona o pacote como uma linha da comanda, guardando uma cópia das
  /// condições (serviços, usos e duração) do momento da venda.
  Future<void> adicionarNaComanda(String comandaId, Pacote escolhido) async {
    final comandaRef = _firestore.collection('comandas').doc(comandaId);
    final pacoteRef = _firestore.collection('pacotes').doc(escolhido.id);

    await _firestore.runTransaction((tx) async {
      final comandaSnap = await tx.get(comandaRef);
      final pacoteSnap = await tx.get(pacoteRef);

      if (!comandaSnap.exists) throw Exception('Comanda não encontrada.');
      if (!pacoteSnap.exists) throw Exception('Pacote não encontrado.');

      final c = Comanda.doDocumento(comandaSnap);
      final p = Pacote.doDocumento(pacoteSnap);

      if (!c.aberta) throw Exception('Esta comanda não está mais aberta.');
      if (c.clienteId.isEmpty) {
        throw Exception(
          'Para vender pacote, abra a comanda escolhendo um cliente '
          'cadastrado.',
        );
      }
      if (!p.ativo || p.precoCentavos <= 0 || p.itens.isEmpty) {
        throw Exception('Este pacote não está disponível para venda.');
      }

      final linha = ItemComanda(
        id: _firestore.collection('comandas').doc().id,
        servicoId: '',
        nome: p.nome,
        categoria: 'Pacotes',
        precoCatalogoCentavos: p.precoCentavos,
        precoCentavos: p.precoCentavos,
        aPartir: false,
        tipo: 'pacote',
        pacoteId: p.id,
        pacote: {
          'nome': p.nome,
          'meses': p.meses,
          'precoTabelaCentavos': p.precoCentavos,
          'itens': p.itens.map((i) => i.paraMapa()).toList(),
        },
      );

      tx.update(
        comandaRef,
        camposTotais(
          [...c.servicos, linha],
          c.produtos,
          c.descontoBp,
          c.pagoCentavos,
        ),
      );
    });
  }
}
