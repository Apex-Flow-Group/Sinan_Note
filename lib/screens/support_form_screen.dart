// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/l10n_migration_helper.dart';
import '../widgets/apex_snackbar.dart';
import '../services/device_info_service.dart';

class SupportFormScreen extends StatefulWidget {
  const SupportFormScreen({super.key});

  @override
  State<SupportFormScreen> createState() => _SupportFormScreenState();
}

class _SupportFormScreenState extends State<SupportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;
  bool _privacyAccepted = false;
  bool _includeDeviceInfo = true;
  static const String _appEmail = 'contact.apex.flow@gmail.com';

  @override
  void initState() {
    super.initState();
    _loadPrivacyConsent();
  }

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

    try {
      String deviceInfoText = '';
      if (_includeDeviceInfo) {
        final info = await DeviceInfoService().getDeviceInfo();
        deviceInfoText = '\n---\nDevice: ${info['device']}\nOS: ${info['os']}\nBuild: ${info['build']}';
      }

      final name = _nameController.text;
      final subject = _subjectController.text;
      final category = _selectedCategory ?? 'Other';

      final body = 'Name: $name\nCategory: $category\n\nMessage:\n${_bodyController.text}$deviceInfoText';

      final String encodedSubject = Uri.encodeComponent('[Sinan Note Support] $subject');
      final String encodedBody = Uri.encodeComponent(body);
      final Uri emailUri = Uri.parse('mailto:$_appEmail?subject=$encodedSubject&body=$encodedBody');

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
        if (mounted) {
          _clearForm();
          ApexSnackBar.show(
            context,
            context.l10n.transferSuccess,
            type: SnackBarType.success,
          );
        }
      } else {
        throw 'No email app found on device';
      }
    } catch (e) {
      if (mounted) {
        ApexSnackBar.show(
          context,
          'Error: $e',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _subjectController.clear();
    _bodyController.clear();
    _selectedCategory = null;
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('سياسة الاستخدام والخصوصية'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogSection(
                'الشروط',
                'بإرسالك هذه الرسالة، أنت توافق على:\n• مشاركة بيانات جهازك\n• استخدام بياناتك لتحسين الدعم الفني\n• الامتثال لسياسة الخصوصية الخاصة بنا',
              ),
              const SizedBox(height: 16),
              _buildDialogSection(
                'البيانات المشاركة',
                'سيتم إرسال:\n• اسمك\n• فئة المشكلة\n• نص رسالتك\n• معلومات الجهاز (اختياري):\n  - نموذج الجهاز\n  - إصدار نظام التشغيل\n  - رقم البناء',
              ),
              const SizedBox(height: 16),
              _buildDialogSection(
                'السبب',
                'نستخدم هذه البيانات لـ:\n• تشخيص المشاكل التقنية\n• تحسين جودة التطبيق\n• تقديم دعم أفضل لك',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('فهمت'),
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
    final l10n = context.l10n;
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.appDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _nameController,
                label: l10n.title,
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.fillAllFields;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildDropdown(
                label: l10n.noteType,
                value: _selectedCategory,
                items: categories,
                onChanged: (value) => setState(() => _selectedCategory = value),
                validator: (value) {
                  if (value == null) {
                    return l10n.fillAllFields;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _subjectController,
                label: l10n.title,
                icon: Icons.subject,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.fillAllFields;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _bodyController,
                label: l10n.writeNote,
                icon: Icons.description,
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.fillAllFields;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _includeDeviceInfo,
                onChanged: (val) => setState(() => _includeDeviceInfo = val),
                title: Text(l10n.attachDeviceInfo),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.helpsDiagnose),
                    const SizedBox(height: 4),
                    Text(
                      l10n.canRemoveFromEmail,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الخصوصية والبيانات',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'نحن نحترم خصوصيتك. سيتم استخدام بياناتك فقط لتحسين الدعم الفني.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _showPrivacyDialog,
                    child: Text(
                      'اقرأ سياسة الاستخدام',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _privacyAccepted,
                    onChanged: (val) {
                      if (val != null) _savePrivacyConsent(val);
                    },
                    title: const Text('أوافق على سياسة الاستخدام'),
                    activeColor: colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: (_isLoading || !_privacyAccepted) ? null : _submitForm,
                  icon: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    _isLoading ? l10n.autoSaved : l10n.send,
                  ),
                ),
              ),
            ],
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

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.category),
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
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
