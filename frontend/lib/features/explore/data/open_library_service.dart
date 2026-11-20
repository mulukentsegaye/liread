import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Data model representing a book fetched from Open Library.
class OpenLibraryBook {
  final String id;
  final String title;
  final String author;
  final String? coverImageUrl;
  final String? coverThumbnailUrl;
  final int? firstPublishYear;
  final int? coverId;
  final String? workKey;
  final String? description;
  final List<String> subjects;
  final String? iaId;
  final bool hasFulltext;
  final String? ebookAccess;

  String? get coverUrl => coverImageUrl;

  bool get isPublicDomain => ebookAccess == 'public';
  bool get hasFreeDownload =>
      (isPublicDomain || hasFulltext) && iaId != null && iaId!.isNotEmpty;
  String? get epubDownloadUrl =>
      hasFreeDownload ? 'https://archive.org/download/$iaId/$iaId.epub' : null;
  String? get pdfDownloadUrl =>
      hasFreeDownload ? 'https://archive.org/download/$iaId/$iaId.pdf' : null;
  String? get archiveDetailsUrl =>
      iaId != null ? 'https://archive.org/details/$iaId' : null;

  const OpenLibraryBook({
    required this.id,
    required this.title,
    required this.author,
    this.coverImageUrl,
    this.coverThumbnailUrl,
    this.firstPublishYear,
    this.coverId,
    this.workKey,
    this.description,
    this.subjects = const [],
    this.iaId,
    this.hasFulltext = false,
    this.ebookAccess,
  });

  factory OpenLibraryBook.fromDoc(Map<String, dynamic> doc) {
    final title = (doc['title'] as String? ?? 'Untitled Book').trim();

    String author = 'Unknown Author';
    if (doc['author_name'] is List && (doc['author_name'] as List).isNotEmpty) {
      author = (doc['author_name'] as List).first.toString().trim();
    }

    int? coverId;
    if (doc['cover_i'] is int) {
      coverId = doc['cover_i'] as int;
    } else if (doc['cover_i'] != null) {
      coverId = int.tryParse(doc['cover_i'].toString());
    }

    String? coverImageUrl;
    String? coverThumbnailUrl;

    if (coverId != null && coverId > 0) {
      coverImageUrl = 'https://covers.openlibrary.org/b/id/$coverId-L.jpg';
      coverThumbnailUrl = 'https://covers.openlibrary.org/b/id/$coverId-M.jpg';
    } else if (doc['cover_edition_key'] != null) {
      final key = doc['cover_edition_key'].toString();
      coverImageUrl = 'https://covers.openlibrary.org/b/olid/$key-L.jpg';
      coverThumbnailUrl = 'https://covers.openlibrary.org/b/olid/$key-M.jpg';
    } else if (doc['isbn'] is List && (doc['isbn'] as List).isNotEmpty) {
      final isbn = (doc['isbn'] as List).first.toString();
      coverImageUrl = 'https://covers.openlibrary.org/b/isbn/$isbn-L.jpg';
      coverThumbnailUrl = 'https://covers.openlibrary.org/b/isbn/$isbn-M.jpg';
    }

    int? firstYear;
    if (doc['first_publish_year'] is int) {
      firstYear = doc['first_publish_year'] as int;
    } else if (doc['first_publish_year'] != null) {
      firstYear = int.tryParse(doc['first_publish_year'].toString());
    }

    final key = doc['key'] as String? ?? '';
    final rawSubjects = doc['subject'];
    List<String> subjects = const [];
    if (rawSubjects is List) {
      subjects = rawSubjects
          .take(5)
          .map((s) => s.toString())
          .toList(growable: false);
    }

    String? iaId;
    if (doc['ia'] is List && (doc['ia'] as List).isNotEmpty) {
      iaId = (doc['ia'] as List).first.toString();
    } else if (doc['ia'] is String) {
      iaId = doc['ia'] as String;
    }

    final hasFulltext = doc['has_fulltext'] == true;
    final ebookAccess = doc['ebook_access']?.toString();

    return OpenLibraryBook(
      id: key.isNotEmpty ? key : '$title-$author-${coverId ?? 0}',
      title: title,
      author: author,
      coverImageUrl: coverImageUrl,
      coverThumbnailUrl: coverThumbnailUrl ?? coverImageUrl,
      firstPublishYear: firstYear,
      coverId: coverId,
      workKey: key,
      subjects: subjects,
      iaId: iaId,
      hasFulltext: hasFulltext,
      ebookAccess: ebookAccess,
    );
  }

  OpenLibraryBook copyWith({
    String? description,
    List<String>? subjects,
    String? coverImageUrl,
    String? iaId,
    bool? hasFulltext,
    String? ebookAccess,
  }) {
    return OpenLibraryBook(
      id: id,
      title: title,
      author: author,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      coverThumbnailUrl: coverThumbnailUrl,
      firstPublishYear: firstPublishYear,
      coverId: coverId,
      workKey: workKey,
      description: description ?? this.description,
      subjects: subjects ?? this.subjects,
      iaId: iaId ?? this.iaId,
      hasFulltext: hasFulltext ?? this.hasFulltext,
      ebookAccess: ebookAccess ?? this.ebookAccess,
    );
  }
}

class SearchBooksResult {
  final List<OpenLibraryBook> books;
  final int totalFound;

  const SearchBooksResult({
    required this.books,
    required this.totalFound,
  });
}

/// Service to interact with the Open Library API.
class OpenLibraryService {
  OpenLibraryService._();
  static final OpenLibraryService instance = OpenLibraryService._();

  // In-memory cache to ensure instant back-and-forth browsing and respect rate-limits
  final Map<String, SearchBooksResult> _searchCache = {};
  final Map<String, List<OpenLibraryBook>> _shelfCache = {};
  final Map<String, String> _descriptionCache = {};

  static const String _userAgent = 'LireadMobile/1.0 (contact: liread@app.local)';

  /// Search Open Library books by user keyword query.
  Future<SearchBooksResult> searchBooks(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 2) {
      return const SearchBooksResult(books: [], totalFound: 0);
    }

    final cacheKey = '${cleanQuery.toLowerCase()}_${page}_$limit';
    if (_searchCache.containsKey(cacheKey)) {
      return _searchCache[cacheKey]!;
    }

    const fields =
        'key,title,author_name,cover_i,cover_edition_key,first_publish_year,isbn,subject,ia,has_fulltext,ebook_access';
    final uri = Uri.parse(
      'https://openlibrary.org/search.json?q=${Uri.encodeComponent(cleanQuery)}&fields=$fields&limit=$limit&page=$page',
    );

    try {
      final response = await http
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final docs = data['docs'] as List? ?? [];
        final totalFound = (data['numFound'] ?? data['num_found'] ?? docs.length) as int;

        final books = docs
            .map((d) => OpenLibraryBook.fromDoc(d as Map<String, dynamic>))
            .toList();

        final result = SearchBooksResult(books: books, totalFound: totalFound);
        _searchCache[cacheKey] = result;
        return result;
      } else {
        debugPrint('OpenLibrary search failed with code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('OpenLibrary search network error: $e');
    }

    // Offline search fallback across curated books & cached shelves
    final offlineMatches = _searchOfflineBooks(cleanQuery);
    return SearchBooksResult(books: offlineMatches, totalFound: offlineMatches.length);
  }

  /// Fetch curated category shelf books from Open Library Subjects API.
  Future<List<OpenLibraryBook>> getCategoryBooks(
    String subjectSlug, {
    int page = 1,
    int limit = 16,
  }) async {
    final cacheKey = '${subjectSlug.toLowerCase()}_${page}_$limit';
    if (_shelfCache.containsKey(cacheKey)) {
      return _shelfCache[cacheKey]!;
    }

    const fields =
        'key,title,author_name,cover_i,cover_edition_key,first_publish_year,isbn,subject,ia,has_fulltext,ebook_access';
    final uri = Uri.parse(
      'https://openlibrary.org/search.json?subject=${Uri.encodeComponent(subjectSlug)}&fields=$fields&limit=$limit&page=$page',
    );

    try {
      final response = await http
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final docs = data['docs'] as List? ?? [];

        final books = docs
            .map((d) => OpenLibraryBook.fromDoc(d as Map<String, dynamic>))
            .toList();

        if (books.isNotEmpty) {
          _shelfCache[cacheKey] = books;
          return books;
        }
      }
    } catch (e) {
      debugPrint('OpenLibrary category network error for $subjectSlug: $e');
    }

    // Offline / fallback response with curated classics
    final offlineBooks = _getCuratedOfflineBooks(subjectSlug);
    _shelfCache[cacheKey] = offlineBooks;
    return offlineBooks;
  }

  List<OpenLibraryBook> _getCuratedOfflineBooks(String subjectSlug) {
    final slug = subjectSlug.toLowerCase().trim();
    if (_curatedOfflineShelfMap.containsKey(slug)) {
      return _curatedOfflineShelfMap[slug]!;
    }
    // Fallback to philosophy / fiction if unknown slug
    return _curatedOfflineShelfMap['philosophy'] ?? const [];
  }

  List<OpenLibraryBook> _searchOfflineBooks(String query) {
    final q = query.toLowerCase().trim();
    final List<OpenLibraryBook> matches = [];

    // Search in-memory shelf cache first
    for (final list in _shelfCache.values) {
      for (final b in list) {
        if ((b.title.toLowerCase().contains(q) || b.author.toLowerCase().contains(q)) &&
            !matches.any((m) => m.id == b.id)) {
          matches.add(b);
        }
      }
    }

    // Search curated offline map
    for (final list in _curatedOfflineShelfMap.values) {
      for (final b in list) {
        if ((b.title.toLowerCase().contains(q) || b.author.toLowerCase().contains(q)) &&
            !matches.any((m) => m.id == b.id)) {
          matches.add(b);
        }
      }
    }

    return matches;
  }

  /// Fetch editorial description and expanded metadata from Works endpoint.
  Future<OpenLibraryBook> fetchBookDetails(OpenLibraryBook book) async {
    if (book.description != null && book.description!.isNotEmpty) {
      return book;
    }

    final key = book.workKey ?? '';
    if (key.isEmpty) return book;

    if (_descriptionCache.containsKey(key)) {
      return book.copyWith(description: _descriptionCache[key]);
    }

    final cleanKey = key.startsWith('/') ? key : '/$key';
    final uri = Uri.parse('https://openlibrary.org$cleanKey.json');

    try {
      final response = await http
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        String? desc;

        final rawDesc = data['description'];
        if (rawDesc is String) {
          desc = rawDesc;
        } else if (rawDesc is Map && rawDesc['value'] is String) {
          desc = rawDesc['value'] as String;
        }

        if (desc != null) {
          _descriptionCache[key] = desc;
        }

        // If iaId wasn't previously loaded, check work editions
        String? iaId = book.iaId;
        String? ebookAccess = book.ebookAccess;
        bool hasFulltext = book.hasFulltext;

        if (iaId == null) {
          try {
            final edUri = Uri.parse('https://openlibrary.org$cleanKey/editions.json?limit=3');
            final edRes = await http
                .get(edUri, headers: {'User-Agent': _userAgent})
                .timeout(const Duration(seconds: 5));
            if (edRes.statusCode == 200) {
              final edData = json.decode(edRes.body) as Map<String, dynamic>;
              final entries = edData['entries'] as List? ?? [];
              for (final entry in entries) {
                final ocaid = entry['ocaid'] ??
                    (entry['ia'] is List && (entry['ia'] as List).isNotEmpty
                        ? entry['ia'][0]
                        : null);
                if (ocaid != null) {
                  iaId = ocaid.toString();
                  hasFulltext = true;
                  ebookAccess = 'public';
                  break;
                }
              }
            }
          } catch (_) {}
        }

        return book.copyWith(
          description: desc,
          iaId: iaId,
          ebookAccess: ebookAccess,
          hasFulltext: hasFulltext,
        );
      }
    } catch (e) {
      debugPrint('Error fetching book details for $key: $e');
    }

    return book;
  }
}

const Map<String, List<OpenLibraryBook>> _curatedOfflineShelfMap = {
  'philosophy': [
    OpenLibraryBook(
      id: '/works/OL267863W',
      workKey: '/works/OL267863W',
      title: 'Meditations',
      author: 'Marcus Aurelius',
      coverImageUrl: 'https://covers.openlibrary.org/b/id/8231996-L.jpg',
      coverThumbnailUrl: 'https://covers.openlibrary.org/b/id/8231996-M.jpg',
      firstPublishYear: 167,
      description: 'Private reflections and timeless Stoic principles from the Roman Emperor on duty, mortality, and inner stillness.',
      subjects: ['Philosophy', 'Stoicism', 'Ethics', 'Ancient Rome'],
      iaId: 'meditations00marc',
      hasFulltext: true,
      ebookAccess: 'public',
    ),
    OpenLibraryBook(
      id: '/works/OL150738W',
      workKey: '/works/OL150738W',
      title: 'Letters from a Stoic',
      author: 'Seneca',
      coverImageUrl: 'https://covers.openlibrary.org/b/id/7222246-L.jpg',
      coverThumbnailUrl: 'https://covers.openlibrary.org/b/id/7222246-M.jpg',
      firstPublishYear: 65,
      description: 'Moral epistles offering practical wisdom on friendship, contentment, resilience, and mortality.',
      subjects: ['Stoicism', 'Philosophy', 'Ethics', 'Wisdom'],
      iaId: 'epistulaemorales01seneuoft',
      hasFulltext: true,
      ebookAccess: 'public',
    ),
    OpenLibraryBook(
      id: '/works/OL102749W',
      workKey: '/works/OL102749W',
      title: 'The Republic',
      author: 'Plato',
      coverImageUrl: 'https://covers.openlibrary.org/b/id/7984916-L.jpg',
      coverThumbnailUrl: 'https://covers.openlibrary.org/b/id/7984916-M.jpg',
      firstPublishYear: -375,
      description: 'Socratic dialogue concerning justice, the ideal city-state, and the philosopher-king.',
      subjects: ['Philosophy', 'Political science', 'Justice', 'Ancient Greece'],
      iaId: 'republicofplato00plat',
      hasFulltext: true,
      ebookAccess: 'public',
    ),
    OpenLibraryBook(
      id: '/works/OL102711W',
      workKey: '/works/OL102711W',
      title: 'Beyond Good and Evil',
      author: 'Friedrich Nietzsche',
      coverImageUrl: 'https://covers.openlibrary.org/b/id/6486828-L.jpg',
      coverThumbnailUrl: 'https://covers.openlibrary.org/b/id/6486828-M.jpg',
      firstPublishYear: 1886,
      description: 'Critique of traditional morality, virtue, and philosophical dogmatism.',
      subjects: ['Philosophy', 'Ethics', 'Nietzsche', 'Modernity'],
      iaId: 'beyondgoodandev00nietgoog',
      hasFulltext: true,
      ebookAccess: 'public',
    ),
  ],
  'fiction': [
    OpenLibraryBook(
      id: '/works/OL66554W',
      workKey: '/works/OL66554W',
      title: 'Pride and Prejudice',
      author: 'Jane Austen',
      coverImageUrl: 'https://covers.openlibrary.org/b/id/8313886-L.jpg',
      coverThumbnailUrl: 'https://covers.openlibrary.org/b/id/8313886-M.jpg',
      firstPublishYear: 1813,
      description: 'A romantic masterpiece of manners, societal expectations, and emotional awakening in 19th-century England.',
      subjects: ['Classic Literature', 'Romance', 'British Literature', 'Social satire'],
      iaId: 'prideandprejudic01aust',
      hasFulltext: true,
      ebookAccess: 'public',
    ),
    OpenLibraryBook(
      id: '/works/OL45844W',
      workKey: '/works/OL45844W',
      title: 'Crime and Punishment',
      author: 'Fyodor Dostoevsky',
      coverImageUrl: 'https://covers.openlibrary.org/b/id/8235116-L.jpg',
      coverThumbnailUrl: 'https://covers.openlibrary.org/b/id/8235116-M.jpg',
      firstPublishYear: 1866,
      description: 'Psychological drama following Raskolnikov through the agony of guilt and spiritual redemption in St. Petersburg.',
      subjects: ['Russian Literature', 'Psychological Fiction', 'Philosophy', 'Morality'],
      iaId: 'crimeandpunishme00dostiala',
      hasFulltext: true,
      ebookAccess: 'public',
    ),
    OpenLibraryBook(
      id: '/works/OL14867175W',
      workKey: '/works/OL14867175W',
      title: 'The Picture of Dorian Gray',
      author: 'Oscar Wilde',
      coverImageUrl: 'https://covers.openlibrary.org/b/id/7222161-L.jpg',
      coverThumbnailUrl: 'https://covers.openlibrary.org/b/id/7222161-M.jpg',
      firstPublishYear: 1890,
      description: 'A cautionary Gothic tale of aestheticism, moral corruption, and hedonistic vanity.',
      subjects: ['Classic Fiction', 'Aestheticism', 'Gothic', 'Morality'],
      iaId: 'pictureofdoriang00wild',
      hasFulltext: true,
      ebookAccess: 'public',
    ),
    OpenLibraryBook(
      id: '/works/OL450063W',
      workKey: '/works/OL450063W',
      title: 'Frankenstein',
      author: 'Mary Shelley',
      coverImageUrl: 'https://covers.openlibrary.org/b/id/8225261-L.jpg',
      coverThumbnailUrl: 'https://covers.openlibrary.org/b/id/8225261-M.jpg',
      firstPublishYear: 1818,
      description: 'The monumental tale of Victor Frankenstein and the sentient creature brought to life through scientific hubris.',
      subjects: ['Gothic', 'Science Fiction', 'Horror', 'Classic Fiction'],
      iaId: 'frankensteinormo00shel',
      hasFulltext: true,
      ebookAccess: 'public',
    ),
  ],
  'poetry': [
    OpenLibraryBook(
      id: '/works/OL262423W',
      workKey: '/works/OL262423W',
      title: 'Leaves of Grass',
      author: 'Walt Whitman',
      coverImageUrl: 'https://covers.openlibrary.org/b/id/7222241-L.jpg',
      coverThumbnailUrl: 'https://covers.openlibrary.org/b/id/7222241-M.jpg',
      firstPublishYear: 1855,
      description: 'A landmark poetry collection celebrating nature, human body, soul, and democracy in free verse.',
      subjects: ['Poetry', 'American Literature', 'Transcendentalism'],
      iaId: 'leavesofgrass00whit',
      hasFulltext: true,
      ebookAccess: 'public',
    ),
    OpenLibraryBook(
      id: '/works/OL41059W',
      workKey: '/works/OL41059W',
      title: 'The Raven and Other Poems',
      author: 'Edgar Allan Poe',
      coverImageUrl: 'https://covers.openlibrary.org/b/id/8235122-L.jpg',
      coverThumbnailUrl: 'https://covers.openlibrary.org/b/id/8235122-M.jpg',
      firstPublishYear: 1845,
      description: 'Atmospheric and rhythmic verses on loss, grief, beauty, and longing.',
      subjects: ['Poetry', 'Gothic', 'Melancholy', 'American Poetry'],
      iaId: 'theravenandother00poee',
      hasFulltext: true,
      ebookAccess: 'public',
    ),
  ],
  'history': [
    OpenLibraryBook(
      id: '/works/OL158434W',
      workKey: '/works/OL158434W',
      title: 'The History of the Peloponnesian War',
      author: 'Thucydides',
      coverImageUrl: 'https://covers.openlibrary.org/b/id/8231998-L.jpg',
      coverThumbnailUrl: 'https://covers.openlibrary.org/b/id/8231998-M.jpg',
      firstPublishYear: -431,
      description: 'Foundational historical analysis of politics, power dynamics, and human nature during the war between Athens and Sparta.',
      subjects: ['History', 'Ancient Greece', 'Military history', 'Classics'],
      iaId: 'historypeloponn00thuc',
      hasFulltext: true,
      ebookAccess: 'public',
    ),
    OpenLibraryBook(
      id: '/works/OL2159013W',
      workKey: '/works/OL2159013W',
      title: 'The Decline and Fall of the Roman Empire',
      author: 'Edward Gibbon',
      coverImageUrl: 'https://covers.openlibrary.org/b/id/7222245-L.jpg',
      coverThumbnailUrl: 'https://covers.openlibrary.org/b/id/7222245-M.jpg',
      firstPublishYear: 1776,
      description: 'A monumental historical narrative tracing Western civilization from the Roman apex to the fall of Constantinople.',
      subjects: ['Roman Empire', 'History', 'Civilization', 'Classics'],
      iaId: 'historyofdecline01gibb',
      hasFulltext: true,
      ebookAccess: 'public',
    ),
  ],
  'science': [
    OpenLibraryBook(
      id: '/works/OL73434W',
      workKey: '/works/OL73434W',
      title: 'On the Origin of Species',
      author: 'Charles Darwin',
      coverImageUrl: 'https://covers.openlibrary.org/b/id/8231999-L.jpg',
      coverThumbnailUrl: 'https://covers.openlibrary.org/b/id/8231999-M.jpg',
      firstPublishYear: 1859,
      description: 'The seminal work introducing the theory of evolution by natural selection.',
      subjects: ['Science', 'Biology', 'Evolution', 'Natural History'],
      iaId: 'originofspecies00darw',
      hasFulltext: true,
      ebookAccess: 'public',
    ),
    OpenLibraryBook(
      id: '/works/OL529944W',
      workKey: '/works/OL529944W',
      title: 'Relativity: The Special and the General Theory',
      author: 'Albert Einstein',
      coverImageUrl: 'https://covers.openlibrary.org/b/id/7222247-L.jpg',
      coverThumbnailUrl: 'https://covers.openlibrary.org/b/id/7222247-M.jpg',
      firstPublishYear: 1916,
      description: 'A clear introduction to the fundamental concepts of spacetime and gravitational physics.',
      subjects: ['Physics', 'Science', 'Relativity', 'Cosmology'],
      iaId: 'relativitythespe00einsrich',
      hasFulltext: true,
      ebookAccess: 'public',
    ),
  ],
  'self-help': [
    OpenLibraryBook(
      id: '/works/OL3149814W',
      workKey: '/works/OL3149814W',
      title: 'As a Man Thinketh',
      author: 'James Allen',
      coverImageUrl: 'https://covers.openlibrary.org/b/id/7222248-L.jpg',
      coverThumbnailUrl: 'https://covers.openlibrary.org/b/id/7222248-M.jpg',
      firstPublishYear: 1903,
      description: 'An influential classic on the power of thoughts to shape character, circumstances, and destiny.',
      subjects: ['Habits', 'Self-improvement', 'Mindset', 'Productivity'],
      iaId: 'asmanthinketh00alle',
      hasFulltext: true,
      ebookAccess: 'public',
    ),
    OpenLibraryBook(
      id: '/works/OL14860361W',
      workKey: '/works/OL14860361W',
      title: 'The Art of War',
      author: 'Sun Tzu',
      coverImageUrl: 'https://covers.openlibrary.org/b/id/8235125-L.jpg',
      coverThumbnailUrl: 'https://covers.openlibrary.org/b/id/8235125-M.jpg',
      firstPublishYear: -500,
      description: 'Timeless military and strategic philosophy applicable to leadership, resolution, and personal discipline.',
      subjects: ['Strategy', 'Leadership', 'Discipline', 'Classics'],
      iaId: 'artofwar00sunt',
      hasFulltext: true,
      ebookAccess: 'public',
    ),
  ],
  'psychology': [
    OpenLibraryBook(
      id: '/works/OL102713W',
      workKey: '/works/OL102713W',
      title: 'The Interpretation of Dreams',
      author: 'Sigmund Freud',
      coverImageUrl: 'https://covers.openlibrary.org/b/id/7222249-L.jpg',
      coverThumbnailUrl: 'https://covers.openlibrary.org/b/id/7222249-M.jpg',
      firstPublishYear: 1899,
      description: 'Freud introduces his psychoanalytic theory of the unconscious mind through dream analysis.',
      subjects: ['Psychology', 'Psychoanalysis', 'Mind', 'Dreams'],
      iaId: 'interpretationof00freu',
      hasFulltext: true,
      ebookAccess: 'public',
    ),
  ],
  'science_fiction': [
    OpenLibraryBook(
      id: '/works/OL52267W',
      workKey: '/works/OL52267W',
      title: 'The Time Machine',
      author: 'H.G. Wells',
      coverImageUrl: 'https://covers.openlibrary.org/b/id/8235126-L.jpg',
      coverThumbnailUrl: 'https://covers.openlibrary.org/b/id/8235126-M.jpg',
      firstPublishYear: 1895,
      description: 'The pioneering science fiction novella chronicling a Victorian scientist traveling to the year 802,701 AD.',
      subjects: ['Science Fiction', 'Time Travel', 'Dystopia', 'Classics'],
      iaId: 'timemachine00well',
      hasFulltext: true,
      ebookAccess: 'public',
    ),
    OpenLibraryBook(
      id: '/works/OL102714W',
      workKey: '/works/OL102714W',
      title: 'Twenty Thousand Leagues Under the Sea',
      author: 'Jules Verne',
      coverImageUrl: 'https://covers.openlibrary.org/b/id/7222250-L.jpg',
      coverThumbnailUrl: 'https://covers.openlibrary.org/b/id/7222250-M.jpg',
      firstPublishYear: 1870,
      description: 'Captain Nemo and the Nautilus take readers on an astonishing journey through undersea wonders.',
      subjects: ['Adventure', 'Science Fiction', 'Ocean', 'Classics'],
      iaId: 'twentthousandle00vern',
      hasFulltext: true,
      ebookAccess: 'public',
    ),
  ],
  'mystery': [
    OpenLibraryBook(
      id: '/works/OL262424W',
      workKey: '/works/OL262424W',
      title: 'The Adventures of Sherlock Holmes',
      author: 'Arthur Conan Doyle',
      coverImageUrl: 'https://covers.openlibrary.org/b/id/8235127-L.jpg',
      coverThumbnailUrl: 'https://covers.openlibrary.org/b/id/8235127-M.jpg',
      firstPublishYear: 1892,
      description: 'Twelve classic detective cases solved by the extraordinary intellect and observation of Sherlock Holmes.',
      subjects: ['Mystery', 'Detective', 'Crime Fiction', 'Classics'],
      iaId: 'adventuresofsher00doyl',
      hasFulltext: true,
      ebookAccess: 'public',
    ),
  ],
  'biography': [
    OpenLibraryBook(
      id: '/works/OL102712W',
      workKey: '/works/OL102712W',
      title: 'The Autobiography of Benjamin Franklin',
      author: 'Benjamin Franklin',
      coverImageUrl: 'https://covers.openlibrary.org/b/id/7222251-L.jpg',
      coverThumbnailUrl: 'https://covers.openlibrary.org/b/id/7222251-M.jpg',
      firstPublishYear: 1791,
      description: 'Franklin reflects on printer life, civic duty, self-discipline, and scientific experiments in colonial America.',
      subjects: ['Biography', 'History', 'Self-improvement', 'American History'],
      iaId: 'autobiographyofb00fran',
      hasFulltext: true,
      ebookAccess: 'public',
    ),
  ],
};
