import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../data/ebook_download_service.dart';
import '../../data/open_library_service.dart';
import '../../data/telegram_bot_service.dart';
import 'book_cover_image.dart';

/// Modal bottom sheet displaying detailed book metadata and actions.
class BookDetailsSheet extends StatefulWidget {
  final OpenLibraryBook book;
  final ValueChanged<OpenLibraryBook>? onStartTimer;
  final ValueChanged<OpenLibraryBook>? onShareBook;

  const BookDetailsSheet({
    super.key,
    required this.book,
    this.onStartTimer,
    this.onShareBook,
  });

  static Future<void> show(
    BuildContext context, {
    required OpenLibraryBook book,
    ValueChanged<OpenLibraryBook>? onStartTimer,
    ValueChanged<OpenLibraryBook>? onShareBook,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookDetailsSheet(
        book: book,
        onStartTimer: onStartTimer,
        onShareBook: onShareBook,
      ),
    );
  }

  @override
  State<BookDetailsSheet> createState() => _BookDetailsSheetState();
}

class _BookDetailsSheetState extends State<BookDetailsSheet> {
  late OpenLibraryBook _book;
  bool _loadingDetails = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _downloadedFilePath;
  String _selectedFormat = 'epub';
  String _botUsername = TelegramBotService.defaultBotName;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _fetchDetails();
    _loadBotUsername();

    final active = EbookDownloadService.instance.currentTask.value;
    if (active != null && active.bookId == _book.id) {
      if (active.isRunning) {
        _isDownloading = true;
        _downloadProgress = active.progress >= 0 ? active.progress : 0.0;
      } else if (active.isCompleted) {
        _downloadedFilePath = active.localUri ?? active.localFilePath;
      }
    }
    EbookDownloadService.instance.currentTask.addListener(_onTaskChanged);
  }

  @override
  void dispose() {
    EbookDownloadService.instance.currentTask.removeListener(_onTaskChanged);
    super.dispose();
  }

  void _onTaskChanged() {
    final task = EbookDownloadService.instance.currentTask.value;
    if (!mounted) return;
    if (task != null && task.bookId == _book.id) {
      setState(() {
        _isDownloading = task.isRunning;
        if (task.progress >= 0) _downloadProgress = task.progress;
        if (task.isCompleted) {
          _downloadedFilePath = task.localUri ?? task.localFilePath;
        }
      });
    } else if (_isDownloading && (task == null || task.bookId != _book.id)) {
      setState(() => _isDownloading = false);
    }
  }

  Future<void> _loadBotUsername() async {
    final bot = await TelegramBotService.instance.getBotUsername();
    if (mounted) setState(() => _botUsername = bot);
  }

  Future<void> _handleDownload() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Downloading "${_book.title}" in the background. You can explore or leave the app—progress will show in your notification bar.',
        ),
        duration: const Duration(seconds: 3),
      ),
    );

    final result = await EbookDownloadService.instance.downloadBook(
      book: _book,
      format: _selectedFormat,
      onProgress: (p) {
        if (mounted) setState(() => _downloadProgress = p);
      },
    );

    if (!mounted) return;
    final targetPath = result.localUri ?? result.filePath;
    setState(() {
      _isDownloading = false;
      if (result.success) {
        _downloadedFilePath = targetPath;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success
            ? 'Downloaded "${_book.title}" (${_selectedFormat.toUpperCase()})!'
            : 'Download failed: ${result.message}'),
        action: result.success && targetPath != null
            ? SnackBarAction(
                label: 'Open',
                onPressed: () => EbookDownloadService.instance.openDownloadedBook(
                  targetPath,
                  downloadId: result.nativeDownloadId,
                  format: _selectedFormat,
                ),
              )
            : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _handleSendToTelegramBot() async {
    final ok = await TelegramBotService.instance.launchBotWithBook(_book);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Could not open Telegram with @$_botUsername. Check your connection or bot configuration.'),
        ),
      );
    }
  }

  Future<void> _handleShareToTelegram() async {
    await TelegramBotService.instance.shareBookToTelegram(_book);
  }

  Future<void> _showConfigureBotDialog() async {
    final controller = TextEditingController(text: _botUsername);
    final updated = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Configure Telegram Bot',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the Telegram bot username you want Liread to redirect to for book downloads:',
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                prefixText: '@',
                hintText: 'BooksFinderBot',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (updated != null && updated.isNotEmpty) {
      await TelegramBotService.instance.setBotUsername(updated);
      if (mounted) {
        setState(() => _botUsername = updated.replaceAll('@', ''));
      }
    }
  }

  Future<void> _fetchDetails() async {
    if (_book.description == null && _book.workKey != null) {
      setState(() => _loadingDetails = true);
      final enriched =
          await OpenLibraryService.instance.fetchBookDetails(_book);
      if (mounted) {
        setState(() {
          _book = enriched;
          _loadingDetails = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.instance.isDarkMode;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Scrollable Body
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book Banner & Metadata Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Book Cover
                      SizedBox(
                        width: 100,
                        child: BookCoverImage(
                          title: _book.title,
                          author: _book.author,
                          coverUrl: _book.coverImageUrl ?? _book.coverThumbnailUrl,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Title, Author, Year, Source
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _book.title,
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _book.author,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),

                            if (_book.firstPublishYear != null)
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 13,
                                    color: textSecondary,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'First published ${_book.firstPublishYear}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 6),

                            // Open Library verification badge
                            Row(
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  size: 13,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Open Library Catalog',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Subject Pills
                  if (_book.subjects.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _book.subjects.map((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkPrimarySurface
                                : AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            s,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: primaryColor,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Divider
                  Divider(color: dividerColor),
                  const SizedBox(height: 12),

                  // Description Header
                  Text(
                    'About this book',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),

                  if (_loadingDetails)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Loading editorial description...',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_book.description != null &&
                      _book.description!.isNotEmpty)
                    Text(
                      _book.description!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        height: 1.5,
                        color: textSecondary,
                      ),
                    )
                  else
                    Text(
                      'No editorial summary is currently recorded in Open Library for this edition. You can still track your reading session and save quotes from it.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                        color: textSecondary,
                      ),
                    ),

                  // ── Direct 1-Click eBook Download ─────────────────
                  _buildDownloadSection(
                    isDark: isDark,
                    primaryColor: primaryColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    dividerColor: dividerColor,
                  ),

                  // ── Telegram Bot Redirect ─────────────────────────
                  _buildTelegramSection(
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    dividerColor: dividerColor,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Action Buttons
          SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await SupabaseService.instance.updateBookStatus(
                        title: _book.title,
                        author: _book.author,
                        status: 'want_to_read',
                        coverImageUrl: _book.coverImageUrl,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('"${_book.title}" added to your bookshelf!'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.bookmark_add_outlined, size: 17),
                    label: Text(
                      'Add to Shelf',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onStartTimer?.call(_book);
                    },
                    icon: const Icon(Icons.timer_outlined, size: 17),
                    label: Text(
                      'Read in Timer',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF222B25)
                        : const Color(0xFFEEF2EF),
                    foregroundColor: textPrimary,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadSection({
    required bool isDark,
    required Color primaryColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color dividerColor,
  }) {
    final hasFree = _book.hasFreeDownload;
    final cardBg = isDark
        ? (hasFree ? const Color(0xFF14221A) : const Color(0xFF1B1E21))
        : (hasFree ? const Color(0xFFF3F8F5) : const Color(0xFFF7F8F9));
    final borderColor =
        hasFree ? primaryColor.withValues(alpha: 0.35) : dividerColor;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (hasFree ? primaryColor : Colors.grey)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasFree ? Icons.download_rounded : Icons.lock_outline_rounded,
                  size: 18,
                  color: hasFree ? primaryColor : textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Direct eBook Download',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      hasFree
                          ? 'Public domain · DRM-free full text'
                          : 'Modern edition · Protected by copyright',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasFree)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Free',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasFree) ...[
            // Format choice pills
            Row(
              children: [
                _buildFormatChoice(
                  label: 'EPUB',
                  isSelected: _selectedFormat == 'epub',
                  primaryColor: primaryColor,
                  isDark: isDark,
                  onTap: () => setState(() => _selectedFormat = 'epub'),
                ),
                const SizedBox(width: 8),
                _buildFormatChoice(
                  label: 'PDF',
                  isSelected: _selectedFormat == 'pdf',
                  primaryColor: primaryColor,
                  isDark: isDark,
                  onTap: () => setState(() => _selectedFormat = 'pdf'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isDownloading) ...[
              LinearProgressIndicator(
                value: _downloadProgress > 0 ? _downloadProgress : null,
                backgroundColor: primaryColor.withValues(alpha: 0.2),
                color: primaryColor,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _downloadProgress > 0
                        ? 'Downloading ${(_downloadProgress * 100).toInt()}% • In background'
                        : 'Connecting to archive servers...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                  Text(
                    'Progress in notification',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ] else if (_downloadedFilePath != null) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => EbookDownloadService.instance
                          .openDownloadedBook(
                        _downloadedFilePath!,
                        format: _selectedFormat,
                      ),
                      icon: const Icon(Icons.folder_open_rounded, size: 16),
                      label: Text(
                          'Open ${_selectedFormat.toUpperCase()} File'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _handleDownload,
                    tooltip: 'Download again',
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _handleDownload,
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label:
                      Text('Download ${_selectedFormat.toUpperCase()} (1-Click)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ] else ...[
            Text(
              'Direct DRM-free file downloads are not hosted on Open Library for this copyrighted edition. Use the Telegram bot below to receive or search for this book file.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                height: 1.4,
                color: textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTelegramSection({
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color dividerColor,
  }) {
    const telegramBlue = Color(0xFF2AABEE);
    final cardBg =
        isDark ? const Color(0xFF14202B) : const Color(0xFFF1F8FC);
    final borderColor = telegramBlue.withValues(alpha: 0.3);

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: telegramBlue.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  size: 17,
                  color: telegramBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Get via Telegram Bot',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Sends book query & receives file in Telegram',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _showConfigureBotDialog,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: telegramBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '@$_botUsername',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: telegramBlue,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.edit_outlined,
                          size: 12, color: telegramBlue),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Redirects to Telegram and submits "${_book.title}" to @$_botUsername so the bot can send you the book file directly.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              height: 1.4,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _handleSendToTelegramBot,
                  icon: const Icon(Icons.send_rounded, size: 15),
                  label: const Text('Send to Telegram Bot'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: telegramBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _handleShareToTelegram,
                icon: const Icon(Icons.share_outlined, size: 15),
                label: const Text('Share Card'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: telegramBlue,
                  side:
                      BorderSide(color: telegramBlue.withValues(alpha: 0.5)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormatChoice({
    required String label,
    required bool isSelected,
    required Color primaryColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : (isDark
                  ? const Color(0xFF222B25)
                  : const Color(0xFFE8ECE9)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }
}
