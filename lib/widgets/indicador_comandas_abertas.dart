import 'package:flutter/material.dart';
import '../models/comanda.dart';
import '../models/perfil_usuario.dart';
import '../repositories/comanda_repository.dart';
import 'cards_painel.dart';

class IndicadorComandasAbertas extends StatefulWidget {
  final PerfilUsuario perfil;

  const IndicadorComandasAbertas({super.key, required this.perfil});

  @override
  State<IndicadorComandasAbertas> createState() =>
      _IndicadorComandasAbertasState();
}

class _IndicadorComandasAbertasState extends State<IndicadorComandasAbertas> {
  late final Stream<List<Comanda>> _stream =
      ComandaRepository().observarAbertas(widget.perfil);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Comanda>>(
      stream: _stream,
      builder: (context, snapshot) {
        return IndicadorCard(
          titulo: 'Comandas abertas',
          valor: snapshot.hasData ? '${snapshot.data!.length}' : '—',
          icone: Icons.receipt_long,
        );
      },
    );
  }
}
