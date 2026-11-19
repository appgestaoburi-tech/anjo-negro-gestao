import 'package:flutter/material.dart';
import '../../config/catalogo_inicial.dart';
import '../../config/tema.dart';
import '../../models/servico.dart';
import '../../repositories/servico_repository.dart';
import '../../utils/dinheiro.dart';

class FormularioServicoDialog extends StatefulWidget {
  final Servico? servico;
  final ServicoRepository repositorio;

  const FormularioServicoDialog({
    super.key,
    required this.repositorio,
    this.servico,
  });

  @override
  State<FormularioServicoDialog> createState() =>
      _FormularioServicoDialogState();
}

class _FormularioServicoDialogState extends State<FormularioServicoDialog> {
  final _nome = TextEditingController();
  final _preco = TextEditingController();
  final _descricao = TextEditingController();

  String _categoria = categoriasServicos.first;
  bool _aPartir = false;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final s = widget.servico;
    if (s != null) {
      _nome.text = s.nome;
      _preco.text =
          '${s.precoCentavos ~/ 100},${(s.precoCentavos % 100).toString().padLeft(2, '0')}';
      _descricao.text = s.descricao;
      _aPartir = s.aPartir;
      if (categoriasServicos.contains(s.categoria)) {
        _categoria = s.categoria;
      }
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _preco.dispose();
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final nome = _nome.text.trim();
    final centavos = Dinheiro.paraCentavos(_preco.text);

    if (nome.isEmpty || centavos == null || centavos <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome e um preço válido.')),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      final s = widget.servico;
      if (s == null) {
        await widget.repositorio.criar(
          nome: nome,
          categoria: _categoria,
          precoCentavos: centavos,
          aPartir: _aPartir,
          descricao: _descricao.text.trim(),
        );
      } else {
        await widget.repositorio.atualizar(
          s.id,
          nome: nome,
          categoria: _categoria,
          precoCentavos: centavos,
          aPartir: _aPartir,
          descricao: _descricao.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível salvar. Confira as permissões do Firebase.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: cartao,
      title: Text(
        widget.servico == null ? 'Novo serviço' : 'Editar serviço',
        style: const TextStyle(color: dourado),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nome,
              decoration: const InputDecoration(
                labelText: 'Nome do serviço',
                prefixIcon: Icon(Icons.content_cut),
              ),
            ),
            const SizedBox(height: 13),
            DropdownButtonFormField<String>(
              value: _categoria,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: categoriasServicos
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _categoria = v);
              },
            ),
            const SizedBox(height: 13),
            TextField(
              controller: _preco,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Preço (R\$)',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: dourado,
              title: const Text('Preço "a partir de"'),
              value: _aPartir,
              onChanged: (v) => setState(() => _aPartir = v),
            ),
            TextField(
              controller: _descricao,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'A inclusão de fotos será habilitada em uma próxima etapa.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: _salvando ? null : _salvar,
          style: ElevatedButton.styleFrom(
            backgroundColor: dourado,
            foregroundColor: Colors.black,
          ),
          child: _salvando
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Text('SALVAR'),
        ),
      ],
    );
  }
}
