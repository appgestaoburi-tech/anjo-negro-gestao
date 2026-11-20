import 'package:firebase_core/firebase_core.dart';

String mensagemDeErro(
  Object e, {
  String padrao =
      'Não foi possível concluir a operação. Verifique a conexão e tente novamente.',
}) {
  if (e is FirebaseException) {
    if (e.code == 'permission-denied') {
      return 'Você não tem permissão para esta operação.';
    }
    return padrao;
  }
  final texto = e.toString();
  if (texto.startsWith('Exception: ')) return texto.substring(11);
  return padrao;
}
