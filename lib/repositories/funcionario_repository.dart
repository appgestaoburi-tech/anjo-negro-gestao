import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/funcionario.dart';

class FuncionarioRepository {
  FuncionarioRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('usuarios');

  Stream<List<Funcionario>> observar() {
    return _col.snapshots().map((snap) {
      final lista = snap.docs.map(Funcionario.doDocumento).toList();
      lista.sort(
        (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
      );
      return lista;
    });
  }

  static String _semAcento(String texto) {
    const de = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const para = 'aaaaaeeeeiiiiooooouuuucn';
    var r = texto.toLowerCase();
    for (var i = 0; i < de.length; i++) {
      r = r.replaceAll(de[i], para[i]);
    }
    return r;
  }

  static String _baseEmail(String nome) {
    final slug = _semAcento(nome)
        .replaceAll(RegExp(r'[^a-z0-9]+'), '.')
        .replaceAll(RegExp(r'^\.+|\.+$'), '');
    return slug.isEmpty ? 'funcionario' : slug;
  }

  /// Cria o login (Firebase Authentication) e o perfil (Firestore).
  /// Usa uma segunda conexão para não derrubar a sessão do administrador.
  /// A senha NÃO é gravada no Firestore. Retorna o e-mail gerado.
  Future<String> criar({
    required String nome,
    required String senha,
    required String cargo,
    required int comissaoBp,
    required int comissaoProdutosBp,
    required Map<String, int> comissaoCategoriasBp,
    required Map<String, bool> permissoes,
  }) async {
    FirebaseApp? app;
    try {
      app = await Firebase.initializeApp(
        name: 'criacao-funcionario',
        options: Firebase.app().options,
      );
      final auth = FirebaseAuth.instanceFor(app: app);

      final base = _baseEmail(nome);
      String? uid;
      var email = '';

      for (var tentativa = 0; tentativa < 20; tentativa++) {
        final sufixo = tentativa == 0 ? '' : '${tentativa + 1}';
        email = '$base$sufixo@anjonegro.app';
        try {
          final cred = await auth.createUserWithEmailAndPassword(
            email: email,
            password: senha,
          );
          uid = cred.user!.uid;
          break;
        } on FirebaseAuthException catch (e) {
          if (e.code != 'email-already-in-use') rethrow;
        }
      }

      if (uid == null) {
        throw Exception('Não foi possível gerar um e-mail único.');
      }

      await auth.signOut();

      await _col.doc(uid).set({
        'nome': nome,
        'email': email,
        'cargo': cargo,
        'ativo': true,
        'permissaoTotal': false,
        'comissaoBp': comissaoBp,
        'comissaoProdutosBp': comissaoProdutosBp,
        'comissaoCategoriasBp': comissaoCategoriasBp,
        'permissoes': permissoes,
        'criadoEm': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

      return email;
    } finally {
      await app?.delete();
    }
  }

  Future<void> atualizar(
    String uid, {
    required String nome,
    required String cargo,
    required int comissaoBp,
    required int comissaoProdutosBp,
    required Map<String, int> comissaoCategoriasBp,
    required Map<String, bool> permissoes,
  }) async {
    await _col.doc(uid).update({
      'nome': nome,
      'cargo': cargo,
      'comissaoBp': comissaoBp,
      'comissaoProdutosBp': comissaoProdutosBp,
      'comissaoCategoriasBp': comissaoCategoriasBp,
      'permissoes': permissoes,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> definirAtivo(String uid, bool ativo) async {
    await _col.doc(uid).update({
      'ativo': ativo,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }
}
