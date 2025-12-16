// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/security_gate.dart';

class LockScreen extends StatelessWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SecurityController();
    
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) SystemNavigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => SystemNavigator.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Sinan Note is Locked',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  return ElevatedButton.icon(
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Unlock'),
                    onPressed: controller.isAuthenticating
                        ? null
                        : controller.requestUnlock,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
