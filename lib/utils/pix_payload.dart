import 'dart:convert';

/// Gera o "Pix copia e cola" (BR Code estático) com valor definido.
/// O mesmo texto vira o QR code.

String _semAcento(String texto) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const para = 'aaaaaeeeeiiiiooooouuuucn';
  var r = texto.toLowerCase();
  for (var i = 0; i < de.length; i++) {
    r = r.replaceAll(de[i], para[i]);
  }
  return r;
}

/// Maiúsculas, sem acento, só letras, números e espaço.
String _limpar(String texto, int max) {
  var r = _semAcento(texto).toUpperCase();
  r = r.replaceAll(RegExp(r'[^A-Z0-9 ]'), ' ');
  r = r.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (r.length > max) r = r.substring(0, max).trim();
  return r;
}

String _tlv(String id, String valor) {
  return '$id${valor.length.toString().padLeft(2, '0')}$valor';
}

String _crc16(String texto) {
  var crc = 0xFFFF;
  for (final byte in utf8.encode(texto)) {
    crc ^= byte << 8;
    for (var i = 0; i < 8; i++) {
      if ((crc & 0x8000) != 0) {
        crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
      } else {
        crc = (crc << 1) & 0xFFFF;
      }
    }
  }
  return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
}

String gerarPayloadPix({
  required String chave,
  required String nome,
  required String cidade,
  required int valorCentavos,
  String txid = '',
}) {
  final k = chave.trim();
  if (k.isEmpty) throw Exception('Chave Pix não informada.');

  final conta = _tlv('00', 'br.gov.bcb.pix') + _tlv('01', k);
  if (conta.length > 99) throw Exception('A chave Pix é longa demais.');

  final nomeLimpo = _limpar(nome, 25);
  final cidadeLimpa = _limpar(cidade, 15);

  if (nomeLimpo.isEmpty || cidadeLimpa.isEmpty) {
    throw Exception('Informe o nome do recebedor e a cidade.');
  }

  var tx = txid.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
  if (tx.isEmpty) {
    tx = '***';
  } else if (tx.length > 25) {
    tx = tx.substring(0, 25);
  }

  var p = _tlv('00', '01') +
      _tlv('26', conta) +
      _tlv('52', '0000') +
      _tlv('53', '986');

  if (valorCentavos > 0) {
    p += _tlv(
      '54',
      '${valorCentavos ~/ 100}.${(valorCentavos % 100).toString().padLeft(2, '0')}',
    );
  }

  p += _tlv('58', 'BR') +
      _tlv('59', nomeLimpo) +
      _tlv('60', cidadeLimpa) +
      _tlv('62', _tlv('05', tx));

  p += '6304';
  return p + _crc16(p);
}
