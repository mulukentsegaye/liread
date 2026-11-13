import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../leaderboard/data/reading_session_store.dart';
import '../data/open_library_service.dart';
import '../domain/explore_category.dart';
import 'widgets/book_cover_image.dart';
import 'widgets/book_details_sheet.dart';

/// Full interactive Explore screen powered by Open Library API.
/// Supports book searching, curated category shelves, and book details.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Timer? _debounceTimer;
  String _activeQuery = '';
  bool _isSearching = false;

  // Search results
  List<OpenLibraryBook> _searchResults = [];
  int _searchTotalFound = 0;
  int _searchPage = 1;

  // Curated category browsing state
  String _selectedCategoryName = 'All';
  ExploreCategoryConfig? _viewingCategoryConfig;
  List<OpenLibraryBook> _categoryBooks = [];
  bool _isLoadingCategoryBooks = false;
  int _categoryPage = 1;

  // Cache for horizontal shelf data: subjectSlug -> books
  final Map<String, List<OpenLibraryBook>> _shelfBooks = {};
  final Set<String> _loadingShelves = {};

  @override
  void initState() {
    super.initState();
    _loadInitialShelves();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _loadInitialShelves() {
    // Pre-load the first 4 curated shelves for instant offline/online viewing
    for (final cat in kExploreCategories.take(4)) {
      _loadShelf(cat.subjectSlug);
    }
  }

  Future<void> _loadShelf(String subjectSlug) async {
    if (_shelfBooks.containsKey(subjectSlug) || _loadingShelves.contains(subjectSlug)) {
      return;
    }
    _loadingShelves.add(subjectSlug);
    final books = await OpenLibraryService.instance.getCategoryBooks(subjectSlug, limit: 10);
    if (mounted) {
      setState(() {
        _shelfBooks[subjectSlug] = books;
        _loadingShelves.remove(subjectSlug);
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    final trimmed = value.trim();

    if (trimmed.length < 2) {
      setState(() {
        _activeQuery = '';
        _searchResults = [];
        _searchTotalFound = 0;
        _isSearching = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _executeSearch(trimmed, page: 1);
    });
  }

  Future<void> _executeSearch(String query, {int page = 1}) async {
    setState(() {
      _activeQuery = query;
      _searchPage = page;
      _isSearching = true;
    });

    final result = await OpenLibraryService.instance.searchBooks(
      query,
      page: page,
      limit: 20,
    );

    if (mounted && _activeQuery == query) {
      setState(() {
        _searchResults = result.books;
        _searchTotalFound = result.totalFound;
        _isSearching = false;
      });
    }
  }

  void _selectCategory(String categoryName) {
    if (categoryName == 'All') {
      setState(() {
        _selectedCategoryName = 'All';
        _viewingCategoryConfig = null;
      });
      return;
    }

    final config = kExploreCategories.firstWhere(
      (c) => c.name.toLowerCase() == categoryName.toLowerCase(),
      orElse: () => kExploreCategories.first,
    );

    _openCategoryDetail(config);
  }

  Future<void> _openCategoryDetail(ExploreCategoryConfig config, {int page = 1}) async {
    setState(() {
      _selectedCategoryName = config.name;
      _viewingCategoryConfig = config;
      _categoryPage = page;
      _isLoadingCategoryBooks = true;
    });

    final books = await OpenLibraryService.instance.getCategoryBooks(
      config.subjectSlug,
      page: page,
      limit: 20,
    );

    if (mounted && _viewingCategoryConfig?.id == config.id) {
      setState(() {
        _categoryBooks = books;
        _isLoadingCategoryBooks = false;
      });
    }
  }

  void _handleBookSelected(OpenLibraryBook book) {
    BookDetailsSheet.show(
      context,
      book: book,
      onStartTimer: (b) {
        ReadingSessionStore.instance.selectBookForTimer(
          b.title,
          b.author,
          coverUrl: b.coverImageUrl ?? b.coverThumbnailUrl,
        );
      },
    );
  }

  void _startTimerWithBook(OpenLibraryBook book) {
    ReadingSessionStore.instance.selectBookForTimer(
      book.title,
      book.author,
      coverUrl: book.coverImageUrl ?? book.coverThumbnailUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppThemeController.instance,
      builder: (context, _) {
        final isDark = AppThemeController.instance.isDarkMode;
        final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
        final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
        final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
        final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
        final dividerColor = isDark ? AppColors.darkDivider : AppColors.divider;
        final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header with Explore Title & Compass
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.explore_rounded,
                                size: 22,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Explore',
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Search Open Library & curated bookshelves',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                      // Quick source badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkPrimarySurface : AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.public_rounded,
                              size: 13,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Open Library',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Input Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _onSearchChanged,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search title, author, or subject...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          color: textSecondary.withValues(alpha: 0.7),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: primaryColor,
                          size: 20,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                color: textSecondary,
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                      ),
                    ),
                  ),
                ),

                // Main Content (Search Results OR Curated Shelves)
                Expanded(
                  child: _activeQuery.isNotEmpty
                      ? _buildSearchResults(
                          isDark,
                          surfaceColor,
                          textPrimary,
                          textSecondary,
                          dividerColor,
                          primaryColor,
                        )
                      : (_viewingCategoryConfig != null
                          ? _buildCategoryDetailView(
                              isDark,
                              surfaceColor,
                              textPrimary,
                              textSecondary,
                              dividerColor,
                              primaryColor,
                            )
                          : _buildCuratedShelvesView(
                              isDark,
                              surfaceColor,
                              textPrimary,
                              textSecondary,
                              dividerColor,
                              primaryColor,
                            )),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SEARCH RESULTS VIEW
  // ─────────────────────────────────────────────────────────────

  Widget _buildSearchResults(
    bool isDark,
    Color surfaceColor,
    Color textPrimary,
    Color textSecondary,
    Color dividerColor,
    Color primaryColor,
  ) {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor, strokeWidth: 2.5),
            const SizedBox(height: 14),
            Text(
              'Searching Open Library...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No matching books found',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Try searching by a broader keyword, author name, or title.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Result Summary Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_searchTotalFound books found for "$_activeQuery"',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              Text(
                'Page $_searchPage',
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Grid of Books
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 16,
              childAspectRatio: 0.58,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final book = _searchResults[index];
              return _buildBookCard(
                book,
                surfaceColor,
                textPrimary,
                textSecondary,
                dividerColor,
                primaryColor,
              );
            },
          ),
        ),

        // Pagination Bar
        _buildPaginationBar(
          currentPage: _searchPage,
          totalItems: _searchTotalFound,
          pageSize: 20,
          onPageChange: (newPage) => _executeSearch(_activeQuery, page: newPage),
          surfaceColor: surfaceColor,
          dividerColor: dividerColor,
          primaryColor: primaryColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CURATED SHELVES VIEW (DEFAULT)
  // ─────────────────────────────────────────────────────────────

  Widget _buildCuratedShelvesView(
    bool isDark,
    Color surfaceColor,
    Color textPrimary,
    Color textSecondary,
    Color dividerColor,
    Color primaryColor,
  ) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const SizedBox(height: 8),

        // Category Pills Filter Strip
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildCategoryPill('All', isSelected: _selectedCategoryName == 'All', primaryColor: primaryColor, surfaceColor: surfaceColor, dividerColor: dividerColor, textPrimary: textPrimary, textSecondary: textSecondary),
              const SizedBox(width: 8),
              ...kExploreCategories.map((c) {
                final isSelected = _selectedCategoryName == c.name;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildCategoryPill(c.name, isSelected: isSelected, primaryColor: primaryColor, surfaceColor: surfaceColor, dividerColor: dividerColor, textPrimary: textPrimary, textSecondary: textSecondary),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Featured Spotlight of the Week Banner
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildSpotlightBanner(
            isDark,
            surfaceColor,
            textPrimary,
            textSecondary,
            dividerColor,
            primaryColor,
          ),
        ),
        const SizedBox(height: 24),

        // Curated Category Horizontal Shelves
        ...kExploreCategories.map((category) {
          final books = _shelfBooks[category.subjectSlug] ?? [];
          final isLoading = _loadingShelves.contains(category.subjectSlug);

          // Lazy load if not loaded yet
          if (books.isEmpty && !isLoading) {
            _loadShelf(category.subjectSlug);
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _buildHorizontalShelf(
              category: category,
              books: books,
              isLoading: isLoading,
              surfaceColor: surfaceColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              dividerColor: dividerColor,
              primaryColor: primaryColor,
            ),
          );
        }),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CATEGORY DETAIL PAGINATED GRID VIEW ("SEE ALL")
  // ─────────────────────────────────────────────────────────────

  Widget _buildCategoryDetailView(
    bool isDark,
    Color surfaceColor,
    Color textPrimary,
    Color textSecondary,
    Color dividerColor,
    Color primaryColor,
  ) {
    final config = _viewingCategoryConfig!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header Strip
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _viewingCategoryConfig = null;
                    _selectedCategoryName = 'All';
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_rounded, size: 16, color: primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        'Back to all shelves',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(config.icon, size: 20, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    config.shelfTitle,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                config.tagline,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Grid Content
        Expanded(
          child: _isLoadingCategoryBooks
              ? Center(
                  child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2.5),
                )
              : _categoryBooks.isEmpty
                  ? Center(
                      child: Text(
                        'Could not load books for this category.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.58,
                      ),
                      itemCount: _categoryBooks.length,
                      itemBuilder: (context, index) {
                        final book = _categoryBooks[index];
                        return _buildBookCard(
                          book,
                          surfaceColor,
                          textPrimary,
                          textSecondary,
                          dividerColor,
                          primaryColor,
                        );
                      },
                    ),
        ),

        // Pagination controls for Category
        _buildPaginationBar(
          currentPage: _categoryPage,
          totalItems: 120, // Estimated subject catalog size
          pageSize: 20,
          onPageChange: (newPage) => _openCategoryDetail(config, page: newPage),
          surfaceColor: surfaceColor,
          dividerColor: dividerColor,
          primaryColor: primaryColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // REUSABLE WIDGETS
  // ─────────────────────────────────────────────────────────────

  Widget _buildCategoryPill(
    String name, {
    required bool isSelected,
    required Color primaryColor,
    required Color surfaceColor,
    required Color dividerColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return GestureDetector(
      onTap: () => _selectCategory(name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : surfaceColor,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: isSelected ? primaryColor : dividerColor,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSpotlightBanner(
    bool isDark,
    Color surfaceColor,
    Color textPrimary,
    Color textSecondary,
    Color dividerColor,
    Color primaryColor,
  ) {
    const spotlightTitle = 'Before the coffee gets cold';
    const spotlightAuthor = 'Toshikazu Kawaguchi';
    const spotlightCover =
        'https://covers.openlibrary.org/b/id/9255566-L.jpg';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cover Thumbnail
          SizedBox(
            width: 72,
            child: BookCoverImage(
              title: spotlightTitle,
              author: spotlightAuthor,
              coverUrl: spotlightCover,
            ),
          ),
          const SizedBox(width: 14),

          // Details & Action
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 14, color: primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      'BOOK OF THE WEEK',
                      style: GoogleFonts.spaceMono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  spotlightTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: textPrimary,
                  ),
                ),
                Text(
                  spotlightAuthor,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 8),

                // Quick Timer Button
                ElevatedButton.icon(
                  onPressed: () {
                    ReadingSessionStore.instance.selectBookForTimer(
                      spotlightTitle,
                      spotlightAuthor,
                      coverUrl: spotlightCover,
                    );
                  },
                  icon: const Icon(Icons.timer_outlined, size: 14),
                  label: const Text('Start Timer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalShelf({
    required ExploreCategoryConfig category,
    required List<OpenLibraryBook> books,
    required bool isLoading,
    required Color surfaceColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color dividerColor,
    required Color primaryColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shelf Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(category.icon, size: 18, color: primaryColor),
                  const SizedBox(width: 7),
                  Text(
                    category.shelfTitle,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _openCategoryDetail(category),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'See all',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 16, color: primaryColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Horizontal Books Track
        SizedBox(
          height: 220,
          child: isLoading && books.isEmpty
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: 4,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, _) => Container(
                    width: 125,
                    decoration: BoxDecoration(
                      color: surfaceColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: dividerColor),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: books.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    if (index == books.length) {
                      // Trailing "Explore all" card
                      return GestureDetector(
                        onTap: () => _openCategoryDetail(category),
                        child: Container(
                          width: 125,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: dividerColor),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: primaryColor.withValues(alpha: 0.12),
                                child: Icon(Icons.arrow_forward_rounded, color: primaryColor, size: 20),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Explore All',
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                '${category.name} catalog',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final book = books[index];
                    return GestureDetector(
                      onTap: () => _handleBookSelected(book),
                      child: Container(
                        width: 125,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: dividerColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cover
                            Expanded(
                              child: Center(
                                child: BookCoverImage(
                                  title: book.title,
                                  author: book.author,
                                  coverUrl: book.coverImageUrl ?? book.coverThumbnailUrl,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Title & Author
                            Text(
                              book.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              book.author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Year & Quick Timer Icon
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  book.firstPublishYear != null ? '${book.firstPublishYear}' : 'Classic',
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 9.5,
                                    color: textSecondary,
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _startTimerWithBook(book),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(3),
                                    child: Icon(
                                      Icons.timer_outlined,
                                      size: 15,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBookCard(
    OpenLibraryBook book,
    Color surfaceColor,
    Color textPrimary,
    Color textSecondary,
    Color dividerColor,
    Color primaryColor,
  ) {
    return GestureDetector(
      onTap: () => _handleBookSelected(book),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            Expanded(
              child: Center(
                child: BookCoverImage(
                  title: book.title,
                  author: book.author,
                  coverUrl: book.coverImageUrl ?? book.coverThumbnailUrl,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Title & Author
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                height: 1.15,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 6),

            // Year and Timer Action Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  book.firstPublishYear != null ? '${book.firstPublishYear}' : 'Classic',
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    color: textSecondary,
                  ),
                ),
                InkWell(
                  onTap: () => _startTimerWithBook(book),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, size: 12, color: primaryColor),
                        const SizedBox(width: 3),
                        Text(
                          'Timer',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
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
    );
  }

  Widget _buildPaginationBar({
    required int currentPage,
    required int totalItems,
    required int pageSize,
    required ValueChanged<int> onPageChange,
    required Color surfaceColor,
    required Color dividerColor,
    required Color primaryColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final totalPages = (totalItems / pageSize).ceil().clamp(1, 100);
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(top: BorderSide(color: dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Previous button
            TextButton.icon(
              onPressed: currentPage > 1 ? () => onPageChange(currentPage - 1) : null,
              icon: const Icon(Icons.chevron_left_rounded, size: 18),
              label: const Text('Prev'),
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
                disabledForegroundColor: textSecondary.withValues(alpha: 0.3),
              ),
            ),

            // Current of Total Indicator
            Text(
              'Page $currentPage of $totalPages',
              style: GoogleFonts.spaceMono(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),

            // Next button
            TextButton.icon(
              onPressed: currentPage < totalPages ? () => onPageChange(currentPage + 1) : null,
              icon: const Icon(Icons.chevron_right_rounded, size: 18),
              label: const Text('Next'),
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
                disabledForegroundColor: textSecondary.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
