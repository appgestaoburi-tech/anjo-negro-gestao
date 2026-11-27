import 'package:flutter/material.dart';
import '../../config/tema.dart';
import '../../models/comanda.dart';
import '../../models/pacote.dart';
import '../../models/pacote_cliente.dart';
import '../../models/perfil_usuario.dart';
import '../../repositories/pacote_cliente_repository.dart';
import '../../repositories/pacote_uso_repository.dart';
import '../../utils/datas.dart';
import '../../utils/erros.dart';
import '../../utils/pacote_calculo.dart';

class CartaoUsoPacote extends StatefulWidget {
  final Comanda comanda;
  final PerfilUsuario perfil;

  const CartaoUsoPacote({
    super.key,
    required this.comanda,
    required this.perfil,
  });

  @override
  State<CartaoUsoPacote> createState() => _CartaoUsoPacoteState();
}

class _CartaoUsoPacoteState extends State<CartaoUsoPacote> {
  late final Stream<List<PacoteCliente>> _stream =
      PacoteClienteRepository().observarDoCliente(widget.comanda.clienteId);

  String? _ocupado;

  Future<void> _usar(PacoteCliente p, ItemPacote i) async {
    setState(() => _ocupado = '${p.id}_${i.servicoId}');

    try {
      await PacoteUsoRepository().usar(
        comandaId: widget.comanda.id,
        pacoteId: p.id,
        servicoId: i.servicoId,
        perfil: widget.perfil,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagemDeErro(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _ocupado = null);
    }
  }

  String? _bloqueio(PacoteCliente p, ItemPacote i, int ciclo) {
    if (p.usosTotal >= p.totalUsos || p.usado(i.servicoId) >= i.qtdTotal) {
      return 'Todos usados';
    }
    if (p.usadoNoCiclo(i.servicoId, ciclo) >= i.maxPorMes) {
      return 'Limite do mês';
    }
    return null;
  }

  Widget _linhaItem(PacoteCliente p, ItemPacote i, int ciclo) {
    final bloqueio = _bloqueio(p, i, ciclo);
    final ocupado = _ocupado == '${p.id}_${i.servicoId}';

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i.servicoNome,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Neste mês: ${p.usadoNoCiclo(i.servicoId, ciclo)} de '
                  '${i.maxPorMes} • Total: ${p.usado(i.servicoId)} de '
                  '${i.qtdTotal}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          if (bloqueio != null)
            Text(
              bloqueio,
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            ElevatedButton(
              onPressed: _ocupado != null ? null : () => _usar(p, i),
              style: ElevatedButton.styleFrom(
                backgroundColor: dourado,
                foregroundColor: Colors.black,
              ),
              child: ocupado
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text('USAR'),
            ),
        ],
      ),
    );
  }

  Widget _cartaoPacote(PacoteCliente p) {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);

    var ciclo = cicloDe(p.inicioData, hoje);
    if (ciclo >= p.meses) ciclo = p.meses - 1;

    final ultimoDia = p.fimData.subtract(const Duration(days: 1));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cartao,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: dourado),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.nome,
            style: const TextStyle(
              color: dourado,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          Text(
            'Vence em ${formatarDia(ultimoDia)}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          for (final i in p.itens) _linhaItem(p, i, ciclo),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PacoteCliente>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final agora = DateTime.now();
        final ativos = snapshot.data!
            .where((p) => p.situacao(agora) == 'ativo')
            .toList();

        if (ativos.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),
            const Text(
              'PACOTE DO CLIENTE',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            for (final p in ativos) _cartaoPacote(p),
          ],
        );
      },
    );
  }
}
