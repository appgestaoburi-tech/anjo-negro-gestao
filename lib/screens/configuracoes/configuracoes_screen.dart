import 'package:flutter/material.dart';
import '../../config/tema.dart';
import '../../repositories/configuracao_repository.dart';
import '../../utils/erros.dart';
import '../../utils/pix_payload.dart';
import '../comandas/dialogo_pix_qr.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  final _repo = ConfiguracaoRepository();

  final _chave = TextEditingController();
  final _nome = TextEditingController();
  final _cidade = TextEditingController();

  bool _carregando = true;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _chave.dispose();
    _nome.dispose();
    _cidade.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final cfg = await _repo.lerPix();
      if (!mounted) return;
      setState(() {
        if (cfg != null) {
          _chave.text = cfg.chave;
          _nome.text = cfg.nome;
          _cidade.text = cfg.cidade;
        }
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = mensagemDeErro(e);
        _carregando = false;
      });
    }
  }

  Future<void> _salvar() async {
    final chave = _chave.text.trim();
    final nome = _nome.text.trim();
    final cidade = _cidade.text.trim();

    if (chave.isEmpty || nome.isEmpty || cidade.isEmpty) {
      setState(() => _erro = 'Preencha a chave, o nome e a cidade.');
      return;
    }

    try {
      gerarPayloadPix(
        chave: chave,
        nome: nome,
        cidade: cidade,
        valorCentavos: 100,
      );
    } catch (e) {
      setState(() => _erro = mensagemDeErro(e));
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      await _repo.salvarPix(chave: chave, nome: nome, cidade: cidade);
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuração do Pix salva!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _erro = mensagemDeErro(e);
      });
    }
  }

  void _testar() {
    showDialog<void>(
      context: context,
      builder: (_) => const DialogPixQr(valorCentavos: 100),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CONFIGURAÇÕES')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: dourado))
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                const Text(
                  'RECEBIMENTO POR PIX',
                  style: TextStyle(
                    color: dourado,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Esses dados geram o QR code Pix mostrado no pagamento. '
                  'O dinheiro cai direto na conta ligada a esta chave.',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _chave,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Chave Pix',
                    helperText: 'CPF/CNPJ: só números. Telefone: +5511999999999. '
                        'E-mail ou chave aleatória: como no banco.',
                    helperMaxLines: 3,
                    prefixIcon: Icon(Icons.key),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nome,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Nome do recebedor',
                    helperText: 'Como aparece no banco (até 25 letras)',
                    prefixIcon: Icon(Icons.storefront_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _cidade,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Cidade',
                    helperText: 'Até 15 letras',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                ),
                if (_erro != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _erro!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _salvando ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dourado,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _salvando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'SALVAR',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _testar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: dourado,
                      side: const BorderSide(color: dourado),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('GERAR QR DE TESTE (R\$ 1,00)'),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Dica: salve primeiro e depois gere o teste. Escaneie com '
                  'o app de outro banco e confira o nome do recebedor e o '
                  'valor na tela de confirmação.',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
    );
  }
}
