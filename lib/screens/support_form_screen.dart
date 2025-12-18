// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/l10n_migration_helper.dart';
import '../widgets/apex_snackbar.dart';

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
    final l10n = context.l10n;

    try {
      final name = _nameController.text;
      final subject = _subjectController.text;
      final category = _selectedCategory ?? 'Other';

      final body = 'Name: $name\nCategory: $category\n\nMessage:\n${_bodyController.text}';

      final String encodedSubject = Uri.encodeComponent('[Sinan Note Support] $subject');
      final String encodedBody = Uri.encodeComponent(body);
      final Uri emailUri = Uri.parse('mailto:$_appEmail?subject=$encodedSubject&body=$encodedBody');

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
        if (mounted) {
          _clearForm();
          ApexSnackBar.show(
            context,
            l10n.supportMessageSent,
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
          '${l10n.supportMessageFailed}: $e',
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
    final l10n = context.l10n;
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
              _buildDialogSection(l10n.supportSharedData, l10n.supportSharedDataDesc),
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
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 80,
        ),
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
                label: l10n.supportCategory,
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
                label: l10n.supportSubject,
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
                label: l10n.supportMessage,
                icon: Icons.description,
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.fillAllFields;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.privacyAndData,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.privacyDescription,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _showPrivacyDialog,
                    child: Text(
                      l10n.readPrivacyPolicy,
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
                    title: Text(l10n.agreeToPolicy),
                    activeColor: colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 24),
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
      initialValue: value,
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
