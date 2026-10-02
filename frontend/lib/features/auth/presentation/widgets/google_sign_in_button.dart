import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: isLoading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accent,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _GoogleLogo(),
                const SizedBox(width: 12),
                Text(
                  'Continue with Google',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 20,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Standard Google 4-color G
    final redPaint = Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.fill;
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.fill;
    final greenPaint = Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.fill;
    final bluePaint = Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill;

    // Draw stylized G badge
    canvas.drawCircle(center, radius, bluePaint);
    canvas.drawCircle(center, radius * 0.55, Paint()..color = Colors.white);

    // Right crossbar
    canvas.drawRect(
      Rect.fromLTRB(center.dx - 1, center.dy - radius * 0.2, center.dx + radius * 0.9, center.dy + radius * 0.2),
      bluePaint,
    );

    // Accent slices
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 0.75, 1.6, true, greenPaint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 2.35, 1.2, true, yellowPaint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 3.55, 1.2, true, redPaint);
    canvas.drawCircle(center, radius * 0.55, Paint()..color = Colors.white);
    canvas.drawRect(
      Rect.fromLTRB(center.dx, center.dy - radius * 0.2, center.dx + radius * 0.95, center.dy + radius * 0.2),
      bluePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
