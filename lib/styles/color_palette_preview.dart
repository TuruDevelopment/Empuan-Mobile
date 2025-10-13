import 'package:flutter/material.dart';
import 'style.dart';

/// Widget untuk menampilkan preview color palette Empuan Mobile
/// Gunakan widget ini untuk testing dan development
class ColorPalettePreview extends StatelessWidget {
  const ColorPalettePreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Empuan Color Palette'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('Primary Colors', [
            _ColorCard(
              name: 'Primary',
              description: 'Burgundy / Maroon',
              hex: '#6A1E3A',
              color: AppColors.primary,
            ),
            _ColorCard(
              name: 'Primary Variant',
              description: 'Deep Plum',
              hex: '#4B0E28',
              color: AppColors.primaryVariant,
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('Secondary Colors', [
            _ColorCard(
              name: 'Secondary',
              description: 'Teal / Sea Green',
              hex: '#4CB7A5',
              color: AppColors.secondary,
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('Background & Surface', [
            _ColorCard(
              name: 'Background',
              description: 'Off White',
              hex: '#FAFAFA',
              color: AppColors.background,
              showBorder: true,
            ),
            _ColorCard(
              name: 'Surface',
              description: 'White',
              hex: '#FFFFFF',
              color: AppColors.surface,
              showBorder: true,
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('Text Colors', [
            _ColorCard(
              name: 'Text Primary',
              description: 'Charcoal Gray',
              hex: '#333333',
              color: AppColors.textPrimary,
            ),
            _ColorCard(
              name: 'Text Secondary',
              description: 'Gray Medium',
              hex: '#666666',
              color: AppColors.textSecondary,
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('Status & Accent', [
            _ColorCard(
              name: 'Error',
              description: 'Rose Red',
              hex: '#D6455D',
              color: AppColors.error,
            ),
            _ColorCard(
              name: 'Accent',
              description: 'Soft Rose',
              hex: '#E6B7C3',
              color: AppColors.accent,
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('Button Examples', [
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Primary Button'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Outlined Button'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {},
              child: const Text('Text Button'),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

class _ColorCard extends StatelessWidget {
  final String name;
  final String description;
  final String hex;
  final Color color;
  final bool showBorder;

  const _ColorCard({
    required this.name,
    required this.description,
    required this.hex,
    required this.color,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Color Preview
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: showBorder
                    ? Border.all(
                        color: AppColors.textSecondary.withOpacity(0.2))
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            // Color Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hex,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: AppColors.textSecondary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
