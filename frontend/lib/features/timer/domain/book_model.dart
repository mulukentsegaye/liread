import 'package:flutter/material.dart';

/// Model representing a book in the user's library.
class ReadingBook {
  final String id;
  final String title;
  final String author;
  final Color coverColor;
  final IconData? coverIcon;
  final int totalPages;
  final int currentPage;

  const ReadingBook({
    required this.id,
    required this.title,
    required this.author,
    required this.coverColor,
    this.coverIcon,
    this.totalPages = 300,
    this.currentPage = 45,
  });

  double get progress => totalPages > 0 ? (currentPage / totalPages).clamp(0.0, 1.0) : 0.0;
}
