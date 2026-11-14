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
          .timeout(const Duration(seconds: 12));

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
      debugPrint('OpenLibrary search error: $e');
    }

    return const SearchBooksResult(books: [], totalFound: 0);
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
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final docs = data['docs'] as List? ?? [];

        final books = docs
            .map((d) => OpenLibraryBook.fromDoc(d as Map<String, dynamic>))
            .toList();

        _shelfCache[cacheKey] = books;
        return books;
      }
    } catch (e) {
      debugPrint('OpenLibrary category error for $subjectSlug: $e');
    }

    return const [];
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
