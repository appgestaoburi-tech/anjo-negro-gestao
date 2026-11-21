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
  final _repo = ComandaRepository();

  late final Stream<List<Comanda>> _abertas =
      _repo.observarAbertas(widget.perfil);
  late final Stream<List<Comanda>> _pagas =
      _repo.observarPagasHoje(widget.perfil);

  bool _verPagas = false;

  @override
  Widget build(BuildContext context) {
    final verTodas = widget.perfil.permissaoTotal;

    return Scaffold(
      appBar: AppBar(title: const Text('COMANDAS')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('ABERTAS'),
                  selected: !_verPagas,
                  selectedColor: dourado,
                  labelStyle: TextStyle(
                    color: !_verPagas ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (_) => setState(() => _verPagas = false),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('PAGAS HOJE'),
                  selected: _verPagas,
                  selectedColor: dourado,
                  labelStyle: TextStyle(
                    color: _verPagas ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (_) => setState(() => _verPagas = true),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Comanda>>(
              stream: _verPagas ? _pagas : _abertas,
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
                  return Center(
                    child: Text(
                      _verPagas
                          ? 'Nenhuma comanda paga hoje.'
                          : 'Nenhuma comanda aberta.',
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
                  itemCount: lista.length,
                  itemBuilder: (context, i) {
                    final c = lista[i];
                    final quando = formatarDataHora(c.criadoEm);

                    final partes = <String>[
                      if (verTodas) c.barbeiroNome,
                      quando,
                      if (c.aberta && c.pagoCentavos > 0)
                        'pago ${Dinheiro.formatar(c.pagoCentavos)}',
                    ];

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
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF302719),
                          child: Icon(
                            c.aberta ? Icons.receipt_long : Icons.check_circle,
                            color: dourado,
                          ),
                        ),
                        title: Text(
                          '#${c.numero} • ${c.nomeCliente}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          partes.join(' • '),
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
                              c.aberta
                                  ? '${c.servicos.length} serviço(s)'
                                  : 'PAGA',
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
          ),
        ],
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
