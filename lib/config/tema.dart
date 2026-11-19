import 'package:flutter/material.dart';

const Color dourado = Color(0xFFD6AD55);
const Color fundo = Color(0xFF101010);
const Color cartao = Color(0xFF1C1C1C);
const Color bordaCartao = Color(0xFF3B3324);

ThemeData criarTema() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: fundo,
    colorScheme: const ColorScheme.dark(
      primary: dourado,
      secondary: dourado,
      surface: cartao,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: cartao,
      foregroundColor: dourado,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cartao,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIconColor: dourado,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF383838)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dourado, width: 1.5),
      ),
    ),
  );
}
