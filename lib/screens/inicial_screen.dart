import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/perfil_usuario.dart';
import '../services/perfil_service.dart';
import 'login_screen.dart';
import 'painel_screen.dart';
import 'telas_basicas.dart';

class InicialScreen extends StatelessWidget {
  const InicialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CarregandoScreen();
        }

        final user = snapshot.data;
        if (user == null) return const LoginScreen();

        return PerfilScreen(key: ValueKey(user.uid), user: user);
      },
    );
  }
}

class PerfilScreen extends StatefulWidget {
  final User user;

  const PerfilScreen({super.key, required this.user});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late final Future<PerfilUsuario> _perfil;

  @override
  void initState() {
    super.initState();
    _perfil = PerfilService().carregar(widget.user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PerfilUsuario>(
      future: _perfil,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CarregandoScreen();
        }

        if (snapshot.hasError) {
          return AcessoNegadoScreen(
            mensagem: snapshot.error.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          );
        }

        final perfil = snapshot.data;
        if (perfil == null) {
          return const AcessoNegadoScreen(
            mensagem: 'Não foi possível carregar seu cadastro.',
          );
        }

        return PainelScreen(perfil: perfil);
      },
    );
  }
}
