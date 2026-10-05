// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:sinan_note/domain/categories.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';

/// سبب رفض اسم تصنيف، بلغة المستخدم.
String categoryIssueText(AppLocalizations l10n, CategoryIssue issue) =>
    switch (issue) {
      CategoryIssue.empty || CategoryIssue.tooLong => l10n.categoryNameInvalid,
      CategoryIssue.duplicate => l10n.categoryNameDuplicate,
      CategoryIssue.limitReached =>
        l10n.categoryLimitReached(CategoryPolicy.maxCategories),
    };
