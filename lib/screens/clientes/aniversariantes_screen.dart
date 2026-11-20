import 'package:flutter/material.dart';
import '../../config/parametros.dart';
import '../../config/tema.dart';
import '../../models/cliente.dart';
import '../../repositories/cliente_repository.dart';

class AniversariantesScreen extends StatelessWidget {
  const AniversariantesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ANIVERSARIANTES')),
      body: StreamBuilder<List<Cliente>>(
        stream: ClienteRepository().observar(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: dourado),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SelectableText(
                  'Erro ao carregar os clientes:\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          }

          final agora = DateTime.now();
          final lista = Cliente.proximosAniversarios(
            snapshot.data ?? [],
            agora,
            diasAvisoAniversario,
          );

          if (lista.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Nenhum cliente faz aniversário nos próximos '
                  '$diasAvisoAniversario dias.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lista.length,
            itemBuilder: (context, i) {
              final c = lista[i];
              final dias = c.diasParaAniversario(agora)!;
              final anos = c.anosAoFazer(agora);

              final partes = <String>[
                c.diaMes,
                if (anos != null && anos > 0) 'faz $anos anos',
                if (c.telefone.isNotEmpty) c.telefoneFormatado,
              ];

              return Card(
                color: cartao,
                margin: const EdgeInsets.only(bottom: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                  side: BorderSide(color: dias == 0 ? dourado : bordaCartao),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 6,
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF302719),
                    child: Icon(Icons.cake_outlined, color: dourado),
                  ),
                  title: Text(
                    c.nome,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    partes.join(' • '),
                    style: const TextStyle(color: Colors.white54),
                  ),
                  trailing: Text(
                    Cliente.rotuloDias(dias).toUpperCase(),
                    style: TextStyle(
                      color: dias == 0 ? dourado : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
