import 'package:flutter/material.dart';

class ExploreCategoryConfig {
  final String id;
  final String name;
  final String subjectSlug;
  final String shelfTitle;
  final String tagline;
  final IconData icon;
  final String badgeLabel;

  const ExploreCategoryConfig({
    required this.id,
    required this.name,
    required this.subjectSlug,
    required this.shelfTitle,
    required this.tagline,
    required this.icon,
    required this.badgeLabel,
  });
}

const List<ExploreCategoryConfig> kExploreCategories = [
  ExploreCategoryConfig(
    id: 'philosophy',
    name: 'Philosophy',
    subjectSlug: 'philosophy',
    shelfTitle: 'Philosophy & Stoic Wisdom',
    tagline: 'Stoicism, existential ethics, ancient dialogues, and timeless questions on the good life.',
    icon: Icons.explore_outlined,
    badgeLabel: 'Deep Thought',
  ),
  ExploreCategoryConfig(
    id: 'psychology',
    name: 'Psychology',
    subjectSlug: 'psychology',
    shelfTitle: 'Psychology & Cognitive Science',
    tagline: 'Mental models, behavioral economics, subconscious impulses, and emotional clarity.',
    icon: Icons.psychology_outlined,
    badgeLabel: 'Mind & Behavior',
  ),
  ExploreCategoryConfig(
    id: 'habits',
    name: 'Habits & Focus',
    subjectSlug: 'self-help',
    shelfTitle: 'Habits, Focus & High Performance',
    tagline: 'Deliberate practice, atomic compounding, deep work rituals, and creative flow.',
    icon: Icons.trending_up_rounded,
    badgeLabel: 'Productivity',
  ),
  ExploreCategoryConfig(
    id: 'fiction',
    name: 'Fiction',
    subjectSlug: 'fiction',
    shelfTitle: 'Masterpiece Fiction',
    tagline: 'Enduring literary monuments, human pathos, sublime storytelling, and classic prose.',
    icon: Icons.auto_stories_rounded,
    badgeLabel: 'Literary Art',
  ),
  ExploreCategoryConfig(
    id: 'scifi',
    name: 'Sci-Fi',
    subjectSlug: 'science_fiction',
    shelfTitle: 'Sci-Fi & Speculative Futures',
    tagline: 'Far-flung galaxies, artificial intelligences, metaphysical epics, and mythic sagas.',
    icon: Icons.rocket_launch_outlined,
    badgeLabel: 'Speculative',
  ),
  ExploreCategoryConfig(
    id: 'history',
    name: 'History',
    subjectSlug: 'history',
    shelfTitle: 'History & Civilizations',
    tagline: 'Epochal revolutions, ancient empires, societal origins, and lessons of the past.',
    icon: Icons.account_balance_outlined,
    badgeLabel: 'World Chronicles',
  ),
  ExploreCategoryConfig(
    id: 'biography',
    name: 'Biography',
    subjectSlug: 'biography',
    shelfTitle: 'Biography & Visionary Lives',
    tagline: 'Intimate portraits of world-shaping inventors, philosophers, leaders, and artists.',
    icon: Icons.person_outline_rounded,
    badgeLabel: 'Remarkable Lives',
  ),
  ExploreCategoryConfig(
    id: 'business',
    name: 'Business',
    subjectSlug: 'business',
    shelfTitle: 'Business, Strategy & Economics',
    tagline: 'Zero to one innovation, market dynamics, asymmetric upside, and timeless strategy.',
    icon: Icons.work_outline_rounded,
    badgeLabel: 'Enterprise',
  ),
  ExploreCategoryConfig(
    id: 'science',
    name: 'Science',
    subjectSlug: 'science',
    shelfTitle: 'Science & The Living Universe',
    tagline: 'Astrophysics, quantum foundations, evolutionary biology, and empirical wonder.',
    icon: Icons.science_outlined,
    badgeLabel: 'Cosmos & Discovery',
  ),
  ExploreCategoryConfig(
    id: 'art',
    name: 'Art',
    subjectSlug: 'art',
    shelfTitle: 'Art, Design & Visual Culture',
    tagline: 'The creative act, aesthetic philosophy, architecture, and seeing the world afresh.',
    icon: Icons.palette_outlined,
    badgeLabel: 'Aesthetics',
  ),
  ExploreCategoryConfig(
    id: 'poetry',
    name: 'Poetry',
    subjectSlug: 'poetry',
    shelfTitle: 'Poetry & Lyric Resonance',
    tagline: 'Distilled verse, rhythmic cadence, vulnerability, and beauty between the lines.',
    icon: Icons.edit_note_rounded,
    badgeLabel: 'Verse',
  ),
  ExploreCategoryConfig(
    id: 'mystery',
    name: 'Mystery',
    subjectSlug: 'mystery',
    shelfTitle: 'Mystery, Noir & Suspense',
    tagline: 'Twisting psychological puzzles, chilling investigations, and detective classics.',
    icon: Icons.security_outlined,
    badgeLabel: 'Intrigue',
  ),
];
