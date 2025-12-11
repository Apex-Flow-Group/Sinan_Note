// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/flavor_config.dart';
import '../services/device_info_service.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '...';
  Map<String, String> _deviceInfo = {};

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final deviceInfo = await DeviceInfoService().getDeviceInfo();
      if (mounted) {
        setState(() {
          _version = 'v${info.version}';
          _deviceInfo = deviceInfo;
        });
      }
    } catch (e) {
      // Failed to load info
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حول التطبيق')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Info
            Center(
              child: Column(
                children: [
                  const Icon(Icons.note_rounded, size: 80, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text(
                    'Sinan Note',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _version,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'تطبيق ملاحظات ذكي واحترافي',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  if (_deviceInfo.isNotEmpty) ...[const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow('الجهاز', _deviceInfo['device'] ?? 'Unknown'),
                          _buildInfoRow('النظام', _deviceInfo['os'] ?? 'Unknown'),
                          _buildInfoRow('البناء', _deviceInfo['build'] ?? 'Unknown'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Links Section
            _buildSection('الروابط المهمة', [
              _buildLink('سياسة الخصوصية', 'https://apexflow.dev/privacy'),
              _buildLink('شروط الخدمة', 'https://apexflow.dev/terms'),
              _buildLink('التراخيص', null, onTap: _showLicenses),
            ]),
            const SizedBox(height: 24),

            // Legal Section
            _buildSection('المعلومات القانونية', [
              _buildLegalText(
                'إخلاء المسؤولية',
                'هذا التطبيق يُقدم "كما هو" بدون أي ضمانات. Apex Flow Group غير مسؤولة عن أي خسائر أو أضرار ناجمة عن استخدام التطبيق.',
              ),
              _buildLegalText(
                'حقوق النشر',
                '© 2025 Apex Flow Group. جميع الحقوق محفوظة.',
              ),
            ]),
            const SizedBox(height: 24),

            // Credits Section
            _buildSection('المكتبات المستخدمة', [
              _buildCredit('Flutter', 'إطار عمل من Google'),
              _buildCredit('Dart', 'لغة البرمجة'),
              _buildCredit('Provider', 'إدارة الحالة'),
              _buildCredit('Sqflite', 'قاعدة البيانات المحلية'),
            ]),
            const SizedBox(height: 24),

            // Flavor Info
            if (!FlavorConfig.hasTransferFeature)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'ميزة المشاركة عبر WiFi متاحة فقط في نسخة F-Droid',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),

            // Footer
            Center(
              child: Column(
                children: [
                  Text(
                    'صُنع بـ ❤️ في العالم العربي',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'contact.apex.flow@gmail.com',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildLink(String title, String? url, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: onTap ?? () => url != null ? _launchUrl(url) : null,
        child: Row(
          children: [
            const Icon(Icons.link, size: 18, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const Icon(Icons.arrow_outward, size: 16, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalText(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredit(String name, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLicenses() {
    showLicensePage(
      context: context,
      applicationName: 'Sinan Note',
      applicationVersion: _version,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
