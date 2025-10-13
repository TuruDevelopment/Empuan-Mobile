import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  /// Burgundy / Maroon - Warna utama brand: tombol utama, icon aktif, dan highlight penting
  static const primary = Color(0xFF6A1E3A);

  /// Deep Plum - Untuk hover / pressed state pada tombol
  static const primaryVariant = Color(0xFF4B0E28);

  // Secondary Colors
  /// Teal / Sea Green - Warna pendukung: tombol sekunder, badge, atau sukses
  static const secondary = Color(0xFF4CB7A5);

  // Background & Surface
  /// Off White - Latar utama aplikasi, ringan dan bersih
  static const background = Color(0xFFFAFAFA);

  /// White - Kartu, container, dan komponen elevasi
  static const surface = Color(0xFFFFFFFF);

  // Text Colors
  /// Charcoal Gray - Warna teks utama (judul, isi)
  static const textPrimary = Color(0xFF333333);

  /// Gray Medium - Sub-teks, deskripsi
  static const textSecondary = Color(0xFF666666);

  // Status Colors
  /// Rose Red - Untuk pesan error atau alert
  static const error = Color(0xFFD6455D);

  /// Soft Rose - Aksen lembut untuk elemen feminin (divider, icon kecil, border)
  static const accent = Color(0xFFE6B7C3);

  // Legacy colors (untuk backward compatibility - akan dihapus bertahap)
  @Deprecated('Use AppColors.primary instead')
  static const pink1 = Color(0xFF6A1E3A);

  @Deprecated('Use AppColors.background instead')
  static const bg1 = Color(0xFFFAFAFA);

  @Deprecated('Use AppColors.surface instead')
  static const bg = Color(0xFFFFFFFF);
}
