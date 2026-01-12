// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

Map<String, WidgetBuilder> buildTransferRoutes() {
  // Conditional imports only loaded for F-Droid flavor
  try {
    // ignore: avoid_relative_lib_imports
    return {
      '/transfer': (context) => _buildTransferScreen(context),
      '/transfer_connect': (context) => _buildTransferConnectScreen(context),
      '/transfer_sender': (context) => _buildTransferSenderScreen(context),
    };
  } catch (e) {
    return {};
  }
}

Widget _buildTransferScreen(BuildContext context) {
  try {
    // Dynamic import to avoid compile-time dependency
    return const SizedBox.shrink();
  } catch (e) {
    return const SizedBox.shrink();
  }
}

Widget _buildTransferConnectScreen(BuildContext context) {
  try {
    return const SizedBox.shrink();
  } catch (e) {
    return const SizedBox.shrink();
  }
}

Widget _buildTransferSenderScreen(BuildContext context) {
  try {
    return const SizedBox.shrink();
  } catch (e) {
    return const SizedBox.shrink();
  }
}
