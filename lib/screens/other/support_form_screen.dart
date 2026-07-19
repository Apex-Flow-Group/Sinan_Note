// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/widgets/common/unified_notification_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportFormScreen extends StatefulWidget {
  const SupportFormScreen({super.key});

  @override
  State<SupportFormScreen> createState() => _SupportFormScreenState();
}

class _SupportFormScreenState extends State<SupportFormScreen> {
  static const MethodChannel _channel = MethodChannel('apex_note/email');

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;
  bool _privacyAccepted = false;
  static const String _appEmail = 'contact.apex.flow@gmail.com';

  @override
  void initState() {
    super.initState();
    _loadPrivacyConsent();
    _nameController.addListener(() => setState(() {}));
    _subjectController.addListener(() => setState(() {}));
    _bodyController.addListener(() => setState(() {}));
  }

  bool get _canSend =>
      _nameController.text.isNotEmpty &&
      _subjectController.text.isNotEmpty &&
      _bodyController.text.isNotEmpty &&
      _privacyAccepted &&
      !_isLoading;

  Future<void> _loadPrivacyConsent() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _privacyAccepted = prefs.getBool('privacy_consented') ?? false;
    });
  }

  Future<void> _savePrivacyConsent(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('privacy_consented', value);
    setState(() => _privacyAccepted = value);
  }

  Future<void> _submitFeedback() async {
    if (_canSend) await _submitForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || !_privacyAccepted) return;

    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    try {
      final name = _nameController.text;
      final subject = _subjectController.text;
      final category = _selectedCategory ?? 'Other';
      final body =
          'Name: $name\nCategory: $category\n\nMessage:\n${_bodyController.text}';

      bool launched = false;
      String? lastError;

      // Try Method 1: Native Android Intent (for Android)
      try {
        await _channel.invokeMethod('sendEmail', {
          'email': _appEmail,
          'subject': '[Sinan Note Support] $subject',
          'body': body,
        });
        launched = true;
      } catch (e) {
        lastError = e.toString();
      }

      // Try Method 2: url_launcher (fallback)
      if (!launched) {
        final Uri emailUri = Uri(
          scheme: 'mailto',
          path: _appEmail,
          queryParameters: {
            'subject': '[Sinan Note Support] $subject',
            'body': body,
          },
        );

        bool canLaunch = false;
        try {
          canLaunch = await canLaunchUrl(emailUri);
        } catch (e) {
          canLaunch = true;
        }

        if (canLaunch) {
          try {
            launched =
                await launchUrl(emailUri, mode: LaunchMode.externalApplication);
          } catch (e) {
            lastError = e.toString();
          }

          if (!launched) {
            try {
              launched =
                  await launchUrl(emailUri, mode: LaunchMode.platformDefault);
            } catch (e) {
              lastError = e.toString();
            }
          }
        }
      }

      if (!launched) {
        throw Exception(lastError ?? 'no_email_app');
      }

      if (mounted) {
        _clearForm();
        UnifiedNotificationService().show(
          context: context,
          message: l10n.supportMessageSent,
          type: NotificationType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        final err = e.toString();
        final isNoApp = err.contains('no_email_app') ||
            err.contains('channel-error') ||
            err.contains('Unable to establish') ||
            err.contains('No Activity found') ||
            err.contains('ActivityNotFoundException') ||
            err.contains('MissingPluginException');
        if (isNoApp) {
          _showNoEmailAppDialog(isAr);
        } else {
          UnifiedNotificationService().show(
            context: context,
            message: '${l10n.supportMessageFailed}: $err',
            type: NotificationType.error,
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showNoEmailAppDialog(bool isAr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.email_outlined, size: 40, color: Colors.orange),
        title: Text(isAr ? 'لا يوجد تطبيق بريد' : 'No Email App Found'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr
                  ? 'لم يتم العثور على تطبيق بريد إلكتروني على جهازك.\n\nيمكنك التواصل معنا مباشرة عبر:'
                  : 'No email app was found on your device.\n\nYou can contact us directly at:',
            ),
            const SizedBox(height: 12),
            const SelectableText(
              _appEmail,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy, size: 18),
            label: Text(isAr ? 'نسخ البريد' : 'Copy Email'),
            onPressed: () async {
              Navigator.pop(ctx);
              await Clipboard.setData(const ClipboardData(text: _appEmail));
              if (mounted) {
                UnifiedNotificationService().show(
                  context: context,
                  message: isAr ? 'تم نسخ البريد الإلكتروني' : 'Email copied',
                  type: NotificationType.success,
                );
              }
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.gotIt),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _subjectController.clear();
    _bodyController.clear();
    _selectedCategory = null;
  }

  void _showPrivacyDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.privacyUsagePolicy),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogSection(l10n.supportTerms, l10n.supportTermsDesc),
              const SizedBox(height: 16),
              _buildDialogSection(
                  l10n.supportSharedData, l10n.supportSharedDataDesc),
              const SizedBox(height: 16),
              _buildDialogSection(l10n.supportReason, l10n.supportReasonDesc),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.gotIt),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.5),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final categories = [
      l10n.feedback,
      l10n.about,
      l10n.info,
      l10n.soon,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.contactUs),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _canSend ? _submitFeedback : null,
            tooltip: l10n.send,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 8,
              right: 8,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 80,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(children: [
                        Icon(Icons.support_agent_rounded,
                            size: 28, color: colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.contactUs,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(l10n.appDescription,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.7))),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Form Card
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.edit_note_rounded,
                                size: 28, color: colorScheme.primary),
                            const SizedBox(width: 12),
                            Text(l10n.supportSubject,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          ]),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _nameController,
                            label: l10n.title,
                            icon: Icons.person,
                            validator: (v) => (v == null || v.isEmpty)
                                ? l10n.fillAllFields
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: categories.map((cat) {
                              final isSelected = _selectedCategory == cat;
                              return ChoiceChip(
                                label: Text(cat),
                                selected: isSelected,
                                showCheckmark: false,
                                onSelected: (_) =>
                                    setState(() => _selectedCategory = cat),
                                selectedColor:
                                    colorScheme.primary.withValues(alpha: 0.2),
                                labelStyle: TextStyle(
                                  color:
                                      isSelected ? colorScheme.primary : null,
                                  fontWeight:
                                      isSelected ? FontWeight.w600 : null,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.outline
                                            .withValues(alpha: 0.3),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _subjectController,
                            label: l10n.supportSubject,
                            icon: Icons.subject,
                            validator: (v) => (v == null || v.isEmpty)
                                ? l10n.fillAllFields
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _bodyController,
                            label: l10n.supportMessage,
                            icon: Icons.description,
                            maxLines: 6,
                            validator: (v) => (v == null || v.isEmpty)
                                ? l10n.fillAllFields
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Privacy Card
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.privacy_tip_outlined,
                                size: 28, color: colorScheme.primary),
                            const SizedBox(width: 12),
                            Text(l10n.privacyAndData,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          ]),
                          const SizedBox(height: 12),
                          Text(l10n.privacyDescription,
                              style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _showPrivacyDialog,
                            child: Text(l10n.readPrivacyPolicy,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.primary,
                                    decoration: TextDecoration.underline)),
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _privacyAccepted,
                            onChanged: (val) {
                              if (val != null) _savePrivacyConsent(val);
                            },
                            title: Text(l10n.agreeToPolicy),
                            activeColor: colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _canSend ? _submitFeedback : null,
                      icon: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                      colorScheme.onPrimary)))
                          : const Icon(Icons.send),
                      label: Text(_isLoading ? l10n.autoSaved : l10n.send),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }
}
