import 'package:flutter/material.dart';
import '../config/tema.dart';
import '../models/pacote_cliente.dart';
import '../repositories/pacote_cliente_repository.dart';
import '../screens/pacotes/pacotes_clientes_screen.dart';
import '../utils/dinheiro.dart';

void _abrirLista(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const PacotesClientesScreen()),
  );
}

/// Dinheiro recebido em pacotes que ainda corresponde a serviços a prestar.
class CartaoPacotesCaixa extends StatefulWidget {
  const CartaoPacotesCaixa({super.key});

  @override
  State<CartaoPacotesCaixa> createState() => _CartaoPacotesCaixaState();
}

class _CartaoPacotesCaixaState extends State<CartaoPacotesCaixa> {
  late final Stream<List<PacoteCliente>> _stream =
      PacoteClienteRepository().observarTodos();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PacoteCliente>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final agora = DateTime.now();
        var aPrestar = 0;
        var ativos = 0;
        var vencidoSemUso = 0;

        for (final p in snapshot.data!) {
          final situacao = p.situacao(agora);
          if (situacao == 'ativo') {
            aPrestar += p.aPrestarCentavos;
            ativos++;
          } else if (situacao == 'vencido') {
            vencidoSemUso += p.aPrestarCentavos;
          }
        }

        return InkWell(
          onTap: () => _abrirLista(context),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cartao,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: bordaCartao),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.card_giftcard, color: dourado, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'PACOTES • SERVIÇOS A PRESTAR',
                        style: TextStyle(
                          color: dourado,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white38),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  Dinheiro.formatar(aPrestar),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                Text(
                  '$ativos pacote(s) ativo(s). Já está no caixa, mas os '
                  'usos ainda não foram feitos.',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                if (vencidoSemUso > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Vencidos com saldo não usado: '
                    '${Dinheiro.formatar(vencidoSemUso)} '
                    '(receita da barbearia)',
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Clientes cujo pacote vence nos próximos 7 dias e ainda tem usos.
class CartaoPacotesVencendo extends StatefulWidget {
  const CartaoPacotesVencendo({super.key});

  @override
  State<CartaoPacotesVencendo> createState() => _CartaoPacotesVencendoState();
}

class _VencendoItem {
  final PacoteCliente pacote;
  final int dias;

  const _VencendoItem(this.pacote, this.dias);
}

class _CartaoPacotesVencendoState extends State<CartaoPacotesVencendo> {
  late final Stream<List<PacoteCliente>> _stream =
      PacoteClienteRepository().observarTodos();

  String _quando(int dias) {
    if (dias == 0) return 'vence hoje';
    if (dias == 1) return 'vence amanhã';
    return 'vence em $dias dias';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PacoteCliente>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final agora = DateTime.now();
        final hoje = DateTime(agora.year, agora.month, agora.day);

        final lista = <_VencendoItem>[];
        for (final p in snapshot.data!) {
          if (p.situacao(agora) != 'ativo' || p.restantes <= 0) continue;

          final ultimoDia = p.fimData.subtract(const Duration(days: 1));
          final dias = ultimoDia.difference(hoje).inDays;

          if (dias >= 0 && dias <= 7) lista.add(_VencendoItem(p, dias));
        }

        if (lista.isEmpty) return const SizedBox.shrink();

        lista.sort((a, b) => a.dias.compareTo(b.dias));

        return InkWell(
          onTap: () => _abrirLista(context),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cartao,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.orangeAccent),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.event_busy,
                      color: Colors.orangeAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'PACOTES VENCENDO (${lista.length})',
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white38),
                  ],
                ),
                const SizedBox(height: 8),
                for (final item in lista.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${item.pacote.clienteNome} • ${item.pacote.nome} • '
                      '${_quando(item.dias)} (restam '
                      '${item.pacote.restantes} usos)',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                if (lista.length > 3)
                  Text(
                    '+ ${lista.length - 3} outro(s)',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
