import 'package:flutter/material.dart';
import '../../config/tema.dart';
import '../../models/pacote_cliente.dart';
import '../../models/uso_pacote.dart';
import '../../repositories/pacote_cliente_repository.dart';
import '../../utils/datas.dart';
import '../../utils/dinheiro.dart';
import '../../utils/pacote_calculo.dart';

class PacoteClienteDetalheScreen extends StatelessWidget {
  final String pacoteId;
  final PacoteClienteRepository _repo = PacoteClienteRepository();

  PacoteClienteDetalheScreen({super.key, required this.pacoteId});

  Widget _cartao(Widget filho) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cartao,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: bordaCartao),
      ),
      child: filho,
    );
  }

  Widget _titulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(
        texto,
        style: const TextStyle(
          color: dourado,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _linha(String rotulo, String valor, {Color? cor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              rotulo,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              color: cor ?? Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumo(PacoteCliente p, String situacao) {
    final ultimoDia = p.fimData.subtract(const Duration(days: 1));

    return _cartao(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.clienteNome,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          if (p.clienteTelefone.isNotEmpty)
            Text(
              p.telefoneFormatado,
              style: const TextStyle(color: Colors.white70),
            ),
          const SizedBox(height: 8),
          Text(
            '${p.nome} • ${PacoteCliente.rotuloSituacao(situacao)}',
            style: const TextStyle(
              color: dourado,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _linha(
            'Validade',
            '${formatarDia(p.inicioData)} a ${formatarDia(ultimoDia)}',
          ),
          _linha('Valor pago', Dinheiro.formatar(p.precoPagoCentavos)),
          if (p.precoTabelaCentavos > p.precoPagoCentavos)
            _linha(
              'Desconto dado',
              Dinheiro.formatar(p.precoTabelaCentavos - p.precoPagoCentavos),
              cor: Colors.orangeAccent,
            ),
          _linha('Valor de cada uso', Dinheiro.formatar(p.valorUsoCentavos)),
          _linha('Usos feitos', '${p.usosTotal} de ${p.totalUsos}'),
          _linha(
            'Serviços a prestar',
            Dinheiro.formatar(p.aPrestarCentavos),
            cor: dourado,
          ),
          _linha(
            'Vendido na comanda',
            '#${p.comandaVendaNumero} por ${p.vendidoPorNome}',
          ),
        ],
      ),
    );
  }

  Widget _saldos(PacoteCliente p) {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);

    var ciclo = cicloDe(p.inicioData, hoje);
    if (ciclo >= p.meses) ciclo = p.meses - 1;

    final cicloIni = somarMeses(p.inicioData, ciclo);
    final fimExcl = somarMeses(p.inicioData, ciclo + 1);
    final cicloFim = DateTime(fimExcl.year, fimExcl.month, fimExcl.day - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo('SALDO POR SERVIÇO'),
        Text(
          'Mês atual do pacote: ${formatarDia(cicloIni)} a '
          '${formatarDia(cicloFim)}',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 8),
        for (final i in p.itens)
          _cartao(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i.servicoNome,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                _linha(
                  'No pacote todo',
                  '${p.usado(i.servicoId)} de ${i.qtdTotal}',
                ),
                _linha(
                  'Neste mês',
                  '${p.usadoNoCiclo(i.servicoId, ciclo)} de ${i.maxPorMes}',
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _historico(String pacoteId) {
    return StreamBuilder<List<UsoPacote>>(
      stream: _repo.observarUsos(pacoteId),
      builder: (context, snapshot) {
        final usos = snapshot.data ?? const <UsoPacote>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _titulo('HISTÓRICO DE USOS'),
            if (usos.isEmpty)
              const Text(
                'Nenhum uso lançado ainda.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            for (final u in usos)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cartao,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: bordaCartao),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u.servicoNome,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: u.cancelado
                                  ? Colors.white38
                                  : Colors.white,
                              decoration: u.cancelado
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          Text(
                            '${formatarDiaIso(u.dia)} • ${u.barbeiroNome} • '
                            'comanda #${u.comandaNumero}'
                            '${u.cancelado ? ' • cancelado' : ''}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      Dinheiro.formatar(u.valorUsoCentavos),
                      style: TextStyle(
                        color: u.cancelado ? Colors.white38 : dourado,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PACOTE DO CLIENTE')),
      body: StreamBuilder<PacoteCliente?>(
        stream: _repo.observarUm(pacoteId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: dourado),
            );
          }

          final p = snapshot.data;

          if (snapshot.hasError || p == null) {
            return const Center(child: Text('Pacote não encontrado.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _resumo(p, p.situacao(DateTime.now())),
              _saldos(p),
              _historico(p.id),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}
