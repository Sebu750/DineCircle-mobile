import 'package:flutter/material.dart';

/// Raw brand palette for DineCircle.
///
/// The identity is built around an "espresso & clay" mood: warm dark browns,
/// burnt terracotta for action, saffron gold for reward, and deep pine for
/// trust signals (verified hosts, restaurants, successful payments).
///
/// Widgets should never read these directly — they consume the semantic tokens
/// exposed by [DcTheme] through `context.dc`, which resolves the right value for
/// the active brightness.
abstract final class AppColors {
  // ── Brand ────────────────────────────────────────────────────────────────
  static const clay50 = Color(0xFFFDF1EA);
  static const clay100 = Color(0xFFF8DFD2);
  static const clay200 = Color(0xFFF0BFA9);
  static const clay400 = Color(0xFFDA7A4E);
  static const clay500 = Color(0xFFBF5327);
  static const clay600 = Color(0xFFA9471F);
  static const clay700 = Color(0xFF853618);
  static const clay900 = Color(0xFF3E1A0C);

  static const gold50 = Color(0xFFFCF5E6);
  static const gold100 = Color(0xFFF7E8C7);
  static const gold400 = Color(0xFFD9A94F);
  static const gold500 = Color(0xFFC08A2E);
  static const gold600 = Color(0xFF9C6C1F);
  static const gold900 = Color(0xFF3D2A0B);

  static const pine50 = Color(0xFFEAF1EB);
  static const pine200 = Color(0xFFB9CFBE);
  static const pine500 = Color(0xFF3A6A4F);
  static const pine600 = Color(0xFF2C4F3C);
  static const pine900 = Color(0xFF152A1F);

  // ── Warm neutrals — light ────────────────────────────────────────────────
  static const cream50 = Color(0xFFFDFBF8);
  static const cream100 = Color(0xFFFBF7F1);
  static const cream200 = Color(0xFFF5EFE6);
  static const cream300 = Color(0xFFEDE4D8);
  static const cream400 = Color(0xFFDFD3C3);

  static const espresso900 = Color(0xFF17120F);
  static const espresso800 = Color(0xFF221B16);
  static const espresso700 = Color(0xFF3A2E25);
  static const espresso500 = Color(0xFF6E6055);
  static const espresso400 = Color(0xFF9C8D80);
  static const espresso300 = Color(0xFFBFB2A5);

  // ── Warm neutrals — dark ─────────────────────────────────────────────────
  static const night950 = Color(0xFF0D0B0A);
  static const night900 = Color(0xFF141110);
  static const night800 = Color(0xFF1C1815);
  static const night700 = Color(0xFF241F1A);
  static const night600 = Color(0xFF302822);
  static const night500 = Color(0xFF3D332B);
  static const night300 = Color(0xFF8B7C6D);
  static const night200 = Color(0xFFAFA093);
  static const night100 = Color(0xFFE9E1D7);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const danger500 = Color(0xFFB23A2E);
  static const danger400 = Color(0xFFD9695C);
  static const info500 = Color(0xFF3A6E92);
  static const info400 = Color(0xFF6F9FBF);

  // ── Utility ──────────────────────────────────────────────────────────────
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const transparent = Color(0x00000000);
}
