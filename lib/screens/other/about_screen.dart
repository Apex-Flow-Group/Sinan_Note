// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '...';
  bool _isLaunching = false;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _version = 'v${info.version}');
    } catch (_) {}
  }

  static const _channel = MethodChannel('com.apexflow.app.sinan/launcher');

  Future<void> _launchUrl(String url) async {
    if (_isLaunching) return;
    setState(() => _isLaunching = true);
    try {
      await _channel.invokeMethod('launch', url);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLaunching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutApp)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            children: [
              // App Info Header Card
              Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          width: 88,
                          height: 88,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.note_rounded,
                              size: 80,
                              color: Colors.blue),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sinan Note | سنان نوت',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _version,
                        style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
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
                            Text(l10n.officialVersion,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600)),
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
                        style: TextStyle(
                            fontSize: 12,
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
              ),

              // Links Section
              _buildSection(
                context,
                l10n.importantLinks,
                Icons.link_rounded,
                [
                  _buildLinkTile(l10n.appPageGooglePlay, Icons.shop_rounded,
                      'https://play.google.com/store/apps/dev?id=5409981776310932919'),
                  _buildLinkTile(
                      l10n.sinanAiNet,
                      Icons.language_rounded,
                      isArabic
                          ? 'https://sinanai.net'
                          : 'https://sinanai.net/en'),
                  _buildLinkTile(l10n.githubRepository, Icons.code_rounded,
                      'https://github.com/Apex-Flow-Group/Sinan_Note'),
                  _buildLinkTile(
                      l10n.privacyPolicy,
                      Icons.privacy_tip_outlined,
                      isArabic
                          ? 'https://apexflow.now/ar/projects/sinan-note/privacy'
                          : 'https://apexflow.now/en/projects/sinan-note/privacy'),
                  _buildLinkTile(
                      l10n.termsOfService,
                      Icons.gavel_rounded,
                      isArabic
                          ? 'https://apexflow.now/ar/projects/sinan-note/terms'
                          : 'https://apexflow.now/en/projects/sinan-note/terms'),
                  ListTile(
                    leading: Icon(Icons.article_outlined,
                        color: colorScheme.primary),
                    title: Text(l10n.licenses),
                    trailing:
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: _showLicenses,
                  ),
                ],
              ),

              // Legal Section
              _buildSection(
                context,
                l10n.legalInfo,
                Icons.gavel_rounded,
                [
                  _buildInfoTile(l10n.copyright, l10n.copyrightText),
                  _buildInfoTile(l10n.disclaimerTitle, l10n.disclaimerText),
                  _buildInfoTile(
                      l10n.officialVersionTitle, l10n.officialVersionText),
                ],
              ),

              // Libraries Section
              _buildSection(
                context,
                l10n.librariesUsed,
                Icons.widgets_outlined,
                [
                  _buildCreditTile('Flutter', l10n.flutterFramework),
                  _buildCreditTile('Dart', l10n.dartLanguage),
                  _buildCreditTile('Provider', l10n.providerStateManagement),
                  _buildCreditTile('SQLite', l10n.localDatabase),
                ],
              ),

              // Footer
              Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l10n.madeWithLove,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.6))),
                          const SizedBox(width: 4),
                          Icon(Icons.favorite,
                              size: 14, color: Colors.red[400]),
                          const SizedBox(width: 4),
                          Text(l10n.inArabWorld,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.6))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.contactEmail,
                          style: TextStyle(
                              fontSize: 12, color: colorScheme.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon,
      List<Widget> children) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon,
                  size: 28, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildLinkTile(String title, IconData icon, String url) {
    final color = Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: Icon(Icons.arrow_outward, size: 16, color: color),
      onTap: _isLaunching ? null : () => _launchUrl(url),
    );
  }

  Widget _buildInfoTile(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Text(content,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                  height: 1.5)),
          const Divider(height: 16),
        ],
      ),
    );
  }

  Widget _buildCreditTile(String name, String description) {
    return ListTile(
      leading:
          const Icon(Icons.check_circle_outline_rounded, color: Colors.green),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(description),
    );
  }

  void _showLicenses() {
    showLicensePage(
      context: context,
      applicationName: 'Sinan Note',
      applicationVersion: _version,
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset('assets/images/app_icon.png',
            width: 64,
            height: 64,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.note_rounded, size: 64, color: Colors.blue)),
      ),
    );
  }
}
