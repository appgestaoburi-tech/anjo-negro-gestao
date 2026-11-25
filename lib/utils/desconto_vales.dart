import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vale.dart';

class PlanoVales {
  /// Vales pagos até o limite e ainda não descontados.
  final List<Vale> aDescontar;
  final int totalCentavos;

  /// Vales pagos depois do limite (ficam para o próximo pagamento).
  final int aposLimiteCentavos;

  const PlanoVales({
    required this.aDescontar,
    required this.totalCentavos,
    required this.aposLimiteCentavos,
  });
}

/// [limite] é o corte da semana (modo semanal). No modo livre, é nulo
/// e todos os vales pagos entram.
PlanoVales planejarVales(List<Vale> vales, {Timestamp? limite}) {
  final elegiveis = <Vale>[];
  var apos = 0;

  for (final v in vales) {
    if (v.status != 'pago' || v.saldoCentavos <= 0 || v.pagoEm == null) {
      continue;
    }

    final dentro = limite == null || v.pagoEm!.compareTo(limite) <= 0;

    if (dentro) {
      elegiveis.add(v);
    } else {
      apos += v.saldoCentavos;
    }
  }

  elegiveis.sort((a, b) => a.pagoEm!.compareTo(b.pagoEm!));

  return PlanoVales(
    aDescontar: elegiveis,
    totalCentavos: elegiveis.fold<int>(0, (s, v) => s + v.saldoCentavos),
    aposLimiteCentavos: apos,
  );
}
