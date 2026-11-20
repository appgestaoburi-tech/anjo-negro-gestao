import 'package:flutter/material.dart';
import '../config/parametros.dart';
import '../config/tema.dart';
import '../models/cliente.dart';
import '../repositories/cliente_repository.dart';
import '../screens/clientes/aniversariantes_screen.dart';

class AniversariantesCard extends StatefulWidget {
  const AniversariantesCard({super.key});

  @override
  State<AniversariantesCard> createState() => _AniversariantesCardState();
}

class _AniversariantesCardState extends State<AniversariantesCard> {
  late final Stream<List<Cliente>> _stream = ClienteRepository().observar();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Cliente>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final agora = DateTime.now();
        final lista = Cliente.proximosAniversarios(
          snapshot.data!,
          agora,
          diasAvisoAniversario,
        );

        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AniversariantesScreen()),
          ),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cartao,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: lista.isEmpty ? bordaCartao : dourado,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cake_outlined, color: dourado, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ANIVERSARIANTES • PRÓXIMOS $diasAvisoAniversario DIAS',
                        style: const TextStyle(
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
                const SizedBox(height: 10),
                if (lista.isEmpty)
                  const Text(
                    'Nenhum aniversariante no período.',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  )
                else ...[
                  for (final c in lista.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${c.nome} • ${Cliente.rotuloDias(c.diasParaAniversario(agora)!)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  if (lista.length > 3)
                    Text(
                      '+ ${lista.length - 3} outros',
                      style: const TextStyle(
                        color: Colors.white54,
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
