import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/pagamento.dart';
import '../models/perfil_usuario.dart';
import '../utils/datas.dart';
import '../utils/dinheiro.dart';
import 'cards_painel.dart';

/// Entradas de hoje: tudo para quem vê o caixa; só o que o próprio
/// barbeiro recebeu para os demais.
class IndicadorEntradasDia extends StatefulWidget {
  final PerfilUsuario perfil;

  const IndicadorEntradasDia({super.key, required this.perfil});

  @override
  State<IndicadorEntradasDia> createState() => _IndicadorEntradasDiaState();
}

class _IndicadorEntradasDiaState extends State<IndicadorEntradasDia> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream = _criar();

  Stream<QuerySnapshot<Map<String, dynamic>>> _criar() {
    Query<Map<String, dynamic>> consulta = FirebaseFirestore.instance
        .collection('pagamentos')
        .where('dia', isEqualTo: diaIso(DateTime.now()));

    if (!widget.perfil.pode('ver_caixa')) {
      consulta = consulta.where('barbeiroUid', isEqualTo: widget.perfil.uid);
    }

    return consulta.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        var valor = '—';

        if (snapshot.hasData) {
          final total = snapshot.data!.docs
              .map(Pagamento.doDocumento)
              .where((p) => !p.estornado)
              .fold<int>(0, (soma, p) => soma + p.valorCentavos);
          valor = Dinheiro.formatar(total);
        }

        return IndicadorCard(
          titulo: 'Entradas do dia',
          valor: valor,
          icone: Icons.attach_money,
        );
      },
    );
  }
}
