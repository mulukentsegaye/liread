import 'package:flutter/material.dart';

// Domain models for the Reader Profile ("Your corner") feature.

enum ShelfStatus { reading, finished, wantToRead }

class ShelfBook {
  final String id;
  final String title;
  final String author;
  final ShelfStatus status;
  final Color coverColor;
  final Color textColor;

  const ShelfBook({
    required this.id,
    required this.title,
    required this.author,
    required this.status,
    required this.coverColor,
    required this.textColor,
  });

  String get statusLabel {
    switch (status) {
      case ShelfStatus.reading:
        return 'Reading';
      case ShelfStatus.finished:
        return 'Finished';
      case ShelfStatus.wantToRead:
        return 'Want to read';
    }
  }
}

class ReaderProfile {
  final String name;
  final String handle;
  final String bio;
  final int booksRead;
  final int followers;
  final int following;
  final int savedPassagesCount;
  final int readingCirclesCount;

  const ReaderProfile({
    required this.name,
    required this.handle,
    required this.bio,
    required this.booksRead,
    required this.followers,
    required this.following,
    required this.savedPassagesCount,
    required this.readingCirclesCount,
  });

  ReaderProfile copyWith({
    String? name,
    String? handle,
    String? bio,
  }) {
    return ReaderProfile(
      name: name ?? this.name,
      handle: handle ?? this.handle,
      bio: bio ?? this.bio,
      booksRead: booksRead,
      followers: followers,
      following: following,
      savedPassagesCount: savedPassagesCount,
      readingCirclesCount: readingCirclesCount,
    );
  }
}
