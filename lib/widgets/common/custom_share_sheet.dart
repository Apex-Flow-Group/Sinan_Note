import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';
import 'package:sinan_note/ui/features/share/view_models/apex_share.dart';
import 'package:sinan_note/widgets/common/unified_notification_service.dart';
import 'package:sinan_note/widgets/home/note_card_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomShareSheet {
  static void show(BuildContext context, String text,
      {String? subject,
      Note? note,
      VoidCallback? onNoteCopied,
      bool appShare = false}) {
    final strings = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                appShare ? strings.shareApp : strings.shareNoteTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                strings.chooseSharingMethod,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),

              // 4 options in one row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (!appShare)
                    _ShareOption(
                      icon: Icons.file_download_outlined,
                      label: strings.save,
                      onTap: () async {
                        try {
                          final extension =
                              note != null ? _getFileExtension(note) : 'txt';
                          final fileName = subject?.isEmpty ?? true
                              ? 'note.$extension'
                              : '${subject!.replaceAll(RegExp(r'[<>:"/\|?*]'), '_')}.$extension';
                          final bytes = Uint8List.fromList(utf8.encode(text));
                          final result = await FilePicker.platform.saveFile(
                            dialogTitle: strings.saveFileDialogTitle,
                            fileName: fileName,
                            type: FileType.any,
                            bytes: bytes,
                          );
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          if (result != null) {
                            UnifiedNotificationService().show(
                              context: context,
                              message: strings.fileSavedSuccessfully,
                              type: NotificationType.success,
                              duration: const Duration(seconds: 2),
                            );
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          UnifiedNotificationService().show(
                            context: context,
                            message: strings.fileSaveFailed,
                            type: NotificationType.error,
                          );
                        }
                      },
                    ),
                  _ShareOption(
                    icon: Icons.share_outlined,
                    label: strings.share,
                    onTap: () {
                      Navigator.pop(context);
                      Share.share(text, subject: subject);
                    },
                  ),
                  _ShareOption(
                    icon: Icons.copy_outlined,
                    label: strings.copy,
                    onTap: () async {
                      Navigator.pop(context);
                      await Clipboard.setData(ClipboardData(text: text));
                      HapticFeedback.lightImpact();
                      if (context.mounted) {
                        UnifiedNotificationService().show(
                          context: context,
                          message: strings.textCopiedToClipboard,
                          type: NotificationType.success,
                          duration: const Duration(seconds: 2),
                        );
                      }
                    },
                  ),
                  if (note != null)
                    _ShareOption(
                      icon: Icons.copy_all,
                      label: strings.duplicate,
                      onTap: () {
                        Navigator.pop(context);
                        if (onNoteCopied != null) onNoteCopied();
                      },
                    ),
                ],
              ),

              // Send via Apex Transfer — shows only if installed
              if (note != null && Platform.isAndroid) ...[
                const SizedBox(height: 16),
                FutureBuilder<bool>(
                  future: context.read<ApexShare>().isInstalled(),
                  builder: (context, snapshot) {
                    if (snapshot.data != true) return const SizedBox.shrink();
                    return _ApexSendTile(
                      onTap: () => _sendViaApex(context, note),
                      colorScheme: colorScheme,
                    );
                  },
                ),
              ],
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  static String _getFileExtension(Note note) {
    final ext = NoteCardUtils.getFileExtension(note.content, note.noteType);
    return ext.startsWith('.') ? ext.substring(1) : ext;
  }

  static void _sendViaApex(BuildContext context, Note note) async {
    Navigator.pop(context);
    try {
      await context.read<ApexShare>().send(note);
    } on PlatformException catch (e) {
      if (!context.mounted) return;
      if (e.code == 'NOT_INSTALLED') {
        // Apex removed since last check — open Play Store
        final storeUri = Uri.parse(context.read<ApexShare>().storeUrl);
        await launchUrl(storeUri, mode: LaunchMode.externalApplication);
      } else {
        UnifiedNotificationService().show(
          context: context,
          message: AppLocalizations.of(context)!.apexSendFailed,
          type: NotificationType.error,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      UnifiedNotificationService().show(
        context: context,
        message: AppLocalizations.of(context)!.apexSendFailed,
        type: NotificationType.error,
      );
    }
  }
}

class _ApexSendTile extends StatelessWidget {
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _ApexSendTile({
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.send_rounded,
                    color: colorScheme.onPrimary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.sendViaApexTransfer,
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.sendViaApexTransferSubtitle,
                      style: context.text.labelMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareOption extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_ShareOption> createState() => _ShareOptionState();
}

class _ShareOptionState extends State<_ShareOption> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                size: 32,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
