import 'package:flutter/material.dart';
import '../../config/tema.dart';
import '../../models/pacote_cliente.dart';
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

  Widget _conteudo(PacoteCliente p) {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final situacao = p.situacao(agora);

    var ciclo = cicloDe(p.inicioData, hoje);
    if (ciclo >= p.meses) ciclo = p.meses - 1;

    final cicloIni = somarMeses(p.inicioData, ciclo);
    final cicloFimExcl = somarMeses(p.inicioData, ciclo + 1);
    final cicloFim = DateTime(
      cicloFimExcl.year,
      cicloFimExcl.month,
      cicloFimExcl.day - 1,
    );
    final ultimoDia = p.fimData.subtract(const Duration(days: 1));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _cartao(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.clienteNome,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
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
                  Dinheiro.formatar(
                    p.precoTabelaCentavos - p.precoPagoCentavos,
                  ),
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
        ),
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
        _titulo('HISTÓRICO DE USOS'),
        const Text(
          'Os usos lançados nas comandas aparecerão aqui (próxima etapa).',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 20),
      ],
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

          return _conteudo(p);
        },
      ),
    );
  }
}
