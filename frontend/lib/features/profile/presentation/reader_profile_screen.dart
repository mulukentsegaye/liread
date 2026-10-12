import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/profile_models.dart';
import 'widgets/bookshelf_section.dart';
import 'widgets/profile_header_section.dart';
import 'widgets/profile_menu_section.dart';

/// "Your corner" Reader Profile screen.
class ReaderProfileScreen extends StatefulWidget {
  const ReaderProfileScreen({super.key});

  @override
  State<ReaderProfileScreen> createState() => _ReaderProfileScreenState();
}

class _ReaderProfileScreenState extends State<ReaderProfileScreen> {
  ReaderProfile _profile = const ReaderProfile(
    name: 'Emma Laurent',
    handle: '@emma.reads',
    bio: 'Collecting stories, slow mornings\nand a few too many books.',
    booksRead: 12,
    followers: 128,
    following: 96,
    savedPassagesCount: 24,
    readingCirclesCount: 3,
  );

  static const List<ShelfBook> _shelfBooks = [
    ShelfBook(
      id: '1',
      title: 'Before the\ncoffee gets\ncold',
      author: 'Toshikazu\nKawaguchi',
      status: ShelfStatus.reading,
      coverColor: Color(0xFF2E493E),
      textColor: Color(0xFFD6DFDA),
    ),
    ShelfBook(
      id: '2',
      title: 'THE\nCREATIVE\nACT',
      author: 'Rick Rubin',
      status: ShelfStatus.finished,
      coverColor: Color(0xFFE9E4D8),
      textColor: Color(0xFF2D4A3E),
    ),
    ShelfBook(
      id: '3',
      title: 'The Wild\nIris',
      author: 'Louise Glück',
      status: ShelfStatus.wantToRead,
      coverColor: Color(0xFFE3E0E8),
      textColor: Color(0xFF2D4A3E),
    ),
  ];

  void _showEditProfileSheet(BuildContext context) {
    final nameCtrl = TextEditingController(text: _profile.name);
    final handleCtrl = TextEditingController(text: _profile.handle);
    final bioCtrl = TextEditingController(text: _profile.bio);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Edit Profile',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: handleCtrl,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _profile = _profile.copyWith(
                        name: nameCtrl.text.trim(),
                        handle: handleCtrl.text.trim(),
                        bio: bioCtrl.text.trim(),
                      );
                    });
                    Navigator.of(ctx).pop();
                  },
                  child: Text(
                    'Save changes',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

  void _showSavedPassagesSheet(BuildContext context) {
    const passages = [
      (
        quote: 'And now that you don\'t have to be perfect, you can be good.',
        source: 'John Steinbeck · East of Eden',
      ),
      (
        quote: 'Creativity is not a rare ability. It is not difficult to access. Creativity is a fundamental aspect of being human.',
        source: 'Rick Rubin · The Creative Act',
      ),
      (
        quote: 'At the end of my suffering there was a door.',
        source: 'Louise Glück · The Wild Iris',
      ),
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Saved passages (24)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...passages.map((p) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.quoteCardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '"${p.quote}"',
                      style: GoogleFonts.lora(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p.source,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5A7E6F),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showReadingCirclesSheet(BuildContext context) {
    const circles = [
      (
        name: 'Quiet Mornings Club',
        members: '18 readers · #1 Emma Laurent (3h 36m/wk)',
      ),
      (
        name: 'Modern Classics Circle',
        members: '42 readers · Reading East of Eden',
      ),
      (
        name: 'Poetry & Tea',
        members: '14 readers · Reading The Wild Iris',
      ),
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'My reading circles',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...circles.map((c) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.people_outline_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  c.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  c.members,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // ── Header ─────────────────────────────────────
              _buildHeader(context),
              const SizedBox(height: 22),

              // ── Profile Identity & Stats ───────────────────
              ProfileHeaderSection(
                profile: _profile,
                onEditProfile: () => _showEditProfileSheet(context),
              ),
              const SizedBox(height: 26),

              // ── "On my shelf" Bookshelf Row ────────────────
              BookshelfSection(
                books: _shelfBooks,
                onViewAll: () {},
              ),
              const SizedBox(height: 22),

              // ── Saved Passages & Reading Circles Links ─────
              ProfileMenuSection(
                savedPassagesCount: _profile.savedPassagesCount,
                readingCirclesCount: _profile.readingCirclesCount,
                onSavedPassagesTap: () => _showSavedPassagesSheet(context),
                onReadingCirclesTap: () => _showReadingCirclesSheet(context),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your corner',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'The reader behind the pages.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Settings / Preferences Icon button
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.18),
              width: 1.5,
            ),
          ),
          child: IconButton(
            onPressed: () => _showEditProfileSheet(context),
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.tune_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
