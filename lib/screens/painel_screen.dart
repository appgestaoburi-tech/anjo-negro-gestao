import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../config/tema.dart';
import '../models/perfil_usuario.dart';
import '../widgets/aniversariantes_card.dart';
import '../widgets/cards_painel.dart';
import '../widgets/indicador_comandas_abertas.dart';
import 'catalogo/catalogo_screen.dart';
import 'clientes/clientes_screen.dart';
import 'comandas/comandas_screen.dart';
import 'comandas/nova_comanda.dart';
import 'funcionarios/funcionarios_screen.dart';
import 'telas_basicas.dart';

class PainelScreen extends StatelessWidget {
  final PerfilUsuario perfil;

  const PainelScreen({super.key, required this.perfil});

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
                  const IndicadorCard(
                    titulo: 'Entradas do dia',
                    valor: '—',
                    icone: Icons.attach_money,
                  ),
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
                    titulo: 'Comandas abertas',
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
                  ModuloCard(
                    titulo: 'Estoque',
                    icone: Icons.inventory_2_outlined,
                    onTap: () => abrirModulo(context, 'Estoque'),
                  ),
                  ModuloCard(
                    titulo: 'Caixa',
                    icone: Icons.point_of_sale,
                    onTap: () => abrirModulo(context, 'Caixa'),
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
