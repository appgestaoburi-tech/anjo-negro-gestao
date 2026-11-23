import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PixConfig {
  final String chave;
  final String nome;
  final String cidade;

  const PixConfig({
    required this.chave,
    required this.nome,
    required this.cidade,
  });

  factory PixConfig.doMapa(Map<String, dynamic> d) {
    return PixConfig(
      chave: (d['chave'] ?? '').toString(),
      nome: (d['nome'] ?? '').toString(),
      cidade: (d['cidade'] ?? '').toString(),
    );
  }

  bool get completo =>
      chave.trim().isNotEmpty &&
      nome.trim().isNotEmpty &&
      cidade.trim().isNotEmpty;
}

/// Regra de pagamento de comissões.
/// semanal: paga por semana fechada (padrão: começa no sábado, 6).
/// livre: paga tudo o que estiver pendente, a qualquer momento.
class ComissaoConfig {
  final String modo;
  final int diaInicio;

  const ComissaoConfig({this.modo = 'semanal', this.diaInicio = 6});

  bool get semanal => modo == 'semanal';

  factory ComissaoConfig.doMapa(Map<String, dynamic> d) {
    final dia = (d['diaInicio'] as num?)?.toInt() ?? 6;
    return ComissaoConfig(
      modo: d['modo'] == 'livre' ? 'livre' : 'semanal',
      diaInicio: (dia >= 1 && dia <= 7) ? dia : 6,
    );
  }
}

class ConfiguracaoRepository {
  ConfiguracaoRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _pix =>
      _firestore.collection('configuracoes').doc('pix');

  DocumentReference<Map<String, dynamic>> get _comissoes =>
      _firestore.collection('configuracoes').doc('comissoes');

  // ---------------- Pix ----------------

  Stream<PixConfig?> observarPix() {
    return _pix.snapshots().map(
          (d) => d.exists ? PixConfig.doMapa(d.data() ?? {}) : null,
        );
  }

  Future<PixConfig?> lerPix() async {
    final d = await _pix.get();
    return d.exists ? PixConfig.doMapa(d.data() ?? {}) : null;
  }

  Future<void> salvarPix({
    required String chave,
    required String nome,
    required String cidade,
  }) async {
    await _pix.set({
      'chave': chave.trim(),
      'nome': nome.trim(),
      'cidade': cidade.trim(),
      'atualizadoPorUid': FirebaseAuth.instance.currentUser?.uid,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  // ---------------- Comissões ----------------

  /// Se ainda não foi configurado, vale o padrão: semanal, sábado a sexta.
  Stream<ComissaoConfig> observarComissoes() {
    return _comissoes.snapshots().map(
          (d) => d.exists
              ? ComissaoConfig.doMapa(d.data() ?? {})
              : const ComissaoConfig(),
        );
  }

  Future<ComissaoConfig> lerComissoes() async {
    final d = await _comissoes.get();
    return d.exists
        ? ComissaoConfig.doMapa(d.data() ?? {})
        : const ComissaoConfig();
  }

  Future<void> salvarComissoes({
    required String modo,
    required int diaInicio,
  }) async {
    await _comissoes.set({
      'modo': modo,
      'diaInicio': diaInicio,
      'atualizadoPorUid': FirebaseAuth.instance.currentUser?.uid,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }
}
