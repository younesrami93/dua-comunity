import 'package:dua_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
// ✅ Import generated localizations

class Category {
  final int id;
  final String name; // Fallback name from backend
  final String slug;

  Category({
    required this.id,
    required this.name,
    required this.slug
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      slug: json['slug'] ?? 'unknown',
    );
  }

  // ✅ Helper to get localized name
  static String getLocalizedName(BuildContext context, Category category) {
    final l10n = AppLocalizations.of(context)!;

    // Map backend slugs to ARB keys
    switch (category.slug.toLowerCase()) {
      case 'general': return l10n.catGeneral;
      case 'ramadan': return l10n.catRamadan;
      case 'hajj-umrah': return l10n.catHajjUmrah;
      case 'health': return l10n.catHealth;
      case 'rizq-work': return l10n.catRizqWork;
      case 'marriage': return l10n.catMarriage;
      case 'family': return l10n.catFamily;
      case 'hardship': return l10n.catHardship;
      case 'guidance': return l10n.catGuidance;
      case 'gratitude': return l10n.catGratitude;

    // Handle "All" filter pill
      case 'all': return l10n.allCategories;

    // Fallback: Use the name provided by the backend (includes Emojis)
      default: return category.name;
    }
  }
}