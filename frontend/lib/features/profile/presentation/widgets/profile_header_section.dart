import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/profile_models.dart';

/// Centered avatar, name, handle, bio, 3-column stats row, and Edit profile button.
class ProfileHeaderSection extends StatelessWidget {
  final ReaderProfile profile;
  final VoidCallback onEditProfile;

  const ProfileHeaderSection({
    super.key,
    required this.profile,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Circular Portrait Avatar ─────────────────────────
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF93A89B),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: CustomPaint(
              size: const Size(84, 84),
              painter: _PortraitAvatarPainter(),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // ── Name ─────────────────────────────────────────────
        Text(
          profile.name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 3),

        // ── Handle ───────────────────────────────────────────
        Text(
          profile.handle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 10),

        // ── Bio ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            profile.bio,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── 3-Column Stats Row ───────────────────────────────
        Row(
          children: [
            Expanded(
              child: _StatColumn(
                value: '${profile.booksRead}',
                label: 'Books read',
              ),
            ),
            Container(
              width: 1,
              height: 28,
              color: AppColors.divider,
            ),
            Expanded(
              child: _StatColumn(
                value: '${profile.followers}',
                label: 'Followers',
              ),
            ),
            Container(
              width: 1,
              height: 28,
              color: AppColors.divider,
            ),
            Expanded(
              child: _StatColumn(
                value: '${profile.following}',
                label: 'Following',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Edit Profile Pill Button ─────────────────────────
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton(
            onPressed: onEditProfile,
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.divider, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(23),
              ),
              elevation: 0,
            ),
            child: Text(
              'Edit profile',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;

  const _StatColumn({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

/// Renders a warm stylized portrait avatar on a sage-green background.
class _PortraitAvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Sage background gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF9CB0A3), Color(0xFF7D9486)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // 2. Back hair silhouette (dark chestnut brown)
    final hairPaint = Paint()
      ..color = const Color(0xFF3A241B)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.48), width: w * 0.52, height: h * 0.62),
      hairPaint,
    );

    // 3. Shoulders / Cream sweater
    final sweaterPaint = Paint()
      ..color = const Color(0xFFF6F2EC)
      ..style = PaintingStyle.fill;
    final sweaterPath = Path()
      ..moveTo(w * 0.16, h)
      ..quadraticBezierTo(w * 0.22, h * 0.72, w * 0.5, h * 0.72)
      ..quadraticBezierTo(w * 0.78, h * 0.72, w * 0.84, h)
      ..close();
    canvas.drawPath(sweaterPath, sweaterPaint);

    // 4. Neck
    final skinPaint = Paint()
      ..color = const Color(0xFFE8B89A)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.5, h * 0.65), width: w * 0.16, height: h * 0.16),
        const Radius.circular(6),
      ),
      skinPaint,
    );

    // 5. Face oval
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.43), width: w * 0.34, height: h * 0.40),
      skinPaint,
    );

    // 6. Front wavy hair strands framing face
    final frontHairPath = Path()
      ..moveTo(w * 0.32, h * 0.38)
      ..quadraticBezierTo(w * 0.36, h * 0.20, w * 0.50, h * 0.21)
      ..quadraticBezierTo(w * 0.66, h * 0.20, w * 0.68, h * 0.40)
      ..quadraticBezierTo(w * 0.70, h * 0.58, w * 0.64, h * 0.76)
      ..quadraticBezierTo(w * 0.61, h * 0.54, w * 0.63, h * 0.36)
      ..quadraticBezierTo(w * 0.52, h * 0.27, w * 0.37, h * 0.36)
      ..quadraticBezierTo(w * 0.39, h * 0.54, w * 0.36, h * 0.76)
      ..quadraticBezierTo(w * 0.30, h * 0.58, w * 0.32, h * 0.38)
      ..close();
    canvas.drawPath(frontHairPath, hairPaint);

    // 7. Eyes & warm smile
    final featurePaint = Paint()
      ..color = const Color(0xFF2D1E18)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.44, h * 0.42), 1.6, featurePaint);
    canvas.drawCircle(Offset(w * 0.56, h * 0.42), 1.6, featurePaint);

    final smilePaint = Paint()
      ..color = const Color(0xFFC47D68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.48), width: w * 0.11, height: h * 0.07),
      0.15,
      2.8,
      false,
      smilePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
