import 'package:flutter/material.dart';
import '../../config/tema.dart';
import '../../models/funcionario.dart';
import '../../models/perfil_usuario.dart';
import '../../repositories/funcionario_repository.dart';
import 'comissao_barbeiro_screen.dart';

class ComissoesScreen extends StatelessWidget {
  final PerfilUsuario perfil;
  final FuncionarioRepository _repo = FuncionarioRepository();

  ComissoesScreen({super.key, required this.perfil});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('COMISSÕES')),
      body: StreamBuilder<List<Funcionario>>(
        stream: _repo.observar(),
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
                  'Erro ao carregar os funcionários:\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          }

          final lista =
              (snapshot.data ?? []).where((f) => !f.permissaoTotal).toList();

          if (lista.isEmpty) {
            return const Center(child: Text('Nenhum funcionário cadastrado.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lista.length,
            itemBuilder: (context, i) {
              final f = lista[i];

              return Opacity(
                opacity: f.ativo ? 1 : 0.5,
                child: Card(
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
                      child: Icon(Icons.person, color: dourado),
                    ),
                    title: Text(
                      f.nome,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      f.rotuloCargo,
                      style: const TextStyle(color: Colors.white54),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.white38,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ComissaoBarbeiroScreen(
                          perfil: perfil,
                          barbeiroUid: f.uid,
                          barbeiroNome: f.nome,
                        ),
                      ),
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
