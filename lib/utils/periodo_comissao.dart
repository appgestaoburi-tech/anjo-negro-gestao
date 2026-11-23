import 'package:cloud_firestore/cloud_firestore.dart';

/// Índice 1 = segunda ... 7 = domingo (igual ao DateTime.weekday).
const List<String> nomesDiasSemana = [
  '',
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
  'Domingo',
];

/// Primeiro dia (00:00) da semana de trabalho em andamento.
DateTime inicioSemanaAtual(DateTime agora, int diaInicio) {
  final dif = (agora.weekday - diaInicio + 7) % 7;
  return DateTime(agora.year, agora.month, agora.day - dif);
}

/// Último instante da última semana COMPLETA: um microssegundo antes do
/// início da semana atual. Ex.: semana de sábado a sexta, agora é sábado
/// 28/11 -> corte = sexta 27/11 às 23:59:59.999999.
Timestamp corteSemanal(DateTime agora, int diaInicio) {
  final inicio = inicioSemanaAtual(agora, diaInicio);
  return Timestamp.fromMicrosecondsSinceEpoch(
    inicio.microsecondsSinceEpoch - 1,
  );
}

/// Dia (sem hora) de um Timestamp, no fuso do aparelho.
DateTime diaDe(Timestamp t) {
  final d = t.toDate();
  return DateTime(d.year, d.month, d.day);
}
