import 'package:flutter/material.dart';
import '../../config/tema.dart';
import '../../repositories/configuracao_repository.dart';
import '../../utils/chave_pix.dart';
import '../../utils/erros.dart';
import '../../utils/periodo_comissao.dart';
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

  String _tipo = 'telefone';
  String _modo = 'semanal';
  int _diaInicio = 6;

  bool _carregando = true;
  bool _salvando = false;
  bool _salvandoRegra = false;
  String? _erro;
  String? _erroRegra;

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
      final regra = await _repo.lerComissoes();
      if (!mounted) return;
      setState(() {
        if (cfg != null) {
          _chave.text = cfg.chave;
          _nome.text = cfg.nome;
          _cidade.text = cfg.cidade;
          _tipo = tipoDaChave(cfg.chave);
        }
        _modo = regra.modo;
        _diaInicio = regra.diaInicio;
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

  TextInputType get _teclado {
    if (_tipo == 'email') return TextInputType.emailAddress;
    if (_tipo == 'aleatoria') return TextInputType.text;
    return TextInputType.phone;
  }

  TipoChavePix get _tipoAtual =>
      tiposChavePix.firstWhere((t) => t.chave == _tipo);

  Future<void> _salvar() async {
    final nome = _nome.text.trim();
    final cidade = _cidade.text.trim();

    if (_chave.text.trim().isEmpty || nome.isEmpty || cidade.isEmpty) {
      setState(() => _erro = 'Preencha a chave, o nome e a cidade.');
      return;
    }

    final String chave;

    try {
      chave = normalizarChavePix(_tipo, _chave.text);
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
      setState(() {
        _chave.text = chave;
        _salvando = false;
      });
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

  Future<void> _salvarRegra() async {
    setState(() {
      _salvandoRegra = true;
      _erroRegra = null;
    });

    try {
      await _repo.salvarComissoes(modo: _modo, diaInicio: _diaInicio);
      if (!mounted) return;
      setState(() => _salvandoRegra = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Regra de comissões salva!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _salvandoRegra = false;
        _erroRegra = mensagemDeErro(e);
      });
    }
  }

  void _testar() {
    showDialog<void>(
      context: context,
      builder: (_) => const DialogPixQr(valorCentavos: 100),
    );
  }

  Widget _titulo(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        color: dourado,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
  }

  Widget _botaoSalvar(String texto, bool ocupado, VoidCallback aoTocar) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: ocupado ? null : aoTocar,
        style: ElevatedButton.styleFrom(
          backgroundColor: dourado,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: ocupado
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : Text(
                texto,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _secaoComissoes() {
    final fim = _diaInicio == 1 ? 7 : _diaInicio - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo('PAGAMENTO DE COMISSÕES'),
        const SizedBox(height: 8),
        const Text(
          'Define como o administrador paga as comissões dos barbeiros.',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 18),
        DropdownButtonFormField<String>(
          value: _modo,
          decoration: const InputDecoration(
            labelText: 'Modo de pagamento',
            prefixIcon: Icon(Icons.calendar_month_outlined),
          ),
          items: const [
            DropdownMenuItem(
              value: 'semanal',
              child: Text('Semanal (por semana fechada)'),
            ),
            DropdownMenuItem(
              value: 'livre',
              child: Text('Livre (tudo que estiver pendente)'),
            ),
          ],
          onChanged: (v) {
            if (v != null) {
              setState(() {
                _modo = v;
                _erroRegra = null;
              });
            }
          },
        ),
        if (_modo == 'semanal') ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _diaInicio,
            decoration: const InputDecoration(
              labelText: 'A semana de trabalho começa em',
              prefixIcon: Icon(Icons.today_outlined),
            ),
            items: [
              for (var d = 1; d <= 7; d++)
                DropdownMenuItem(value: d, child: Text(nomesDiasSemana[d])),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  _diaInicio = v;
                  _erroRegra = null;
                });
              }
            },
          ),
          const SizedBox(height: 10),
          Text(
            'Cada pagamento cobre de ${nomesDiasSemana[_diaInicio].toLowerCase()} '
            'a ${nomesDiasSemana[fim].toLowerCase()} e pode ser feito a partir '
            'de ${nomesDiasSemana[_diaInicio].toLowerCase()}. O trabalho do '
            'próprio dia ${nomesDiasSemana[_diaInicio].toLowerCase()} entra no '
            'pagamento da semana seguinte.',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ] else ...[
          const SizedBox(height: 10),
          const Text(
            'No modo livre, o administrador paga tudo o que estiver '
            'pendente quando quiser.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
        if (_erroRegra != null) ...[
          const SizedBox(height: 12),
          Text(_erroRegra!, style: const TextStyle(color: Colors.redAccent)),
        ],
        const SizedBox(height: 16),
        _botaoSalvar('SALVAR REGRA DE COMISSÕES', _salvandoRegra, _salvarRegra),
        const SizedBox(height: 10),
        const Text(
          'Mudar a regra não altera comissões já calculadas nem '
          'pagamentos já feitos.',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
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
                _secaoComissoes(),
                const SizedBox(height: 30),
                const Divider(color: bordaCartao),
                const SizedBox(height: 22),
                _titulo('RECEBIMENTO POR PIX'),
                const SizedBox(height: 8),
                const Text(
                  'Esses dados geram o QR code Pix mostrado no pagamento. '
                  'O dinheiro cai direto na conta ligada a esta chave.',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  value: _tipo,
                  decoration: const InputDecoration(
                    labelText: 'Tipo da chave',
                    prefixIcon: Icon(Icons.vpn_key_outlined),
                  ),
                  items: [
                    for (final t in tiposChavePix)
                      DropdownMenuItem(value: t.chave, child: Text(t.rotulo)),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _tipo = v;
                        _erro = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _chave,
                  autocorrect: false,
                  keyboardType: _teclado,
                  onChanged: (_) => setState(() => _erro = null),
                  decoration: InputDecoration(
                    labelText: 'Chave Pix',
                    helperText: _tipoAtual.dica,
                    helperMaxLines: 3,
                    prefixIcon: const Icon(Icons.key),
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
                _botaoSalvar('SALVAR PIX', _salvando, _salvar),
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
                const SizedBox(height: 20),
              ],
            ),
    );
  }
}
