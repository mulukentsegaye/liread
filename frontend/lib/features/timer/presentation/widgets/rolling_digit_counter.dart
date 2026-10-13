import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A dynamic timer counter featuring smooth mechanical number-drop transitions
/// where updated digits slide into place with a satisfying motion.
class RollingDigitCounter extends StatelessWidget {
  final int totalSeconds;
  final TextStyle textStyle;
  final Color colonColor;

  const RollingDigitCounter({
    super.key,
    required this.totalSeconds,
    required this.textStyle,
    required this.colonColor,
  });

  @override
  Widget build(BuildContext context) {
    final mins = (totalSeconds / 60).floor();
    final secs = totalSeconds % 60;

    final m1 = (mins ~/ 10).toString();
    final m2 = (mins % 10).toString();
    final s1 = (secs ~/ 10).toString();
    final s2 = (secs % 10).toString();

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _RollingDigit(char: m1, style: textStyle),
        _RollingDigit(char: m2, style: textStyle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Text(
            ':',
            style: textStyle.copyWith(color: colonColor),
          ),
        ),
        _RollingDigit(char: s1, style: textStyle),
        _RollingDigit(char: s2, style: textStyle),
      ],
    );
  }
}

class _RollingDigit extends StatelessWidget {
  final String char;
  final TextStyle style;

  const _RollingDigit({
    required this.char,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: style.fontSize != null ? style.fontSize! * 0.62 : 32,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeInQuad,
        transitionBuilder: (child, animation) {
          final inAnimation = Tween<Offset>(
            begin: const Offset(0.0, -0.65),
            end: Offset.zero,
          ).animate(animation);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: inAnimation,
              child: child,
            ),
          );
        },
        child: Text(
          char,
          key: ValueKey<String>(char),
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            textStyle: style,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.0,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
