import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comanda.dart';
import '../models/pacote_cliente.dart';
import '../models/perfil_usuario.dart';
import '../utils/comissao_barbeiro.dart';
import '../utils/datas.dart';
import '../utils/pacote_calculo.dart';
import '../utils/totais_comanda.dart';

typedef Escrita = void Function(Transaction tx);

int _menos(int? v) => (v ?? 0) > 0 ? (v ?? 0) - 1 : 0;

/// Lê (sem escrever) o que precisa mudar para devolver usos de pacote e
/// retorna as escritas a executar depois. Chame ANTES de qualquer escrita
/// da transação.
Future<List<Escrita>> prepararLiberacoes(
  Transaction tx,
  FirebaseFirestore fs,
  List<ItemComanda> usos,
) async {
  final escritas = <Escrita>[];
  final porPacote = <String, List<ItemComanda>>{};

  for (final l in usos) {
    porPacote.putIfAbsent(l.pacoteId, () => []).add(l);
  }

  for (final e in porPacote.entries) {
    final pacoteRef = fs.collection('pacotesClientes').doc(e.key);
    final pacoteSnap = await tx.get(pacoteRef);

    final validas = <ItemComanda>[];
    final refsUso = <DocumentReference<Map<String, dynamic>>>[];

    for (final l in e.value) {
      final ref = fs.collection('usosPacote').doc(l.id);
      final snap = await tx.get(ref);
      if (snap.exists && snap.data()?['status'] == 'ativo') {
        validas.add(l);
        refsUso.add(ref);
      }
    }

    if (validas.isEmpty) continue;

    if (pacoteSnap.exists) {
      final p = PacoteCliente.doDocumento(pacoteSnap);
      final contadores = Map<String, int>.from(p.contadores);
      final mes = Map<String, int>.from(p.contadoresMes);
      var total = p.usosTotal;

      for (final l in validas) {
        contadores[l.servicoId] = _menos(contadores[l.servicoId]);
        final chave = '${l.servicoId}_${l.ciclo}';
        mes[chave] = _menos(mes[chave]);
        total = total > 0 ? total - 1 : 0;
      }

      escritas.add(
        (t) => t.update(pacoteRef, {
          'contadores': contadores,
          'contadoresMes': mes,
          'usosTotal': total,
          'atualizadoEm': FieldValue.serverTimestamp(),
        }),
      );
    }

    for (final ref in refsUso) {
      escritas.add(
        (t) => t.update(ref, {
          'status': 'cancelado',
          'canceladoEm': FieldValue.serverTimestamp(),
        }),
      );
    }
  }

  return escritas;
}

class PacoteUsoRepository {
  PacoteUsoRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Lança o uso de um serviço do pacote na comanda. Confere validade,
  /// serviço incluído e limites, e conta o uso, tudo na mesma operação.
  Future<void> usar({
    required String comandaId,
    required String pacoteId,
    required String servicoId,
    required PerfilUsuario perfil,
  }) async {
    final fs = _firestore;

    await fs.runTransaction((tx) async {
      final comandaRef = fs.collection('comandas').doc(comandaId);
      final pacoteRef = fs.collection('pacotesClientes').doc(pacoteId);
      final servicoRef = fs.collection('servicos').doc(servicoId);

      final comandaSnap = await tx.get(comandaRef);
      final pacoteSnap = await tx.get(pacoteRef);
      final servicoSnap = await tx.get(servicoRef);

      if (!comandaSnap.exists) throw Exception('Comanda não encontrada.');
      if (!pacoteSnap.exists) throw Exception('Pacote não encontrado.');

      final c = Comanda.doDocumento(comandaSnap);
      final p = PacoteCliente.doDocumento(pacoteSnap);

      if (!c.aberta) throw Exception('Esta comanda não está mais aberta.');
      if (!perfil.permissaoTotal && c.barbeiroUid != perfil.uid) {
        throw Exception(
          'Somente o barbeiro responsável ou o administrador pode lançar.',
        );
      }
      if (c.clienteId.isEmpty || c.clienteId != p.clienteId) {
        throw Exception('Este pacote é de outro cliente.');
      }
      if (p.status != 'ativo') {
        throw Exception('Este pacote foi cancelado.');
      }

      final agora = DateTime.now();
      final hoje = DateTime(agora.year, agora.month, agora.day);

      if (hoje.isBefore(p.inicioData) || !hoje.isBefore(p.fimData)) {
        throw Exception('Este pacote está fora da validade.');
      }

      final itens = p.itens.where((i) => i.servicoId == servicoId).toList();
      if (itens.isEmpty) {
        throw Exception('Este serviço não está incluído no pacote.');
      }
      final item = itens.first;

      if (p.usosTotal >= p.totalUsos ||
          p.usado(servicoId) >= item.qtdTotal) {
        throw Exception(
          'Todos os usos de ${item.servicoNome} deste pacote já foram '
          'feitos (${item.qtdTotal}).',
        );
      }

      var ciclo = cicloDe(p.inicioData, hoje);
      if (ciclo >= p.meses) ciclo = p.meses - 1;

      final usadoMes = p.usadoNoCiclo(servicoId, ciclo);
      if (usadoMes >= item.maxPorMes) {
        final proximo = somarMeses(p.inicioData, ciclo + 1);
        throw Exception(
          'Limite do mês atingido para ${item.servicoNome}: $usadoMes de '
          '${item.maxPorMes}. O próximo mês do pacote começa em '
          '${formatarDia(proximo)}.',
        );
      }

      // O último uso do pacote absorve os centavos de resto.
      final numero = p.usosTotal + 1;
      final valorUso = numero == p.totalUsos
          ? p.precoPagoCentavos - p.valorUsoCentavos * (p.totalUsos - 1)
          : p.valorUsoCentavos;

      final categoria = (servicoSnap.data()?['categoria'] ?? 'Principais')
          .toString();

      final usoRef = fs.collection('usosPacote').doc();

      final linha = ItemComanda(
        id: usoRef.id,
        servicoId: servicoId,
        nome: item.servicoNome,
        categoria: categoria,
        precoCatalogoCentavos: 0,
        precoCentavos: 0,
        aPartir: false,
        tipo: 'uso',
        pacoteId: p.id,
        valorUsoCentavos: valorUso,
        ciclo: ciclo,
      );

      final contadores = Map<String, int>.from(p.contadores);
      contadores[servicoId] = (contadores[servicoId] ?? 0) + 1;

      final mes = Map<String, int>.from(p.contadoresMes);
      final chave = '${servicoId}_$ciclo';
      mes[chave] = (mes[chave] ?? 0) + 1;

      tx.update(
        comandaRef,
        camposTotais(
          [...c.servicos, linha],
          c.produtos,
          c.descontoBp,
          c.pagoCentavos,
        ),
      );

      tx.update(pacoteRef, {
        'contadores': contadores,
        'contadoresMes': mes,
        'usosTotal': numero,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

      tx.set(usoRef, {
        'pacoteClienteId': p.id,
        'pacoteNome': p.nome,
        'clienteId': p.clienteId,
        'clienteNome': p.clienteNome,
        'comandaId': c.id,
        'comandaNumero': c.numero,
        'barbeiroUid': c.barbeiroUid,
        'barbeiroNome': c.barbeiroNome,
        'registradoPorUid': perfil.uid,
        'registradoPorNome': perfil.nome,
        'servicoId': servicoId,
        'servicoNome': item.servicoNome,
        'valorUsoCentavos': valorUso,
        'ciclo': ciclo,
        'dia': diaIso(agora),
        'status': 'ativo',
        'criadoEm': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Tira o uso da comanda e devolve o uso ao pacote.
  Future<void> removerUso(String comandaId, String itemId) async {
    final fs = _firestore;

    await fs.runTransaction((tx) async {
      final ref = fs.collection('comandas').doc(comandaId);
      final snap = await tx.get(ref);

      if (!snap.exists) throw Exception('Comanda não encontrada.');

      final c = Comanda.doDocumento(snap);
      if (!c.aberta) throw Exception('Esta comanda não está mais aberta.');

      final alvo = c.servicos.where((i) => i.id == itemId && i.ehUso).toList();
      if (alvo.isEmpty) throw Exception('Uso não encontrado nesta comanda.');

      final escritas = await prepararLiberacoes(tx, fs, alvo);

      final restantes = c.servicos.where((i) => i.id != itemId).toList();

      tx.update(
        ref,
        camposTotais(
          restantes,
          c.produtos,
          restantes.isEmpty ? 0 : c.descontoBp,
          c.pagoCentavos,
        ),
      );

      for (final e in escritas) {
        e(tx);
      }
    });
  }

  /// Finaliza o atendimento sem cobrança (só usos de pacote) e grava a
  /// comissão de quem atendeu.
  Future<void> finalizarCoberta(String comandaId, PerfilUsuario perfil) async {
    final fs = _firestore;

    await fs.runTransaction((tx) async {
      final ref = fs.collection('comandas').doc(comandaId);
      final snap = await tx.get(ref);

      if (!snap.exists) throw Exception('Comanda não encontrada.');

      final c = Comanda.doDocumento(snap);
      final bruto = snap.data() ?? <String, dynamic>{};
      final finalizacoes = (bruto['finalizacoes'] as num?)?.toInt() ?? 0;

      if (!c.aberta) throw Exception('Esta comanda não está mais aberta.');
      if (!perfil.permissaoTotal && c.barbeiroUid != perfil.uid) {
        throw Exception(
          'Somente o barbeiro responsável ou o administrador pode finalizar.',
        );
      }
      if (!c.coberta || c.totalCentavos != 0 || c.pagoCentavos != 0) {
        throw Exception('Esta comanda tem valor a cobrar. Use o pagamento.');
      }

      final barbeiro = await tx.get(fs.collection('usuarios').doc(c.barbeiroUid));
      final comissao = comissaoDoBarbeiro(c, barbeiro);

      final agora = DateTime.now();

      final campos = <String, dynamic>{
        'status': 'paga',
        'pagoCentavos': 0,
        'finalizadaEm': FieldValue.serverTimestamp(),
        'finalizadaPorUid': perfil.uid,
        'finalizadaDia': diaIso(agora),
        'finalizacoes': finalizacoes + 1,
        'atualizadoEm': FieldValue.serverTimestamp(),
      };

      String? comissaoId;
      if (comissao != null && comissao.linhas.isNotEmpty) {
        comissaoId = '${c.id}_${finalizacoes + 1}';
        campos['comissaoAtualId'] = comissaoId;
      }

      tx.update(ref, campos);

      if (comissao != null && comissaoId != null) {
        tx.set(fs.collection('comissoes').doc(comissaoId), {
          'comandaId': c.id,
          'comandaNumero': c.numero,
          'barbeiroUid': c.barbeiroUid,
          'barbeiroNome': c.barbeiroNome,
          'clienteNome': c.clienteNome,
          'dia': diaIso(agora),
          'status': 'ativa',
          'totalComissaoCentavos': comissao.totalCentavos,
          'baseServicosCentavos': comissao.baseServicosCentavos,
          'baseProdutosCentavos': comissao.baseProdutosCentavos,
          'descontoCentavos': c.descontoCentavos,
          'linhas': comissao.linhas.map((l) => l.paraMapa()).toList(),
          'criadoEm': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Só o administrador: reabre um atendimento finalizado sem cobrança e
  /// estorna a comissão dele.
  Future<void> reabrirCoberta(String comandaId, PerfilUsuario perfil) async {
    if (!perfil.permissaoTotal) {
      throw Exception('Somente o administrador pode reabrir.');
    }

    final fs = _firestore;

    await fs.runTransaction((tx) async {
      final ref = fs.collection('comandas').doc(comandaId);
      final snap = await tx.get(ref);

      if (!snap.exists) throw Exception('Comanda não encontrada.');

      final c = Comanda.doDocumento(snap);
      final bruto = snap.data() ?? <String, dynamic>{};

      if (c.status != 'paga' || !c.coberta) {
        throw Exception('Esta comanda não é um atendimento coberto por pacote.');
      }

      final comissaoId = (bruto['comissaoAtualId'] ?? '').toString();
      DocumentReference<Map<String, dynamic>>? comissaoRef;
      DocumentSnapshot<Map<String, dynamic>>? comissaoSnap;

      if (comissaoId.isNotEmpty) {
        comissaoRef = fs.collection('comissoes').doc(comissaoId);
        comissaoSnap = await tx.get(comissaoRef);
      }

      tx.update(ref, {
        'status': 'aberta',
        'reabertaEm': FieldValue.serverTimestamp(),
        'reabertaPorUid': perfil.uid,
        'finalizadaEm': FieldValue.delete(),
        'finalizadaDia': FieldValue.delete(),
        'comissaoAtualId': FieldValue.delete(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

      if (comissaoRef != null &&
          comissaoSnap != null &&
          comissaoSnap.exists &&
          comissaoSnap.data()?['status'] == 'ativa') {
        tx.update(comissaoRef, {
          'status': 'estornada',
          'estornadaEm': FieldValue.serverTimestamp(),
          'estornadaPorUid': perfil.uid,
        });
      }
    });
  }
}
