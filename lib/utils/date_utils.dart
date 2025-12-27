import 'package:dua_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
// ✅ Import generated localizations

class DateFormatter {
  // ✅ Added BuildContext context
  static String timeAgo(BuildContext context, String? dateString) {
    if (dateString == null) return '';

    // 1. Parse the string
    DateTime date = DateTime.parse(dateString);

    // 2. Convert to Local Time
    date = date.toLocal();

    final now = DateTime.now();
    final difference = now.difference(date);

    // ✅ Access Localization
    final l10n = AppLocalizations.of(context)!;

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return l10n.timeAgoYears(years);
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return l10n.timeAgoMonths(months);
    } else if (difference.inDays > 0) {
      return l10n.timeAgoDays(difference.inDays);
    } else if (difference.inHours > 0) {
      return l10n.timeAgoHours(difference.inHours);
    } else if (difference.inMinutes > 0) {
      return l10n.timeAgoMinutes(difference.inMinutes);
    } else {
      return l10n.justNow;
    }
  }
}