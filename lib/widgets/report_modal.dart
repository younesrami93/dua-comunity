import 'package:dua_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
// ✅ Import generated localizations
import '../api/api_service.dart';
import '../theme/app_colors.dart';

class ReportModal extends StatefulWidget {
  final int postId;
  final String contentType; // 'post' or 'comment'

  const ReportModal({
    super.key,
    required this.postId,
    this.contentType = 'post',
  });

  @override
  State<ReportModal> createState() => _ReportModalState();
}

class _ReportModalState extends State<ReportModal> {
  String? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitReport(AppLocalizations l10n) async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectReasonError)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await ApiService().reportContent(
      type: widget.contentType,
      id: widget.postId,
      reason: _selectedReason!, // Sends the English Key (e.g., "Spam")
      details: _detailsController.text,
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context); // Close modal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.reportSubmittedMessage),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.reportFailedMessage)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // ✅ THEME AWARENESS
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final subTextColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surface : AppColors.surfaceLight;
    final inputColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight; // Inputs use bg color
    final borderColor = isDark ? AppColors.border : AppColors.borderLight;

    // Map: Key (Backend) -> Value (Localized Display)
    final Map<String, String> reportReasons = {
      "Spam": l10n.reasonSpam,
      "Hate Speech": l10n.reasonHateSpeech,
      "Harassment": l10n.reasonHarassment,
      "False Information": l10n.reasonFalseInfo,
      "Inappropriate Content": l10n.reasonInappropriateContent,
      "Other": l10n.reasonOther,
    };

    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            l10n.reportTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor, // ✅ Dynamic
            ),
          ),
          const SizedBox(height: 20),

          // Reason Dropdown
          Text(
            l10n.whyReportingLabel,
            style: TextStyle(color: subTextColor, fontSize: 14), // ✅ Dynamic
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: inputColor, // ✅ Dynamic
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor), // ✅ Dynamic
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedReason,
                hint: Text(l10n.selectReasonHint, style: TextStyle(color: subTextColor)), // ✅ Dynamic
                isExpanded: true,
                dropdownColor: surfaceColor, // ✅ Dynamic
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                items: reportReasons.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(
                      entry.value,
                      style: TextStyle(color: textColor), // ✅ Dynamic
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedReason = val),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Additional Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.additionalDetailsHint,
                  style: TextStyle(color: subTextColor, fontSize: 14), // ✅ Dynamic
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: TextField(
                    controller: _detailsController,
                    maxLines: 5,
                    style: TextStyle(color: textColor), // ✅ Dynamic
                    decoration: InputDecoration(
                      hintText: l10n.additionalDetailsHint,
                      hintStyle: TextStyle(color: subTextColor.withOpacity(0.5)), // ✅ Dynamic
                      filled: true,
                      fillColor: inputColor, // ✅ Dynamic
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Submit Button
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : () => _submitReport(l10n),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(l10n.submitReportButton,
                  style: const TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
          // Add spacing for keyboard
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
          ),
        ],
      ),
    );
  }
}