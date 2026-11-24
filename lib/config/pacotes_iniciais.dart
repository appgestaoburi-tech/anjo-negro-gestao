import '../models/pacote.dart';

class PacoteInicial {
  final String id;
  final String nome;
  final int meses;
  final List<ItemPacote> itens;

  const PacoteInicial(this.id, this.nome, this.meses, this.itens);
}

/// Cadastrados inativos e sem preço: o administrador define o preço e ativa.
/// Os ids dos serviços são os do catálogo inicial.
const List<PacoteInicial> pacotesIniciais = [
  PacoteInicial('mensal-1', 'Pacote mensal 1', 1, [
    ItemPacote(
      servicoId: 'corte-cabelo',
      servicoNome: 'Corte de Cabelo',
      qtdTotal: 2,
      maxPorMes: 2,
    ),
    ItemPacote(
      servicoId: 'barba',
      servicoNome: 'Barba',
      qtdTotal: 4,
      maxPorMes: 4,
    ),
  ]),
  PacoteInicial('mensal-2', 'Pacote mensal 2', 1, [
    ItemPacote(
      servicoId: 'corte-cabelo',
      servicoNome: 'Corte de Cabelo',
      qtdTotal: 4,
      maxPorMes: 4,
    ),
  ]),
  PacoteInicial('trimestral', 'Pacote trimestral', 3, [
    ItemPacote(
      servicoId: 'corte-cabelo',
      servicoNome: 'Corte de Cabelo',
      qtdTotal: 12,
      maxPorMes: 4,
    ),
  ]),
  PacoteInicial('semestral', 'Pacote semestral', 6, [
    ItemPacote(
      servicoId: 'corte-cabelo',
      servicoNome: 'Corte de Cabelo',
      qtdTotal: 26,
      maxPorMes: 5,
    ),
  ]),
];
