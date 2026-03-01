// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:apex_note/widgets/home/note_card_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class CustomShareSheet {
  static void show(BuildContext context, String text, {String? subject, Note? note, VoidCallback? onNoteCopied}) {
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
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(context).padding.bottom),
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
              isArabic ? 'مشاركة الملاحظة' : 'Share Note',
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
            
            // Share options - horizontal row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ShareOption(
                  icon: Icons.file_download_outlined,
                  label: isArabic ? 'حفظ كملف' : 'Save File',
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final extension = note != null ? _getFileExtension(note) : 'txt';
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
                      
                      
                      if (result != null) {
                        if (context.mounted) {
                          final toastMsg = isArabic ? 'تم حفظ الملف بنجاح' : 'File saved successfully';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(toastMsg),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        UnifiedNotificationService().show(
                          context: context,
                          message: isArabic ? 'فشل حفظ الملف' : 'Failed to save file',
                          type: NotificationType.error,
                        );
                      }
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
                        message: isArabic ? 'تم النسخ إلى الحافظة' : strings.textCopiedToClipboard,
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
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  static String _getFileExtension(Note note) {
    final ext = NoteCardUtils.getFileExtension(note.content, note.noteType);
    // strip leading dot
    return ext.startsWith('.') ? ext.substring(1) : ext;
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
