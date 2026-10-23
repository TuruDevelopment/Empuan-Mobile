import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../styles/style.dart';
import 'em_motion.dart';

export '../styles/style.dart';
export 'em_motion.dart';

enum EmButtonVariant { primary, secondary, tonal, text, danger, white }

class EmButton extends StatelessWidget {
  const EmButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = EmButtonVariant.primary,
    this.loading = false,
    this.expand = true,
    this.small = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final EmButtonVariant variant;
  final bool loading;
  final bool expand;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final height = small ? 40.0 : 52.0;
    final (bg, fg, border) = switch (variant) {
      EmButtonVariant.primary => (AppColors.primary, Colors.white, null),
      EmButtonVariant.secondary => (Colors.transparent, AppColors.primary, AppColors.primary),
      EmButtonVariant.tonal => (AppColors.blush, AppColors.primary, null),
      EmButtonVariant.text => (Colors.transparent, AppColors.primary, null),
      EmButtonVariant.danger => (AppColors.danger, Colors.white, null),
      EmButtonVariant.white => (Colors.white, AppColors.primary, null),
    };
    final disabled = onPressed == null || loading;
    final child = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: small ? 18 : 20), const SizedBox(width: 8)],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final button = TextButton(
      onPressed: disabled ? null : onPressed,
      style: TextButton.styleFrom(
        backgroundColor: disabled && variant != EmButtonVariant.text && !loading ? const Color(0xFFE7DFE1) : bg,
        foregroundColor: fg,
        disabledForegroundColor: loading ? fg : const Color(0xFF8E8487),
        minimumSize: Size(small ? 44 : 64, height),
        padding: EdgeInsets.symmetric(horizontal: small ? 16 : 22),
        shape: StadiumBorder(
          side: border == null ? BorderSide.none : BorderSide(color: disabled ? AppColors.line2 : border, width: 1.5),
        ),
        textStyle: TextStyle(fontFamily: AppFonts.body, fontSize: small ? 14 : 16, fontWeight: FontWeight.w700),
      ),
      child: child,
    );
    final sized = expand ? SizedBox(width: double.infinity, height: height, child: button) : SizedBox(height: height, child: button);
    return EmPressable(enabled: !disabled, child: sized);
  }
}

enum EmIconButtonStyle { plain, soft, tint, primary }

class EmIconButton extends StatelessWidget {
  const EmIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.style = EmIconButtonStyle.plain,
    this.size = 44,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final EmIconButtonStyle style;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (style) {
      EmIconButtonStyle.plain => (Colors.transparent, color ?? AppColors.textPrimary, false),
      EmIconButtonStyle.soft => (AppColors.surface, color ?? AppColors.textPrimary, true),
      EmIconButtonStyle.tint => (AppColors.blush, color ?? AppColors.primary, false),
      EmIconButtonStyle.primary => (AppColors.primary, Colors.white, false),
    };
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: bg,
          shape: CircleBorder(side: border ? const BorderSide(color: AppColors.line) : BorderSide.none),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, color: fg, size: size >= 44 ? 22 : 18),
            ),
          ),
        ),
      ),
    );
  }
}

/// App bar used by pushed screens: back button, centred title, optional actions.
class EmTopBar extends StatelessWidget implements PreferredSizeWidget {
  const EmTopBar({
    super.key,
    this.title,
    this.actions = const [],
    this.leading,
    this.closeIcon = false,
    this.backgroundColor,
    this.foregroundColor,
    this.onBack,
  });

  final String? title;
  final List<Widget> actions;
  final Widget? leading;
  final bool closeIcon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.background,
      foregroundColor: foregroundColor ?? AppColors.textPrimary,
      automaticallyImplyLeading: false,
      leadingWidth: 60,
      leading: leading ??
          (canPop || onBack != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: EmIconButton(
                    icon: closeIcon ? Icons.close_rounded : Icons.arrow_back_ios_new_rounded,
                    label: closeIcon ? 'Close' : 'Back',
                    color: foregroundColor,
                    onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                  ),
                )
              : null),
      title: title == null
          ? null
          : Text(title!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: foregroundColor ?? AppColors.textPrimary)),
      actions: [...actions, const SizedBox(width: 8)],
    );
  }
}

class EmCard extends StatelessWidget {
  const EmCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.surface,
    this.borderColor = AppColors.line,
    this.radius = 20,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor),
    );
    return EmPressable(
      enabled: onTap != null,
      scale: 0.985,
      child: Material(
        color: color,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A white rounded group of rows separated by hairlines.
class EmGroup extends StatelessWidget {
  const EmGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) items.add(const Divider(height: 1));
      items.add(children[i]);
    }
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: items),
    );
  }
}

class EmRow extends StatelessWidget {
  const EmRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showChevron,
    this.highlighted = false,
    this.titleColor,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool? showChevron;
  final bool highlighted;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final chevron = showChevron ?? (onTap != null && trailing == null);
    return Material(
      color: highlighted ? AppColors.blush : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 14)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: titleColor ?? AppColors.textPrimary)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
                if (chevron) const Icon(Icons.chevron_right_rounded, color: AppColors.quietIcon),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum EmTileTone { normal, danger, primary }

class EmIconTile extends StatelessWidget {
  const EmIconTile(this.icon, {super.key, this.tone = EmTileTone.normal, this.size = 40});

  final IconData icon;
  final EmTileTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      EmTileTone.normal => (AppColors.blush, AppColors.primary),
      EmTileTone.danger => (AppColors.dangerTint, AppColors.danger),
      EmTileTone.primary => (AppColors.primary, Colors.white),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * 0.3)),
      child: Icon(icon, color: fg, size: size * 0.5),
    );
  }
}

class EmAvatar extends StatelessWidget {
  const EmAvatar({super.key, required this.name, this.size = 40});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.surfaceAlt, shape: BoxShape.circle),
      child: Text(
        initialsOf(name),
        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: size * 0.36),
      ),
    );
  }
}

class EmTag extends StatelessWidget {
  const EmTag(this.label, {super.key, this.tone = EmTileTone.normal, this.icon});

  final String label;
  final EmTileTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      EmTileTone.normal => (AppColors.blush, AppColors.primary),
      EmTileTone.danger => (AppColors.dangerTint, AppColors.danger),
      EmTileTone.primary => (AppColors.primary, Colors.white),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 4)],
          Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class EmChip extends StatelessWidget {
  const EmChip({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: EmMotion.medium,
        curve: EmMotion.enter,
        decoration: ShapeDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.primary : AppColors.line2)),
        ),
        child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                widthFactor: 1,
                child: AnimatedDefaultTextStyle(
                  duration: EmMotion.medium,
                  style: TextStyle(fontFamily: AppFonts.body, fontSize: 14, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textPrimary),
                  child: Text(label),
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

/// Horizontally scrolling row of single-select chips.
class EmChipBar extends StatelessWidget {
  const EmChipBar({super.key, required this.labels, required this.selected, required this.onSelected, this.padding = EdgeInsets.zero});

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => EmChip(label: labels[i], selected: i == selected, onTap: () => onSelected(i)),
      ),
    );
  }
}

/// Large selectable option used in onboarding, quizzes and report sheets.
class EmOption extends StatelessWidget {
  const EmOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.multi = false,
    this.leading,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool multi;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final marker = leading ??
        (multi
            ? Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: selected ? AppColors.primary : AppColors.line2, width: 2),
                ),
                child: selected ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
              )
            : Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: selected ? AppColors.primary : AppColors.line2, width: selected ? 7 : 2),
                ),
              ));
    return Semantics(
      selected: selected,
      checked: multi ? selected : null,
      inMutuallyExclusiveGroup: !multi,
      button: true,
      child: Material(
        color: selected ? AppColors.blush : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selected ? AppColors.primary : AppColors.line2, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  marker,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: selected ? AppColors.primaryVariant : AppColors.textPrimary),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Labelled text field with optional password visibility toggle.
class EmTextField extends StatefulWidget {
  const EmTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.errorText,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.password = false,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.suffixIcon,
    this.autofillHints,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.textCapitalization = TextCapitalization.none,
    this.hideLabel = false,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool password;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final IconData? suffixIcon;
  final Iterable<String>? autofillHints;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final TextCapitalization textCapitalization;
  final bool hideLabel;

  @override
  State<EmTextField> createState() => _EmTextFieldState();
}

class _EmTextFieldState extends State<EmTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    Widget? suffix;
    if (widget.password) {
      suffix = IconButton(
        tooltip: _obscure ? 'Show password' : 'Hide password',
        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textSecondary),
        onPressed: () => setState(() => _obscure = !_obscure),
      );
    } else if (widget.suffixIcon != null) {
      suffix = Icon(widget.suffixIcon, color: AppColors.primary);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.hideLabel) ...[
          Text(widget.label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: widget.password && _obscure,
          enableSuggestions: !widget.password,
          autocorrect: !widget.password,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          autofillHints: widget.autofillHints,
          maxLines: widget.password ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          enabled: widget.enabled,
          textCapitalization: widget.textCapitalization,
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helper,
            errorText: widget.errorText,
            suffixIcon: suffix,
            semanticCounterText: widget.label,
          ).copyWith(labelText: widget.hideLabel ? widget.label : null, floatingLabelBehavior: FloatingLabelBehavior.never),
        ),
      ],
    );
  }
}

/// Live checklist line used under password fields.
class EmCheckLine extends StatelessWidget {
  const EmCheckLine({super.key, required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final color = met ? AppColors.primary : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(met ? Icons.check_rounded : Icons.circle_outlined, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class EmProgressBar extends StatelessWidget {
  const EmProgressBar({super.key, required this.value, this.height = 6});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: height,
        backgroundColor: AppColors.blush,
        color: AppColors.primary,
      ),
    );
  }
}

/// Segmented step indicator for multi-step flows.
class EmStepBar extends StatelessWidget {
  const EmStepBar({super.key, required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step $step of $total',
      child: Row(
        children: [
          for (var i = 1; i <= total; i++) ...[
            if (i > 1) const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  color: i <= step ? AppColors.primary : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class EmSectionHeader extends StatelessWidget {
  const EmSectionHeader(this.title, {super.key, this.actionLabel, this.onAction, this.trailing});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        if (trailing != null) trailing!,
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class EmCaption extends StatelessWidget {
  const EmCaption(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color));
  }
}

class EmNote extends StatelessWidget {
  const EmNote({super.key, required this.child, this.icon = Icons.info_outline_rounded});

  final Widget child;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.blush, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryVariant),
          const SizedBox(width: 10),
          Expanded(
            child: DefaultTextStyle.merge(
              style: const TextStyle(fontSize: 13, height: 18 / 13, color: AppColors.primaryVariant),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty, error and gate states share this layout.
class EmStateView extends StatelessWidget {
  const EmStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.tone = EmTileTone.normal,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EmTileTone tone;

  factory EmStateView.error({required String message, VoidCallback? onRetry}) => EmStateView(
        icon: Icons.wifi_off_rounded,
        title: 'Something went wrong',
        message: message,
        actionLabel: onRetry == null ? null : 'Try again',
        onAction: onRetry,
        tone: EmTileTone.danger,
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmIconTile(icon, tone: tone, size: 56),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(message!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            EmButton(label: actionLabel!, onPressed: onAction, variant: EmButtonVariant.tonal, expand: false, small: true),
          ],
        ],
      ),
    );
  }
}

class EmLoading extends StatelessWidget {
  const EmLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.6)),
      ),
    );
  }
}

class EmWordmark extends StatelessWidget {
  const EmWordmark({super.key, this.size = 30, this.color = AppColors.primary});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Empuan',
      semanticsLabel: 'Empuan',
      style: TextStyle(fontFamily: AppFonts.wordmark, fontSize: size, height: 1.15, color: color),
    );
  }
}

/// Pinned bottom area for primary actions on pushed screens.
class EmBottomBar extends StatelessWidget {
  const EmBottomBar({super.key, required this.child, this.bordered = true});

  final Widget child;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bordered ? AppColors.surface : Colors.transparent,
        border: bordered ? const Border(top: BorderSide(color: AppColors.line)) : null,
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Overlays
// ---------------------------------------------------------------------------

Future<T?> showEmSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: builder(ctx),
      ),
    ),
  );
}

/// Standard sheet header: title, optional description.
class EmSheetHeader extends StatelessWidget {
  const EmSheetHeader({super.key, required this.title, this.message, this.icon, this.iconTone = EmTileTone.normal});

  final String title;
  final String? message;
  final IconData? icon;
  final EmTileTone iconTone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[EmIconTile(icon!, tone: iconTone, size: 48), const SizedBox(height: 16)],
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(message!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        ],
      ],
    );
  }
}

/// Confirmation dialog. Returns true when the user confirms.
Future<bool> showEmConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool danger = false,
  Widget? extra,
}) async {
  final result = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(ctx).textTheme.headlineMedium),
            const SizedBox(height: 10),
            Text(message, style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
            if (extra != null) ...[const SizedBox(height: 12), extra],
            const SizedBox(height: 20),
            EmButton(
              label: confirmLabel,
              variant: danger ? EmButtonVariant.danger : EmButtonVariant.primary,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
            const SizedBox(height: 8),
            EmButton(label: cancelLabel, variant: EmButtonVariant.text, onPressed: () => Navigator.of(ctx).pop(false)),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

void showEmToast(BuildContext context, String message, {IconData? icon, String? actionLabel, VoidCallback? onAction}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 10)],
            Expanded(child: Text(message)),
          ],
        ),
        action: actionLabel == null ? null : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
      ),
    );
}

// ---------------------------------------------------------------------------
// Formatting helpers
// ---------------------------------------------------------------------------

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts.first.characters.first + parts[1].characters.first).toUpperCase();
}

DateTime? parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}

/// "1 Oct 2026"
String formatDate(DateTime? date) => date == null ? '' : DateFormat('d MMM yyyy').format(date);

/// "Just now", "5 min", "3 h", "Yesterday", "12 Oct"
String formatRelative(DateTime? date, {DateTime? now}) {
  if (date == null) return '';
  final current = now ?? DateTime.now();
  final diff = current.difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24 && current.day == date.day) return '${diff.inHours} h ago';
  final yesterday = DateTime(current.year, current.month, current.day).subtract(const Duration(days: 1));
  if (date.isAfter(yesterday)) return 'Yesterday';
  if (date.year == current.year) return DateFormat('d MMM').format(date);
  return DateFormat('d MMM yyyy').format(date);
}

String apiDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

/// Pushes a full-screen route on the root navigator so the tab bar is hidden.
Future<T?> pushScreen<T>(BuildContext context, Widget screen) {
  return Navigator.of(context, rootNavigator: true).push<T>(MaterialPageRoute(builder: (_) => screen));
}
