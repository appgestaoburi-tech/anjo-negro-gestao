import 'package:flutter/material.dart';
import '../../config/tema.dart';
import '../../models/cliente.dart';
import '../../models/perfil_usuario.dart';
import '../../repositories/cliente_repository.dart';
import '../../repositories/comanda_repository.dart';
import '../../utils/erros.dart';
import 'comanda_screen.dart';

class _EscolhaCliente {
  final Cliente? cliente;
  const _EscolhaCliente(this.cliente);
}

/// Pergunta o cliente (ou atendimento sem cadastro), abre a comanda
/// e leva direto para a tela dela.
Future<void> iniciarNovaComanda(
  BuildContext context,
  PerfilUsuario perfil,
) async {
  final escolha = await showModalBottomSheet<_EscolhaCliente>(
    context: context,
    isScrollControlled: true,
    backgroundColor: cartao,
    builder: (_) => const _SeletorCliente(),
  );

  if (escolha == null || !context.mounted) return;

  final navegador = Navigator.of(context);
  final mensagens = ScaffoldMessenger.of(context);

  try {
    final id = await ComandaRepository().criar(
      perfil,
      cliente: escolha.cliente,
    );
    navegador.push(
      MaterialPageRoute(
        builder: (_) => ComandaScreen(comandaId: id, perfil: perfil),
      ),
    );
  } catch (e) {
    mensagens.showSnackBar(
      SnackBar(
        content: Text(
          mensagemDeErro(
            e,
            padrao: 'Não foi possível abrir a comanda. Verifique a conexão.',
          ),
        ),
      ),
    );
  }
}

class _SeletorCliente extends StatefulWidget {
  const _SeletorCliente();

  @override
  State<_SeletorCliente> createState() => _SeletorClienteState();
}

class _SeletorClienteState extends State<_SeletorCliente> {
  late final Stream<List<Cliente>> _stream = ClienteRepository().observar();
  String _termo = '';

  bool _combina(Cliente c) {
    if (_termo.isEmpty) return true;
    final q = Cliente.normalizar(_termo);
    if (Cliente.normalizar(c.nome).contains(q)) return true;
    final digitos = _termo.replaceAll(RegExp(r'\D'), '');
    return digitos.isNotEmpty && c.telefone.contains(digitos);
  }

  @override
  Widget build(BuildContext context) {
    final altura = MediaQuery.of(context).size.height * 0.8;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: altura,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'PARA QUEM É A COMANDA?',
                style: TextStyle(
                  color: dourado,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (v) => setState(() => _termo = v.trim()),
                decoration: const InputDecoration(
                  labelText: 'Pesquisar cliente',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_off_outlined, color: dourado),
              title: const Text('Atendimento sem cadastro'),
              onTap: () => Navigator.pop(context, const _EscolhaCliente(null)),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<List<Cliente>>(
                stream: _stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: dourado),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Erro ao carregar os clientes.'),
                    );
                  }

                  final lista = (snapshot.data ?? []).where(_combina).toList();

                  if (lista.isEmpty) {
                    return const Center(
                      child: Text('Nenhum cliente encontrado.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: lista.length,
                    itemBuilder: (context, i) {
                      final c = lista[i];
                      return ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(c.nome),
                        subtitle: c.telefone.isEmpty
                            ? null
                            : Text(c.telefoneFormatado),
                        onTap: () =>
                            Navigator.pop(context, _EscolhaCliente(c)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
