import 'package:dua_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
// ✅ Import generated localizations
import '../api/api_service.dart';
import '../models/category.dart';
import '../theme/app_colors.dart'; // ✅ Import Colors

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _contentController = TextEditingController();
  List<Category> _categories = [];
  Category? _selectedCategory;
  bool _isLoading = true;
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // Fetch Categories on Load
  Future<void> _loadCategories() async {
    try {
      final categories = await ApiService().getCategories();
      setState(() {
        _categories = categories;
        if (categories.isNotEmpty) _selectedCategory = categories[0];
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
      setState(() => _isLoading = false);
    }
  }

  // Send Data to Backend
  Future<void> _submitPost() async {
    if (_contentController.text.isEmpty || _selectedCategory == null) return;

    setState(() => _isSubmitting = true);

    final success = await ApiService().createPost(
      _contentController.text,
      _selectedCategory!.id,
      _isAnonymous,
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.pop(context, true); // Return "true" to refresh the feed
    } else if (mounted) {
      // ✅ Localized Error Message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.postFailedMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Access Localization
    final l10n = AppLocalizations.of(context)!;

    // ✅ THEME AWARENESS
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final subTextColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final surfaceColor = isDark ? AppColors.surface : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.border : AppColors.borderLight;

    return Scaffold(
      backgroundColor: backgroundColor, // ✅ Dynamic Background
      appBar: AppBar(
        title: Text(l10n.newPostTitle,
            style: TextStyle(color: textColor)), // ✅ Dynamic Title
        iconTheme: IconThemeData(color: textColor), // ✅ Dynamic Back Button
        actions: [
          IconButton(
            onPressed: _isSubmitting ? null : _submitPost,
            icon: _isSubmitting
                ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: textColor)) // ✅ Dynamic Spinner
                : Icon(Icons.send, color: textColor), // ✅ Dynamic Icon
          )
        ],
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.primary))
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Category Dropdown
            DropdownButtonFormField<Category>(
              value: _selectedCategory,
              dropdownColor: surfaceColor, // ✅ Dynamic Dropdown Background
              style: TextStyle(color: textColor), // ✅ Dynamic Text
              decoration: InputDecoration(
                labelText: l10n.categoryLabel,
                labelStyle: TextStyle(color: subTextColor), // ✅ Dynamic Label
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: borderColor), // ✅ Dynamic Border
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                border: const OutlineInputBorder(),
              ),
              items: _categories.map((Category category) {
                return DropdownMenuItem<Category>(
                  value: category,
                  child: Text(
                    Category.getLocalizedName(context, category),
                    style: TextStyle(color: textColor), // ✅ Dynamic Item Text
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
            ),
            const SizedBox(height: 20),

            // Content Input
            TextField(
              controller: _contentController,
              maxLines: 5,
              style: TextStyle(color: textColor), // ✅ Dynamic Input Text
              decoration: InputDecoration(
                hintText: l10n.postContentHint,
                hintStyle: TextStyle(color: subTextColor), // ✅ Dynamic Hint
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: borderColor), // ✅ Dynamic Border
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            // Anonymous Switch
            SwitchListTile(
              title: Text(l10n.postAnonymously,
                  style: TextStyle(color: textColor)), // ✅ Dynamic Title
              activeColor: AppColors.primary,
              value: _isAnonymous,
              onChanged: (val) => setState(() => _isAnonymous = val),
            ),
          ],
        ),
      ),
    );
  }
}