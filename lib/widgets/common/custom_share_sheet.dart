import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/services/unified_notification_service.dart';
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
    final isArabic = Directionality.of(context) == TextDirection.rtl;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, 20 + MediaQuery.of(context).padding.bottom),
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
              appShare
                  ? (isArabic ? 'مشاركة التطبيق' : 'Share App')
                  : (isArabic ? 'مشاركة الملاحظة' : 'Share Note'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              isArabic ? 'اختر طريقة المشاركة' : 'Choose sharing method',
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
                    label: isArabic ? 'حفظ' : 'Save',
                    onTap: () async {
                      try {
                        final extension =
                            note != null ? _getFileExtension(note) : 'txt';
                        final fileName = subject?.isEmpty ?? true
                            ? 'note.$extension'
                            : '${subject!.replaceAll(RegExp(r'[<>:"/\|?*]'), '_')}.$extension';
                        final bytes = Uint8List.fromList(utf8.encode(text));
                        final result = await FilePicker.platform.saveFile(
                          dialogTitle: isArabic ? 'حفظ الملف' : 'Save File',
                          fileName: fileName,
                          type: FileType.any,
                          bytes: bytes,
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        if (result != null) {
                          UnifiedNotificationService().show(
                            context: context,
                            message: isArabic
                                ? 'تم حفظ الملف بنجاح'
                                : 'File saved successfully',
                            type: NotificationType.success,
                            duration: const Duration(seconds: 2),
                          );
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        UnifiedNotificationService().show(
                          context: context,
                          message: isArabic
                              ? 'فشل حفظ الملف'
                              : 'Failed to save file',
                          type: NotificationType.error,
                        );
                      }
                    },
                  ),
                _ShareOption(
                  icon: Icons.share_outlined,
                  label: isArabic ? 'مشاركة' : 'Share',
                  onTap: () {
                    Navigator.pop(context);
                    Share.share(text, subject: subject);
                  },
                ),
                _ShareOption(
                  icon: Icons.copy_outlined,
                  label: isArabic ? 'نسخ' : 'Copy',
                  onTap: () async {
                    Navigator.pop(context);
                    await Clipboard.setData(ClipboardData(text: text));
                    HapticFeedback.lightImpact();
                    if (context.mounted) {
                      UnifiedNotificationService().show(
                        context: context,
                        message: isArabic
                            ? 'تم النسخ إلى الحافظة'
                            : strings.textCopiedToClipboard,
                        type: NotificationType.success,
                        duration: const Duration(seconds: 2),
                      );
                    }
                  },
                ),
                if (note != null)
                  _ShareOption(
                    icon: Icons.copy_all,
                    label: isArabic ? 'نسخة' : 'Duplicate',
                    onTap: () {
                      Navigator.pop(context);
                      if (onNoteCopied != null) onNoteCopied();
                    },
                  ),
              ],
            ),

            // Send via Apex - full width tile
            if (note != null) ...[
              const SizedBox(height: 16),
              _ApexSendTile(
                isArabic: isArabic,
                onTap: () => _sendViaApex(context, note, isArabic),
                colorScheme: colorScheme,
              ),
            ],
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  static String _getFileExtension(Note note) {
    final ext = NoteCardUtils.getFileExtension(note.content, note.noteType);
    return ext.startsWith('.') ? ext.substring(1) : ext;
  }

  static void _sendViaApex(
      BuildContext context, Note note, bool isArabic) async {
    Navigator.pop(context);
    try {
      final tmp = await getTemporaryDirectory();
      final safeTitle = (note.title.isEmpty ? 'note' : note.title)
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
          .trim();
      final filePath = '${tmp.path}/$safeTitle.sinan';

      await File(filePath).writeAsString(jsonEncode({
        'title': note.title,
        'content': note.content,
        'noteType': note.noteType,
        'colorIndex': note.colorIndex,
        'createdAt': note.createdAt.toIso8601String(),
      }));

      const apexPackage = 'com.apexflow.tools.transfer';

      // Use MethodChannel via the existing platform channel in main.dart
      // We call openApexWithFile which handles FileProvider + explicit Intent
      const channel = MethodChannel('com.apexflow.app.sinan/widget');
      try {
        await channel.invokeMethod('openApexWithFile', {'path': filePath});
        return;
      } catch (_) {
        // Apex not installed - open Play Store
      }

      if (!context.mounted) return;
      final storeUri = Uri.parse(
          'https://play.google.com/store/apps/details?id=$apexPackage');
      await launchUrl(storeUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!context.mounted) return;
      UnifiedNotificationService().show(
        context: context,
        message: isArabic ? 'فشل الإرسال عبر Apex' : 'Failed to send via Apex',
        type: NotificationType.error,
      );
    }
  }
}

class _ApexSendTile extends StatelessWidget {
  final bool isArabic;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _ApexSendTile({
    required this.isArabic,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
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
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic
                          ? 'إرسال عبر Apex Transfer'
                          : 'Send via Apex Transfer',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isArabic
                          ? 'شارك الملاحظة عبر الشبكة المحلية بدون إنترنت'
                          : 'Share note over local network without internet',
                      style: TextStyle(
                        fontSize: 12,
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
