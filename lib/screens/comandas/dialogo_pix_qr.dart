import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../config/tema.dart';
import '../../repositories/configuracao_repository.dart';
import '../../utils/dinheiro.dart';
import '../../utils/erros.dart';
import '../../utils/pix_payload.dart';

class DialogPixQr extends StatefulWidget {
  final int valorCentavos;
  final int comandaNumero;

  const DialogPixQr({
    super.key,
    required this.valorCentavos,
    this.comandaNumero = 0,
  });

  @override
  State<DialogPixQr> createState() => _DialogPixQrState();
}

class _DialogPixQrState extends State<DialogPixQr> {
  late final Stream<PixConfig?> _stream =
      ConfiguracaoRepository().observarPix();

  bool _copiado = false;

  Widget _aviso(String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(texto, textAlign: TextAlign.center),
    );
  }

  Widget _conteudo(PixConfig cfg) {
    final String payload;

    try {
      payload = gerarPayloadPix(
        chave: cfg.chave,
        nome: cfg.nome,
        cidade: cfg.cidade,
        valorCentavos: widget.valorCentavos,
        txid: widget.comandaNumero > 0
            ? 'ANJO${widget.comandaNumero.toString().padLeft(6, '0')}'
            : 'ANJOTESTE',
      );
    } catch (e) {
      return Text(
        mensagemDeErro(e),
        style: const TextStyle(color: Colors.redAccent),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: QrImageView(
            data: payload,
            version: QrVersions.auto,
            size: 230,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          Dinheiro.formatar(widget.valorCentavos),
          style: const TextStyle(
            color: dourado,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Recebedor: ${cfg.nome}',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          'O cliente escaneia no app do banco. Confira no seu banco que o '
          'Pix entrou antes de confirmar o pagamento na comanda.',
          style: TextStyle(color: Colors.white54, fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: payload));
            if (mounted) setState(() => _copiado = true);
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: dourado,
            side: const BorderSide(color: dourado),
          ),
          icon: Icon(_copiado ? Icons.check : Icons.copy),
          label: Text(_copiado ? 'COPIADO' : 'COPIAR PIX COPIA E COLA'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: cartao,
      title: const Text('QR code Pix', style: TextStyle(color: dourado)),
      content: SingleChildScrollView(
        child: StreamBuilder<PixConfig?>(
          stream: _stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(color: dourado),
                ),
              );
            }

            if (snapshot.hasError) {
              return _aviso('Não foi possível carregar a chave Pix.');
            }

            final cfg = snapshot.data;

            if (cfg == null || !cfg.completo) {
              return _aviso(
                'A chave Pix ainda não foi configurada. '
                'O administrador pode cadastrar em Configurações.',
              );
            }

            return _conteudo(cfg);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('FECHAR'),
        ),
      ],
    );
  }
}
