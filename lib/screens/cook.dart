import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../mealie.dart';
import '../theme.dart';

/// Cook mode: one step at a time, large type, screen kept awake, and the whole
/// surface is a tap target so floury fingers can advance without aiming.
class CookScreen extends StatefulWidget {
  const CookScreen({super.key, required this.recipe});

  final Recipe recipe;

  @override
  State<CookScreen> createState() => _CookScreenState();
}

class _CookScreenState extends State<CookScreen> {
  int _index = 0;

  List<String> get _steps => widget.recipe.steps;

  @override
  Widget build(BuildContext context) {
    if (_steps.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0E0C0A),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'No steps saved for this recipe yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFF7EFE4), fontSize: 17),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Back',
                        style: TextStyle(color: Color(0xFFE0663C))),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return _cookBody(context);
  }


  void _next() {
    if (_index >= _steps.length - 1) {
      Navigator.of(context).maybePop();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _index++);
  }

  void _prev() {
    if (_index == 0) return;
    HapticFeedback.selectionClick();
    setState(() => _index--);
  }

  Widget _cookBody(BuildContext context) {
    final c = MiseColors.dark;
    final last = _index == _steps.length - 1;
    return Scaffold(
      backgroundColor: const Color(0xFF0E0C0A),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          final w = MediaQuery.of(context).size.width;
          if (details.localPosition.dx < w * 0.3) {
            _prev();
          } else {
            _next();
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: Colors.white),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'STEP ${_index + 1} OF ${_steps.length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 38),
                  ],
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: (_index + 1) / _steps.length,
                    minHeight: 6,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFE0663C)),
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  widget.recipe.name.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFE0663C),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SingleChildScrollView(
                      child: Text(
                        _steps[_index],
                        style: const TextStyle(
                          color: Color(0xFFF7EFE4),
                          fontSize: 26,
                          height: 1.42,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'tap right for next',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.28),
                          fontSize: 11),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _next,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 13),
                        decoration: BoxDecoration(
                          color: last ? c.sage : const Color(0xFFE0663C),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Text(
                              last ? 'Done' : 'Next',
                              style: TextStyle(
                                color: last ? Colors.white : const Color(0xFF1A0E08),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              last ? Icons.check_rounded : Icons.arrow_forward_rounded,
                              size: 16,
                              color: last ? Colors.white : const Color(0xFF1A0E08),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
