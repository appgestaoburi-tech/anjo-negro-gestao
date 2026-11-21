import 'package:flutter/material.dart';
import '../config/tema.dart';
import '../models/comanda.dart';
import '../models/perfil_usuario.dart';
import '../repositories/comanda_repository.dart';
import '../screens/comandas/autorizacoes_screen.dart';

class CartaoAutorizacoes extends StatefulWidget {
  final PerfilUsuario perfil;

  const CartaoAutorizacoes({super.key, required this.perfil});

  @override
  State<CartaoAutorizacoes> createState() => _CartaoAutorizacoesState();
}

class _CartaoAutorizacoesState extends State<CartaoAutorizacoes> {
  late final Stream<List<Comanda>> _stream =
      ComandaRepository().observarPendentes();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Comanda>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final total = snapshot.data!.length;

        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AutorizacoesScreen(perfil: widget.perfil),
            ),
          ),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cartao,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: total > 0 ? dourado : bordaCartao),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: total > 0 ? dourado : Colors.white38,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    total == 0
                        ? 'Nenhuma autorização de desconto pendente.'
                        : '$total pedido(s) de desconto aguardando '
                            'autorização.',
                    style: TextStyle(
                      color: total > 0 ? Colors.white : Colors.white54,
                      fontWeight:
                          total > 0 ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white38),
              ],
            ),
          ),
        );
      },
    );
  }
}
