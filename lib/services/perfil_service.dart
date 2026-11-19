import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/perfil_usuario.dart';

class PerfilService {
  PerfilService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // Localiza o campo ignorando espaços extras no nome (proteção com trim).
  static dynamic _campo(Map<String, dynamic> dados, String nome) {
    for (final e in dados.entries) {
      if (e.key.trim() == nome) return e.value;
    }
    return null;
  }

  Future<PerfilUsuario> carregar(String uid) async {
    final doc = await _firestore.collection('usuarios').doc(uid).get();

    if (!doc.exists) {
      throw Exception('Cadastro de usuário não encontrado.');
    }

    final dados = doc.data()!;
    final ativo = _campo(dados, 'ativo');

    if (ativo != true) {
      final campos = dados.keys.map((c) => '"$c"').join(', ');
      throw Exception(
        'ACESSO BLOQUEADO\n'
        'Valor de "ativo": $ativo\n'
        'Tipo: ${ativo?.runtimeType ?? 'null'}\n'
        'Campos existentes: $campos\n'
        'UID: $uid',
      );
    }

    final cargo =
        (_campo(dados, 'cargo') ?? '').toString().toLowerCase().trim();

    if (!['admin', 'administrador', 'admin_equipe', 'colaborador'].contains(cargo)) {
      throw Exception('Seu perfil não possui um cargo válido.');
    }

    final permissoes = <String, bool>{};
    final brutas = _campo(dados, 'permissoes');
    if (brutas is Map) {
      brutas.forEach((k, v) {
        if (v == true) permissoes[k.toString().trim()] = true;
      });
    }

    return PerfilUsuario(
      uid: uid,
      nome: (_campo(dados, 'nome') ?? 'Usuário').toString(),
      cargo: cargo,
      permissaoTotal: _campo(dados, 'permissaoTotal') == true,
      permissoes: permissoes,
    );
  }
}
