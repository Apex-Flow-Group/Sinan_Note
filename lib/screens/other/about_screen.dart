// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '...';

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = 'v${info.version}';
        });
      }
    } catch (e) {
      // Failed to load info
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Failed to launch URL
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutApp)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Info
                Center(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          width: 100,
                          height: 100,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.note_rounded,
                                size: 80, color: Colors.blue);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sinan Note | سنان نوت',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _version,
                        style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified,
                                size: 14, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              l10n.officialVersion,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isArabic ? l10n.appTaglineAr : l10n.appTagline,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isArabic ? l10n.appTagline : l10n.appTaglineAr,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Links Section
                _buildSection(l10n.importantLinks, [
                  _buildLink(
                    l10n.appPageGooglePlay,
                    'https://play.google.com/store/apps/details?id=com.apexflow.sinan_note',
                  ),
                  _buildLink(
                    l10n.privacyPolicy,
                    isArabic
                        ? 'https://docs.google.com/document/d/e/2PACX-1vRVJmMZMx5-mzCV2tqLCz6Nx9usUCH1KHxEHeopj5XTxmGV2CeSFg-TbqEcLtfZNarZ5kHJPlG7DsQg/pub'
                        : 'https://docs.google.com/document/d/e/2PACX-1vSteJ2fwHp0nBT8vpUHAT1B0OOyRSlkfpwJxW2bLn17fy_9lTKzwOHLmZ4SRljtLxgtXluvkp3qAzNV/pub',
                  ),
                  _buildLink(
                    l10n.termsOfService,
                    isArabic
                        ? 'https://docs.google.com/document/d/e/2PACX-1vTWx4FoSMwyeNKLiwll5oJnjvOW10vWT-YH9qrA3TaCkCva62zfwUvP-__Ztys83nBQEaYs8d8JZPZ5/pub'
                        : 'https://docs.google.com/document/d/e/2PACX-1vTkHjTUla85oqqHOXcN9dxjiC5tkJ-Y-vPd9yUfJIQIS5xWtftxjvio4fFKnedHdX5lHGWEV7ZlsL9z/pub',
                  ),
                  _buildLink(l10n.licenses, null, onTap: _showLicenses),
                ]),
                const SizedBox(height: 24),

                // Legal Section
                _buildSection(l10n.legalInfo, [
                  _buildLegalText(
                    l10n.copyright,
                    l10n.copyrightText,
                  ),
                  _buildLegalText(
                    l10n.disclaimerTitle,
                    l10n.disclaimerText,
                  ),
                  _buildLegalText(
                    l10n.officialVersionTitle,
                    l10n.officialVersionText,
                  ),
                ]),
                const SizedBox(height: 24),

                // Credits Section
                _buildSection(l10n.librariesUsed, [
                  _buildCredit('Flutter', l10n.flutterFramework),
                  _buildCredit('Dart', l10n.dartLanguage),
                  _buildCredit('Provider', l10n.providerStateManagement),
                  _buildCredit('Sqflite', l10n.sqfliteDatabase),
                ]),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    border:
                        Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.green, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.officialGooglePlay,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Footer
                Center(
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.madeWithLove,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.favorite,
                              size: 14, color: Colors.red[400]),
                          const SizedBox(width: 4),
                          Text(
                            l10n.inArabWorld,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.contactEmail,
                        style: const TextStyle(
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
}
