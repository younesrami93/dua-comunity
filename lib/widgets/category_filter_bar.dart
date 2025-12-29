import 'package:dua_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/category.dart';
import '../theme/app_colors.dart';

class CategoryFilterBar extends StatefulWidget {
  final int? selectedCategoryId;
  final Function(int?) onCategorySelected;

  const CategoryFilterBar({
    super.key,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  State<CategoryFilterBar> createState() => _CategoryFilterBarState();
}

class _CategoryFilterBarState extends State<CategoryFilterBar> {
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await ApiService().getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Error loading categories: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 50,
        child: Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary))),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context); // ✅ Theme Access

    // Add "All" option at the beginning with localized name
    final allCategories = [
      Category(id: -1, name: l10n.allCategories, slug: "all"),
      ..._categories
    ];

    return Container(
      height: 60,
      color: theme.scaffoldBackgroundColor, // ✅ Dynamic Background
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: allCategories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = allCategories[index];
          final isSelected =
              (widget.selectedCategoryId == null && category.id == -1) ||
                  (widget.selectedCategoryId == category.id);

          return _buildCategoryPill(category, isSelected);
        },
      ),
    );
  }

  Widget _buildCategoryPill(Category category, bool isSelected) {
    // ✅ Dynamic Colors
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final unselectedBg = isDark ? AppColors.surface : AppColors.surfaceLight;
    final unselectedBorder = isDark ? AppColors.border : AppColors.borderLight;
    final unselectedText = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;

    return GestureDetector(
      onTap: () {
        if (category.id == -1) {
          widget.onCategorySelected(null);
        } else {
          widget.onCategorySelected(category.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : unselectedBg, // ✅ Dynamic
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : unselectedBorder, // ✅ Dynamic
          ),
        ),
        child: Center(
          child: Text(
            Category.getLocalizedName(context, category),
            style: TextStyle(
              color: isSelected ? Colors.white : unselectedText, // ✅ Dynamic
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}