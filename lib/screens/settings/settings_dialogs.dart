// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../../controllers/settings/settings_provider.dart';

class SettingsDialogs {
  static void showLanguageDialog(
      BuildContext context, SettingsProvider settings, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.language),
        children: [
          SimpleDialogOption(
            onPressed: () {
              settings.setLanguage('system');
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Icon(
                  settings.languageCode == 'system' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Text(l10n.system),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              settings.setLanguage('ar');
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Icon(
                  settings.languageCode == 'ar' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Text(l10n.arabic),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              settings.setLanguage('en');
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Icon(
                  settings.languageCode == 'en' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Text(l10n.english),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void showThemeDialog(BuildContext context, SettingsProvider settings) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.chooseTheme),
        children: [
          SimpleDialogOption(
            onPressed: () {
              settings.setThemeMode(ThemeMode.system);
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Icon(
                  settings.themeMode == ThemeMode.system ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Text(l10n.systemTheme),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              settings.setThemeMode(ThemeMode.light);
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Icon(
                  settings.themeMode == ThemeMode.light ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Text(l10n.lightTheme),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              settings.setThemeMode(ThemeMode.dark);
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Icon(
                  settings.themeMode == ThemeMode.dark ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Text(l10n.darkTheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void showSwipeActionDialog(BuildContext context, SettingsProvider settings,
      bool isRight, String lang) {
    final l10n = AppLocalizations.of(context)!;
    final currentValue = isRight ? settings.swipeRightAction : settings.swipeLeftAction;
    
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(isRight ? l10n.swipeRight : l10n.swipeLeft),
        children: [
          SimpleDialogOption(
            onPressed: () {
              if (isRight) {
                settings.setSwipeRightAction('delete');
              } else {
                settings.setSwipeLeftAction('delete');
              }
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Icon(
                  currentValue == 'delete' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Text(l10n.delete),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              if (isRight) {
                settings.setSwipeRightAction('archive');
              } else {
                settings.setSwipeLeftAction('archive');
              }
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Icon(
                  currentValue == 'archive' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Text(l10n.archive),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              if (isRight) {
                settings.setSwipeRightAction('share');
              } else {
                settings.setSwipeLeftAction('share');
              }
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Icon(
                  currentValue == 'share' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Text(l10n.share),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> showLockDelayDialog(
      BuildContext context, SettingsProvider settings, AppLocalizations l10n) async {
    final delays = [
      {'seconds': 30, 'label': l10n.seconds30},
      {'seconds': 120, 'label': l10n.minutes2},
      {'seconds': 180, 'label': l10n.minutes3},
      {'seconds': 300, 'label': l10n.minutes5},
    ];

    await showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.selectLockDelay),
        children: delays.map((delay) {
          return SimpleDialogOption(
            onPressed: () async {
              await settings.setLockDelaySeconds(delay['seconds'] as int);
              await settings.setLockDelayEnabled(true);
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Icon(
                  settings.lockDelaySeconds == delay['seconds'] ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Text(delay['label'] as String),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}