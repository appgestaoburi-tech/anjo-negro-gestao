import 'package:flutter/material.dart';
import '../../config/tema.dart';
import '../../models/comanda.dart';
import '../../models/perfil_usuario.dart';
import '../../repositories/comanda_repository.dart';
import '../../utils/datas.dart';
import '../../utils/dinheiro.dart';
import 'comanda_screen.dart';
import 'nova_comanda.dart';

class ComandasScreen extends StatefulWidget {
  final PerfilUsuario perfil;

  const ComandasScreen({super.key, required this.perfil});

  @override
  State<ComandasScreen> createState() => _ComandasScreenState();
}

class _ComandasScreenState extends State<ComandasScreen> {
  late final Stream<List<Comanda>> _stream =
      ComandaRepository().observarAbertas(widget.perfil);

  @override
  Widget build(BuildContext context) {
    final verTodas = widget.perfil.permissaoTotal;

    return Scaffold(
      appBar: AppBar(title: const Text('COMANDAS ABERTAS')),
      body: StreamBuilder<List<Comanda>>(
        stream: _stream,
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
                  'Erro ao carregar as comandas:\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          }

          final lista = snapshot.data ?? [];

          if (lista.isEmpty) {
            return const Center(child: Text('Nenhuma comanda aberta.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: lista.length,
            itemBuilder: (context, i) {
              final c = lista[i];
              final quando = formatarDataHora(c.criadoEm);

              return Card(
                color: cartao,
                margin: const EdgeInsets.only(bottom: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                  side: const BorderSide(color: bordaCartao),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF302719),
                    child: Icon(Icons.receipt_long, color: dourado),
                  ),
                  title: Text(
                    '#${c.numero} • ${c.nomeCliente}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    verTodas ? '${c.barbeiroNome} • $quando' : quando,
                    style: const TextStyle(color: Colors.white54),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Dinheiro.formatar(c.totalCentavos),
                        style: const TextStyle(
                          color: dourado,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${c.servicos.length} serviço(s)',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ComandaScreen(
                        comandaId: c.id,
                        perfil: widget.perfil,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: dourado,
        foregroundColor: Colors.black,
        onPressed: () => iniciarNovaComanda(context, widget.perfil),
        icon: const Icon(Icons.add),
        label: const Text('NOVA COMANDA'),
      ),
    );
  }
}
