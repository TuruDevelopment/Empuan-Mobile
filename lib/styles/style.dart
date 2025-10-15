import 'package:flutter/material.dart';

class AppColors {
  // ✅ PRIMARY COLORS (dipertahankan sesuai yang disetujui client)
  /// Burgundy / Maroon - Warna utama brand: tombol utama, icon aktif, dan highlight penting
  static const primary = Color(0xFF6A1E3A);

  /// Deep Plum - Untuk hover / pressed state pada tombol
  static const primaryVariant = Color(0xFF4B0E28);

  // 🌿 SECONDARY COLORS (disesuaikan agar lebih senada & tidak keluar tone)
  /// Muted Coral Mauve - Warna pendukung senada maroon untuk tombol sekunder, badge, atau sukses
  static const secondary = Color(0xFFB95B76);

  /// Soft Coral Highlight - Warna aksen hangat untuk “Daily Quiz” dan tombol interaktif
  static const highlight = Color(0xFFE58A97);

  // 🩷 BACKGROUND & SURFACE
  /// Warm Off White - Latar utama aplikasi, lembut dan bernuansa pinkish
  static const background = Color(0xFFF9F6F6);

  /// Pure White - Kartu, container, dan komponen elevasi
  static const surface = Color(0xFFFFFFFF);

  /// Soft Pink Surface - Untuk kartu feminin seperti “31 Days”
  static const surfaceAlt = Color(0xFFEBD1D1);

  // 🖋 TEXT COLORS
  /// Charcoal Gray - Warna teks utama (judul, isi)
  static const textPrimary = Color(0xFF2F2F2F);

  /// Warm Gray - Sub-teks, deskripsi
  static const textSecondary = Color(0xFF7D7D7D);

  // ⚠️ STATUS COLORS
  /// Rose Red - Untuk pesan error atau alert
  static const error = Color(0xFFD6455D);

  /// Soft Rose - Aksen lembut untuk elemen feminin (divider, border)
  static const accent = Color(0xFFE6B7C3);

  // ✨ GRADIENT (untuk card utama “Welcome to Empuan”)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6A1E3A), Color(0xFFB95B76)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 🔙 LEGACY COLORS (untuk backward compatibility)
  @Deprecated('Use AppColors.primary instead')
  static const pink1 = Color(0xFF6A1E3A);

  @Deprecated('Use AppColors.background instead')
  static const bg1 = Color(0xFFF9F6F6);

  @Deprecated('Use AppColors.surface instead')
  static const bg = Color(0xFFFFFFFF);
}
