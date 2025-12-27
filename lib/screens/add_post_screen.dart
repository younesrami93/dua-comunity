import 'package:dua_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
// ✅ Import generated localizations
import '../api/api_service.dart';
import '../models/category.dart';

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
        SnackBar(content: Text(AppLocalizations.of(context)!.postFailedMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Access Localization
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.newPostTitle), // ✅ Localized Title
        actions: [
          IconButton(
            onPressed: _isSubmitting ? null : _submitPost,
            icon: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                : const Icon(Icons.send),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Category Dropdown
            DropdownButtonFormField<Category>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: l10n.categoryLabel, // ✅ Localized Label
                border: const OutlineInputBorder(),
              ),
              items: _categories.map((Category category) {
                return DropdownMenuItem<Category>(
                  value: category,
                  child: Text(Category.getLocalizedName(context, category)), // Shows Emoji + Name (Data from API, usually no translation needed here)
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
            ),
            const SizedBox(height: 20),

            // Content Input
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: l10n.postContentHint, // ✅ Localized Hint
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            // Anonymous Switch
            SwitchListTile(
              title: Text(l10n.postAnonymously), // ✅ Localized Switch Title
              value: _isAnonymous,
              onChanged: (val) => setState(() => _isAnonymous = val),
            ),
          ],
        ),
      ),
    );
  }
}