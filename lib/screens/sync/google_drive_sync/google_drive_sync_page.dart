// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/screens/sync/google_drive_sync/google_drive_sync_controller.dart';
import 'package:apex_note/screens/sync/google_drive_sync/sync_step.dart';
import 'package:apex_note/screens/sync/google_drive_sync/widgets/sync_conflict_widget.dart';
import 'package:apex_note/screens/sync/google_drive_sync/widgets/sync_progress_widget.dart';
import 'package:apex_note/screens/sync/google_drive_sync/widgets/sync_sign_in_widget.dart';
import 'package:apex_note/screens/sync/google_drive_sync/widgets/sync_success_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GoogleDriveSyncPage extends StatelessWidget {
  const GoogleDriveSyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GoogleDriveSyncController(),
      child: const _GoogleDriveSyncPageContent(),
    );
  }
}

class _GoogleDriveSyncPageContent extends StatefulWidget {
  const _GoogleDriveSyncPageContent();

  @override
  State<_GoogleDriveSyncPageContent> createState() =>
      _GoogleDriveSyncPageContentState();
}

class _GoogleDriveSyncPageContentState
    extends State<_GoogleDriveSyncPageContent> {
  GoogleDriveSyncController? _controller;

  @override
  void initState() {
    super.initState();
    // Listen for snackbar messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller = context.read<GoogleDriveSyncController>();
      _controller?.addListener(_handleSnackBar);
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleSnackBar);
    super.dispose();
  }

  void _handleSnackBar() {
    final controller = context.read<GoogleDriveSyncController>();
    if (controller.snackBarMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.snackBarMessage!),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      controller.consumeSnackBar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = context.watch<GoogleDriveSyncController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // إلغاء العملية عند الضغط على Back
          await controller.abort();
          if (!context.mounted) return;
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.googleDriveSync),
          centerTitle: true,
        ),
        body: _buildBody(context, controller),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, GoogleDriveSyncController controller) {
    switch (controller.currentStep) {
      case SyncStep.signIn:
        return const SyncSignInWidget();

      case SyncStep.checking:
        return SyncProgressWidget(
          message: AppLocalizations.of(context)!.syncing,
        );

      case SyncStep.conflict:
        return const SyncConflictWidget();

      case SyncStep.syncing:
        return SyncProgressWidget(
          message: AppLocalizations.of(context)!.syncing,
        );

      case SyncStep.success:
        return const SyncSuccessWidget();

      case SyncStep.error:
        return _buildError(context, controller);
    }
  }

  Widget _buildError(
      BuildContext context, GoogleDriveSyncController controller) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              l10n.syncFailed,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: controller.retry,
              icon: const Icon(Icons.refresh),
              label: Text(Localizations.localeOf(context).languageCode == 'ar'
                  ? 'إعادة المحاولة'
                  : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
