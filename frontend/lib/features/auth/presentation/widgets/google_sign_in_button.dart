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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                // Flexible: in a narrow dialog or with large text, shrink to
                // "Continue with Goo…" rather than overflow the button.
                Flexible(
                  child: Text(
                    'Continue with Google',
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
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
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24.0, size.height / 24.0);

    // Official Google 4-color "G" paths (24x24 viewBox)
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;

    // Blue section (crossbar and right arm)
    final bluePath = Path()
      ..moveTo(22.56, 12.25)
      ..cubicTo(22.56, 11.47, 22.49, 10.72, 22.36, 10.00)
      ..lineTo(12.00, 10.00)
      ..lineTo(12.00, 14.26)
      ..lineTo(17.92, 14.26)
      ..cubicTo(17.66, 15.63, 16.88, 16.79, 15.71, 17.57)
      ..lineTo(15.71, 20.34)
      ..lineTo(19.28, 20.34)
      ..cubicTo(21.36, 18.42, 22.56, 15.60, 22.56, 12.25)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // Green section (bottom arc)
    final greenPath = Path()
      ..moveTo(12.00, 23.00)
      ..cubicTo(14.97, 23.00, 17.46, 22.02, 19.28, 20.34)
      ..lineTo(15.71, 17.57)
      ..cubicTo(14.73, 18.23, 13.48, 18.63, 12.00, 18.63)
      ..cubicTo(9.14, 18.63, 6.71, 16.70, 5.84, 14.10)
      ..lineTo(2.18, 14.10)
      ..lineTo(2.18, 16.94)
      ..cubicTo(3.99, 20.53, 7.70, 23.00, 12.00, 23.00)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // Yellow section (left arc)
    final yellowPath = Path()
      ..moveTo(5.84, 14.09)
      ..cubicTo(5.62, 13.43, 5.49, 12.73, 5.49, 12.00)
      ..cubicTo(5.49, 11.27, 5.62, 10.57, 5.84, 9.91)
      ..lineTo(5.84, 7.06)
      ..lineTo(2.18, 7.06)
      ..cubicTo(1.43, 8.55, 1.00, 10.22, 1.00, 12.00)
      ..cubicTo(1.00, 13.78, 1.43, 15.45, 2.18, 16.94)
      ..lineTo(5.03, 14.72)
      ..lineTo(5.84, 14.09)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // Red section (top arc)
    final redPath = Path()
      ..moveTo(12.00, 5.38)
      ..cubicTo(13.62, 5.38, 15.06, 5.94, 16.21, 7.02)
      ..lineTo(19.36, 3.87)
      ..cubicTo(17.45, 2.09, 14.97, 1.00, 12.00, 1.00)
      ..cubicTo(7.70, 1.00, 3.99, 3.47, 2.18, 7.06)
      ..lineTo(5.84, 9.90)
      ..cubicTo(6.71, 7.30, 9.14, 5.38, 12.00, 5.38)
      ..close();
    canvas.drawPath(redPath, redPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
