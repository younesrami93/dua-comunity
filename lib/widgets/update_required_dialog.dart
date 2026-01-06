import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dua_app/main.dart'; // To access navigatorKey

/// triggers the global update dialog
void showUpdateRequiredDialog() {
  final context = navigatorKey.currentContext;

  // Prevent showing if context is missing or if a dialog is likely already open (basic check)
  if (context == null || !context.mounted) return;

  showDialog(
    context: context,
    barrierDismissible: false, // User cannot click outside to close
    builder: (BuildContext ctx) {
      return const PopScope(
        canPop: false, // Android back button won't close it
        child: UpdateRequiredDialog(),
      );
    },
  );
}

class UpdateRequiredDialog extends StatelessWidget {
  const UpdateRequiredDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        "Update Required",
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
      ),
      content: const Text(
        "A new version of the app is available. In order to continue using the app, you must update to the latest version.",
        style: TextStyle(fontSize: 16),
      ),
      actions: [
        FilledButton(
          onPressed: _launchStore,
          child: const Text("Update Now"),
        ),
      ],
    );
  }

  Future<void> _launchStore() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String packageName = packageInfo.packageName;

    // TODO: Replace with your actual Apple App ID
    const String appleAppId = "YOUR_APPLE_APP_ID";

    Uri url;

    if (Platform.isAndroid) {
      // Try opening the market protocol first
      url = Uri.parse("market://details?id=$packageName");
    } else {
      // iOS App Store
      url = Uri.parse("https://apps.apple.com/app/id$appleAppId");
    }

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Fallback for Android web link if market:// fails
        if (Platform.isAndroid) {
          url = Uri.parse("https://play.google.com/store/apps/details?id=$packageName");
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        }
      }
    } catch (e) {
      debugPrint("Could not launch store: $e");
    }
  }
}