import 'dart:io';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

extension BuildContextExt on BuildContext {
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showAlert(
    String message,
    Color color,
  ) => ScaffoldMessenger.of(this).showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(8),
      duration: const Duration(seconds: 3),
      dismissDirection: DismissDirection.horizontal,
    ),
  );

  Future<T?> showCustomBottomSheet<T>({
    required bool expanded,
    required Widget child,
    required String title,
  }) {
    return showMaterialModalBottomSheet(
      context: this,
      expand: expanded,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
      ),
      builder:
          (context) => SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.close),
                          ),
                          const SizedBox(width: 10.0),
                          Text(title, style: const TextStyle(fontSize: 16.0)),
                        ],
                      ),
                    ),
                  ),
                  Padding(padding: const EdgeInsets.all(8.0), child: child),
                ],
              ),
            ),
          ),
    );
  }

  Future<T?> showCustomDialog<T>({
    required Widget child,
    required String title,
    bool barrierDismissible = true,
  }) {
    final screenSize = MediaQuery.of(this).size;
    final isMobile = Platform.isAndroid || Platform.isIOS;

    // Calculate dialog width based on platform
    final dialogWidth =
        isMobile
            ? screenSize.width *
                0.92 // 92% of screen width for mobile
            : screenSize.width * 0.4; // 40% for desktop

    return showDialog<T>(
      context: this,
      barrierDismissible: barrierDismissible,
      builder:
          (context) => Dialog(
            elevation: 0,
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 40,
              vertical: 24,
            ),
            child: Container(
              width: dialogWidth,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 10),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 24,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
