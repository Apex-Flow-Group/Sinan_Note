// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

class MsgDebug {
  static void show(BuildContext context, String title, dynamic value, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final Color color = isSuccess ? Colors.green.shade800 : Colors.red.shade800;
    final IconData icon = isSuccess ? Icons.check_circle : Icons.error_outline;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    "$value",
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
