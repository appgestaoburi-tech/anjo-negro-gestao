import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../config/tema.dart';
import '../models/perfil_usuario.dart';
import '../widgets/aniversariantes_card.dart';
import '../widgets/cards_painel.dart';
import '../widgets/cartao_autorizacoes.dart';
import '../widgets/cartao_vales.dart';
import '../widgets/indicador_comandas_abertas.dart';
import '../widgets/indicador_entradas_dia.dart';
import 'caixa/caixa_screen.dart';
import 'catalogo/catalogo_screen.dart';
import 'clientes/clientes_screen.dart';
import 'comandas/comandas_screen.dart';
import 'comandas/nova_comanda.dart';
import 'comissoes/comissao_barbeiro_screen.dart';
import 'comissoes/comissoes_screen.dart';
import 'funcionarios/funcionarios_screen.dart';
import 'pacotes/pacotes_screen.dart';
import 'produtos/produtos_screen.dart';
import 'telas_basicas.dart';
import 'vales/vales_screen.dart';

class PainelScreen extends StatelessWidget {
  final PerfilUsuario perfil;

  const PainelScreen({super.key, required this.perfil});

  void _abrirComissoes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => perfil.permissaoTotal
            ? ComissoesScreen(perfil: perfil)
            : ComissaoBarbeiroScreen(
                perfil: perfil,
                barbeiroUid: perfil.uid,
                barbeiroNome: perfil.nome,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ANJO NEGRO',
          style: TextStyle(
            color: dourado,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout, color: dourado),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, ${perfil.primeiroNome}!',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                perfil.rotuloCargo,
                style: const TextStyle(color: dourado, fontSize: 14),
              ),
              const SizedBox(height: 25),
              const TextoSecao(titulo: 'VISÃO GERAL'),
              const SizedBox(height: 13),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: [
                  IndicadorEntradasDia(perfil: perfil),
                  IndicadorComandasAbertas(perfil: perfil),
                  const IndicadorCard(
                    titulo: 'Clientes atendidos',
                    valor: '—',
                    icone: Icons.people_outline,
                  ),
                  const IndicadorCard(
                    titulo: 'Resultado estimado',
                    valor: '—',
                    icone: Icons.trending_up,
                  ),
                ],
              ),
              if (perfil.permissaoTotal) ...[
                const SizedBox(height: 14),
                CartaoAutorizacoes(perfil: perfil),
                const SizedBox(height: 10),
                CartaoVales(perfil: perfil),
              ],
              const SizedBox(height: 14),
              const AniversariantesCard(),
              const SizedBox(height: 28),
              const TextoSecao(titulo: 'GESTÃO DA BARBEARIA'),
              const SizedBox(height: 13),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  ModuloCard(
                    titulo: 'Nova comanda',
                    icone: Icons.add_shopping_cart,
                    onTap: () => iniciarNovaComanda(context, perfil),
                  ),
                  ModuloCard(
                    titulo: 'Comandas',
                    icone: Icons.receipt_long,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ComandasScreen(perfil: perfil),
                      ),
                    ),
                  ),
                  ModuloCard(
                    titulo: 'Clientes',
                    icone: Icons.people,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ClientesScreen(),
                      ),
                    ),
                  ),
                  ModuloCard(
                    titulo: 'Catálogo de serviços',
                    icone: Icons.content_cut,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CatalogoScreen(perfil: perfil),
                      ),
                    ),
                  ),
                  if (perfil.permissaoTotal)
                    ModuloCard(
                      titulo: 'Pacotes',
                      icone: Icons.card_membership,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PacotesScreen(),
                        ),
                      ),
                    ),
                  ModuloCard(
                    titulo: 'Estoque',
                    icone: Icons.inventory_2_outlined,
                    onTap: () {
                      if (perfil.permissaoTotal) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProdutosScreen(),
                          ),
                        );
                      } else {
                        abrirModulo(context, 'Estoque');
                      }
                    },
                  ),
                  if (perfil.pode('ver_caixa'))
                    ModuloCard(
                      titulo: 'Caixa',
                      icone: Icons.point_of_sale,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CaixaScreen(perfil: perfil),
                        ),
                      ),
                    ),
                  ModuloCard(
                    titulo: 'Comissões',
                    icone: Icons.percent,
                    onTap: () => _abrirComissoes(context),
                  ),
                  ModuloCard(
                    titulo: perfil.permissaoTotal ? 'Vales' : 'Meus vales',
                    icone: Icons.account_balance_wallet_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ValesScreen(perfil: perfil),
                      ),
                    ),
                  ),
                  ModuloCard(
                    titulo: 'Relatórios',
                    icone: Icons.bar_chart,
                    onTap: () => abrirModulo(context, 'Relatórios'),
                  ),
                  if (perfil.permissaoTotal)
                    ModuloCard(
                      titulo: 'Funcionários',
                      icone: Icons.badge_outlined,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FuncionariosScreen(perfil: perfil),
                        ),
                      ),
                    ),
                  if (perfil.permissaoTotal)
                    ModuloCard(
                      titulo: 'Configurações',
                      icone: Icons.settings,
                      onTap: () => abrirModulo(context, 'Configurações'),
                    ),
                ],
              ),
              const SizedBox(height: 25),
              const Center(
                child: Text(
                  'ANJO NEGRO GESTÃO',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 11,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
