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
        SnackBar(content: Text(l10n.selectReasonError)), // ✅ "Please select a reason"
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
            content: Text(l10n.reportSubmittedMessage), // ✅ "Report submitted..."
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.reportFailedMessage)), // ✅ "Failed to submit..."
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Access Localization
    final l10n = AppLocalizations.of(context)!;

    // ✅ Map: Key (Backend) -> Value (Localized Display)
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
            l10n.reportTitle, // ✅ "Report Content"
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // Reason Dropdown
          Text(
            l10n.whyReportingLabel, // ✅ "Why are you reporting this?"
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedReason,
                hint: Text(l10n.selectReasonHint, style: TextStyle(color: AppColors.textSecondary)), // ✅ "Select a reason"
                isExpanded: true,
                dropdownColor: AppColors.surface,
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                items: reportReasons.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key, // Store English Key (e.g., "Spam")
                    child: Text(
                      entry.value,    // Show Localized Value (e.g., "سبام")
                      style: const TextStyle(color: AppColors.textPrimary),
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
                  l10n.additionalDetailsHint, // ✅ "Additional Details (Optional)"
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: TextField(
                    controller: _detailsController,
                    maxLines: 5,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: l10n.additionalDetailsHint,
                      hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
                      filled: true,
                      fillColor: AppColors.backgroundDark,
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
              onPressed: _isSubmitting ? null : () => _submitReport(l10n), // Pass l10n
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(l10n.submitReportButton, // ✅ "Submit Report"
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