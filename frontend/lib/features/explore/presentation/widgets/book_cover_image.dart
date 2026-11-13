import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Renders a book cover with realistic spine shadow and an editorial foil fallback
/// matching the web Liread edition styling.
class BookCoverImage extends StatelessWidget {
  final String title;
  final String author;
  final String? coverUrl;
  final double? width;
  final double? height;
  final double aspectRatio;
  final BorderRadius? borderRadius;

  const BookCoverImage({
    super.key,
    required this.title,
    required this.author,
    this.coverUrl,
    this.width,
    this.height,
    this.aspectRatio = 2 / 3,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(12);

    return ClipRRect(
      borderRadius: effectiveRadius,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (coverUrl != null && coverUrl!.isNotEmpty)
                Image.network(
                  coverUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildEditorialFallback(context),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: const Color(0xFF222B26),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF557766),
                          ),
                        ),
                      ),
                    );
                  },
                )
              else
                _buildEditorialFallback(context),

              // Realistic spine highlight & inner shadow on left edge
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 10,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.40),
                        Colors.white.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditorialFallback(BuildContext context) {
    // Generate deterministic cover jacket color based on title hash
    final styles = const [
      Color(0xFF1B2820), // Sage obsidian
      Color(0xFF1E242B), // Midnight slate
      Color(0xFF2B211E), // Terracotta coffee
      Color(0xFF231F28), // Deep plum
      Color(0xFF1C221F), // Evergreen charcoal
    ];
    int hash = 0;
    for (int i = 0; i < title.length; i++) {
      hash = (hash << 5) - hash + title.codeUnitAt(i);
    }
    final jacketColor = styles[hash.abs() % styles.length];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact =
            constraints.maxWidth < 80 || constraints.maxHeight < 110;

        return Container(
          color: jacketColor,
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 6 : 10,
            vertical: isCompact ? 6 : 10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top header label
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'LIREAD',
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: GoogleFonts.spaceMono(
                        fontSize: isCompact ? 7 : 8.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: isCompact ? 0.8 : 1.5,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.menu_book_rounded,
                    size: isCompact ? 9 : 11,
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
                  ),
                ],
              ),

              // Title & Author
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: isCompact ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: isCompact ? 11 : 14,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          color: Colors.white,
                        ),
                      ),
                      if (!isCompact) ...[
                        const SizedBox(height: 3),
                        Text(
                          author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.4,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom publisher mark
              Container(
                padding: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'EDITION',
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: GoogleFonts.spaceMono(
                          fontSize: isCompact ? 6.5 : 7.5,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        'CLASSIC',
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: isCompact ? 8 : 9.5,
                          fontStyle: FontStyle.italic,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
