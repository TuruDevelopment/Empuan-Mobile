import 'dart:io';

import 'package:flutter/material.dart';
import 'package:Empuan/styles/style.dart';

class NavBar extends StatelessWidget {
  final int pageIndex;
  final Function(int) onTap;
  final bool sosActive;
  final VoidCallback onPanicPressed;

  const NavBar({
    Key? key,
    required this.pageIndex,
    required this.onTap,
    required this.sosActive,
    required this.onPanicPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: Platform.isAndroid ? 16 : 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surface,
            AppColors.accent.withOpacity(0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.accent.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -4,
          ),
        ],
        border: Border.all(
          color: AppColors.accent.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              navItem(
                Icons.home_rounded,
                'Home',
                pageIndex == 0,
                onTap: () => onTap(0),
              ),
              navItem(
                Icons.calendar_month_rounded,
                'Catatan',
                pageIndex == 1,
                onTap: () => onTap(1),
              ),
              _buildPanicButton(),
              navItem(
                Icons.phone_rounded,
                'Panggil',
                pageIndex == 2,
                onTap: () => onTap(2),
              ),
              navItem(
                Icons.more_horiz_rounded,
                'More',
                pageIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanicButton() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: GestureDetector(
          onTap: onPanicPressed,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: sosActive
                    ? [
                        AppColors.secondary,
                        AppColors.secondary.withOpacity(0.8),
                      ]
                    : [
                        AppColors.error,
                        AppColors.error.withOpacity(0.8),
                      ],
              ),
              boxShadow: [
                BoxShadow(
                  color: sosActive
                      ? AppColors.secondary.withOpacity(0.3)
                      : AppColors.error.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              sosActive ? Icons.close_rounded : Icons.crisis_alert_rounded,
              size: 28,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget navItem(
    IconData icon,
    String text,
    bool selected, {
    Function()? onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primary.withOpacity(0.1),
          highlightColor: AppColors.accent.withOpacity(0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: selected
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary.withOpacity(0.08),
                        AppColors.accent.withOpacity(0.12),
                      ],
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(selected ? 4 : 3),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: selected ? 24 : 22,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 3),
                // Text with animation
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                    fontSize: selected ? 10.5 : 9.5,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary.withOpacity(0.7),
                    letterSpacing: 0.2,
                    height: 1.1,
                  ),
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
