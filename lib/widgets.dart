import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'mealie.dart';
import 'theme.dart';

/// Recipe photography with the two image paths the app actually has: demo
/// fixtures are public Unsplash URLs, a real household's images live behind
/// `/api/media` and need the bearer token.
class RecipePhoto extends StatelessWidget {
  const RecipePhoto({
    super.key,
    required this.store,
    required this.recipe,
    this.fit = BoxFit.cover,
    this.dark = false,
  });

  final AppStore store;
  final Recipe recipe;
  final BoxFit fit;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final key = recipe.imageKey;
    final fallback = Container(
      color: dark ? c.scrim : c.surfaceAlt,
      alignment: Alignment.center,
      child: Icon(Icons.restaurant_menu_rounded,
          size: 26, color: dark ? Colors.white24 : c.faint),
    );
    if (key == null || key.isEmpty) return fallback;

    if (store.demo) {
      return Image.network(
        key,
        fit: fit,
        width: double.infinity,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    final url = store.api.imageUrl(recipe);
    if (url == null) return fallback;
    return CachedNetworkImage(
      imageUrl: url,
      httpHeaders: store.api.imageHeaders,
      fit: fit,
      width: double.infinity,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, _) => Container(color: c.surfaceAlt),
      errorWidget: (_, _, _) => fallback,
    );
  }
}

class EmberButton extends StatefulWidget {
  const EmberButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 52,
    this.busy = false,
    this.ghost = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final bool busy;
  final bool ghost;

  @override
  State<EmberButton> createState() => _EmberButtonState();
}

class _EmberButtonState extends State<EmberButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final disabled = widget.onPressed == null || widget.busy;
    final bg = widget.ghost ? Colors.transparent : c.ember;
    final fg = widget.ghost ? c.ink : c.emberInk;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: disabled ? null : (_) => setState(() => _down = false),
      onTap: disabled ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _down ? 0.985 : 1,
        duration: const Duration(milliseconds: 110),
        child: Container(
          height: widget.height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: widget.ghost ? Border.all(color: c.line) : null,
          ),
          child: widget.busy
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 17, color: fg),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: fg,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(text.toUpperCase(), style: context.label),
        const Spacer(),
        ?trailing,
      ],
    );
  }
}

class MiseField extends StatelessWidget {
  const MiseField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.keyboard,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboard;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: context.label),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboard,
          onChanged: onChanged,
          style: context.body.copyWith(fontSize: 15.5),
          cursorColor: c.ember,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: context.body.copyWith(color: c.faint),
            filled: true,
            fillColor: c.surface,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(color: c.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(color: c.ember, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.local_dining_outlined,
    this.action,
  });

  final String title;
  final String body;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: c.muted),
            ),
            const SizedBox(height: 18),
            Text(title, style: context.headline.copyWith(fontSize: 19), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(body,
                style: context.small.copyWith(height: 1.55),
                textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

class MiseSheetGrip extends StatelessWidget {
  const MiseSheetGrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.c.line,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Weekday + date in the app's voice: "FRIDAY 30 OCTOBER".
String longDate(DateTime d) {
  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December'];
  return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
}

String shortDay(DateTime d) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return days[d.weekday - 1];
}

String dayLabel(String iso, DateTime today) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  final diff = DateTime(d.year, d.month, d.day)
      .difference(DateTime(today.year, today.month, today.day))
      .inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff < 7 && diff > 0) return shortDay(d);
  return '${shortDay(d)} ${d.day}';
}

String mealTypeLabel(String type) {
  switch (type) {
    case 'breakfast':
      return 'Breakfast';
    case 'lunch':
      return 'Lunch';
    case 'dinner':
      return 'Dinner';
    case 'side':
      return 'Side';
    case 'snack':
      return 'Snack';
    default:
      return type.isEmpty ? 'Meal' : type[0].toUpperCase() + type.substring(1);
  }
}
