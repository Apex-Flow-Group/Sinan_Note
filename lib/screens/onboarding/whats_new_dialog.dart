// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';

import 'package:apex_note/services/storage/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class WhatsNewDialog extends StatefulWidget {
  final String version;
  const WhatsNewDialog({super.key, required this.version});

  static Future<void> show(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WhatsNewDialog(version: info.version),
    );
  }

  @override
  State<WhatsNewDialog> createState() => _WhatsNewDialogState();
}

class _WhatsNewDialogState extends State<WhatsNewDialog> {
  bool _confirmed = false;
  bool _isExporting = false;
  bool _exported = false;
  String? _exportMsg;

  Future<void> _exportNow() async {
    setState(() { _isExporting = true; _exportMsg = null; });
    try {
      final dir = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final downloadsPath = Platform.isAndroid
          ? '/storage/emulated/0/Download'
          : dir.path;
      final msg = await StorageService().exportNotesToPath(downloadsPath);
      setState(() { _exported = true; _exportMsg = msg; });
    } catch (e) {
      setState(() { _exportMsg = e.toString().replaceAll('Exception:', '').trim(); });
    } finally {
      setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      child: Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 480,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.backup_rounded, color: Colors.orange, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isArabic ? 'قبل التحديث — احفظ بياناتك' : 'Before Update — Save Your Data',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Warning box ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    isArabic
                        ? 'هذا التحديث يتضمن تغييرات في قاعدة البيانات.\nيُنصح بأخذ نسخة احتياطية من ملاحظاتك قبل المتابعة لضمان عدم فقدان أي بيانات.'
                        : 'This update includes database changes.\nIt is recommended to back up your notes before continuing to ensure no data is lost.',
                    style: TextStyle(fontSize: 13, height: 1.5, color: scheme.onSurface),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Export button ──
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isExporting ? null : _exportNow,
                    icon: _isExporting
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(_exported ? Icons.check_circle_rounded : Icons.download_rounded),
                    label: Text(
                      _isExporting
                          ? (isArabic ? 'جاري التصدير...' : 'Exporting...')
                          : _exported
                              ? (isArabic ? 'تم التصدير ✓' : 'Exported ✓')
                              : (isArabic ? 'تصدير الملاحظات إلى التنزيلات' : 'Export Notes to Downloads'),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _exported ? Colors.green : scheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                // ── Export result message ──
                if (_exportMsg != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _exportMsg!,
                    style: TextStyle(
                      fontSize: 12,
                      color: _exported ? Colors.green : scheme.error,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // ── Checkbox ──
                InkWell(
                  onTap: () => setState(() => _confirmed = !_confirmed),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _confirmed,
                        onChanged: (v) => setState(() => _confirmed = v ?? false),
                        activeColor: scheme.primary,
                      ),
                      Expanded(
                        child: Text(
                          isArabic
                              ? 'نعم، أخذت نسخة احتياطية من بياناتي'
                              : 'Yes, I have backed up my data',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Confirm button ──
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _confirmed ? () => Navigator.pop(context) : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      isArabic ? 'متابعة' : 'Continue',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
