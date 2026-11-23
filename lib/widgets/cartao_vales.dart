import 'package:flutter/material.dart';
import '../config/tema.dart';
import '../models/perfil_usuario.dart';
import '../models/vale.dart';
import '../repositories/vale_repository.dart';
import '../screens/vales/vales_screen.dart';

class CartaoVales extends StatefulWidget {
  final PerfilUsuario perfil;

  const CartaoVales({super.key, required this.perfil});

  @override
  State<CartaoVales> createState() => _CartaoValesState();
}

class _CartaoValesState extends State<CartaoVales> {
  late final Stream<List<Vale>> _stream = ValeRepository().observarPendentes();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Vale>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final total = snapshot.data!.length;

        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ValesScreen(perfil: widget.perfil),
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
                  Icons.account_balance_wallet_outlined,
                  color: total > 0 ? dourado : Colors.white38,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    total == 0
                        ? 'Nenhum pedido de vale pendente.'
                        : '$total pedido(s) de vale aguardando aprovação.',
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
