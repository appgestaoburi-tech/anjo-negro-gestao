import 'package:flutter/material.dart';
import '../../config/catalogo_inicial.dart';
import '../../config/tema.dart';
import '../../models/perfil_usuario.dart';
import '../../models/servico.dart';
import '../../repositories/servico_repository.dart';
import '../../utils/dinheiro.dart';
import 'formulario_servico_dialog.dart';

class CatalogoScreen extends StatefulWidget {
  final PerfilUsuario perfil;

  const CatalogoScreen({super.key, required this.perfil});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  final _repo = ServicoRepository();

  String _categoria = 'Todas';
  bool _mostrarDesativados = false;
  bool _preparando = false;
  String? _erro;

  // Alinhado às regras do Firestore: só permissaoTotal grava em "servicos".
  bool get _editor => widget.perfil.permissaoTotal;

  @override
  void initState() {
    super.initState();
    if (_editor) _prepararCatalogo();
  }

  Future<void> _prepararCatalogo() async {
    setState(() {
      _preparando = true;
      _erro = null;
    });
    try {
      await _repo.garantirCatalogoInicial();
    } catch (e) {
      if (mounted) setState(() => _erro = 'Erro ao preparar o catálogo: $e');
    } finally {
      if (mounted) setState(() => _preparando = false);
    }
  }

  Future<void> _abrirFormulario({Servico? servico}) async {
    final salvou = await showDialog<bool>(
      context: context,
      builder: (_) => FormularioServicoDialog(
        repositorio: _repo,
        servico: servico,
      ),
    );

    if (salvou == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Serviço salvo com sucesso!')),
      );
    }
  }

  Future<void> _alterarAtivo(Servico s) async {
    try {
      await _repo.definirAtivo(s.id, !s.ativo);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível alterar o serviço.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CATÁLOGO DE SERVIÇOS'),
        actions: [
          if (_editor)
            IconButton(
              tooltip: 'Novo serviço',
              icon: const Icon(Icons.add),
              onPressed: () => _abrirFormulario(),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_editor)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFF302719),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: dourado),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'GESTÃO DO CATÁLOGO • ADMINISTRADOR',
                      style: TextStyle(
                        color: dourado,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: _categoria,
              decoration: const InputDecoration(
                labelText: 'Filtrar categoria',
                prefixIcon: Icon(Icons.filter_list),
              ),
              items: [
                const DropdownMenuItem(
                  value: 'Todas',
                  child: Text('Todas as categorias'),
                ),
                ...categoriasServicos.map(
                  (c) => DropdownMenuItem(value: c, child: Text(c)),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _categoria = v);
              },
            ),
          ),
          if (_editor)
            SwitchListTile(
              activeColor: dourado,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: const Text('Mostrar serviços desativados'),
              value: _mostrarDesativados,
              onChanged: (v) => setState(() => _mostrarDesativados = v),
            ),
          if (_preparando) const LinearProgressIndicator(color: dourado),
          if (_erro != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _erro!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<Servico>>(
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
                        'Erro ao carregar os serviços:\n\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  );
                }

                final lista = (snapshot.data ?? []).where((s) {
                  if (!s.ativo && !(_editor && _mostrarDesativados)) {
                    return false;
                  }
                  return _categoria == 'Todas' || s.categoria == _categoria;
                }).toList();

                if (lista.isEmpty) {
                  return const Center(
                    child: Text('Nenhum serviço encontrado.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                  itemCount: lista.length,
                  itemBuilder: (context, i) => _itemServico(lista[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _editor
          ? FloatingActionButton.extended(
              backgroundColor: dourado,
              foregroundColor: Colors.black,
              onPressed: () => _abrirFormulario(),
              icon: const Icon(Icons.add),
              label: const Text('NOVO SERVIÇO'),
            )
          : null,
    );
  }

  Widget _itemServico(Servico s) {
    return Opacity(
      opacity: s.ativo ? 1 : 0.5,
      child: Card(
        color: cartao,
        margin: const EdgeInsets.only(bottom: 11),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
          side: const BorderSide(color: bordaCartao),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          leading: const CircleAvatar(
            backgroundColor: Color(0xFF302719),
            child: Icon(Icons.content_cut, color: dourado),
          ),
          title: Text(
            s.nome,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            s.ativo ? s.categoria : '${s.categoria} • desativado',
            style: const TextStyle(color: Colors.white54),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Dinheiro.formatar(s.precoCentavos),
                    style: const TextStyle(
                      color: dourado,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (s.aPartir)
                    const Text(
                      'A partir de',
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                ],
              ),
              if (_editor)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  onSelected: (opcao) {
                    if (opcao == 'editar') {
                      _abrirFormulario(servico: s);
                    } else {
                      _alterarAtivo(s);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'editar',
                      child: Text('Editar serviço'),
                    ),
                    PopupMenuItem(
                      value: 'ativo',
                      child: Text(
                        s.ativo ? 'Desativar serviço' : 'Reativar serviço',
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
