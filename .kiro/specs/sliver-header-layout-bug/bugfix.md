# Bugfix Requirements Document

## Introduction

يحدث خطأ assertion في Flutter أثناء تخطيط الـ `SliverPersistentHeader` في شاشة الرئيسية (`home_screen.dart`).
الخطأ: `SliverGeometry is not valid: The "layoutExtent" exceeds the "paintExtent"` — حيث `paintExtent = 0.0` و`layoutExtent = 28.0`.

السبب الجذري: الـ delegate المستخدم (`SmoothSearchHeaderDelegate`) يُعيد `minExtent = expandedHeight = 80.0` دائماً، لكن عندما يكون الـ header من نوع `floating` ومخفياً تماماً أثناء التمرير، يُحسب Flutter الـ `paintExtent` كـ `0.0` بينما يبقى `layoutExtent` بقيمة `minExtent` (28.0 أو أكثر)، مما يُخالف assertion الـ `SliverGeometry`.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN يقوم المستخدم بالتمرير لأسفل في الشاشة الرئيسية بينما `selectedIds` فارغة (وضع `floating`) THEN يرمي النظام استثناء assertion: `SliverGeometry is not valid: layoutExtent (28.0) exceeds paintExtent (0.0)`

1.2 WHEN يكون الـ `SliverPersistentHeader` في وضع `floating` ومخفياً بالكامل (hidden) THEN يُعيد النظام `layoutExtent` بقيمة `minExtent` (28.0) بينما `paintExtent = 0.0`، مما يُسبب crash في rendering pipeline

### Expected Behavior (Correct)

2.1 WHEN يقوم المستخدم بالتمرير لأسفل في الشاشة الرئيسية بينما `selectedIds` فارغة THEN يجب أن يعمل النظام بدون أي استثناء، ويختفي الـ header بسلاسة

2.2 WHEN يكون الـ `SliverPersistentHeader` في وضع `floating` ومخفياً بالكامل THEN يجب أن يكون `layoutExtent <= paintExtent` دائماً، بحيث لا يتجاوز `layoutExtent` قيمة `paintExtent` في أي حالة

### Unchanged Behavior (Regression Prevention)

3.1 WHEN تكون `selectedIds` غير فارغة (وضع `pinned`) THEN يجب أن يستمر النظام في عرض الـ header ثابتاً في أعلى الشاشة بشكل صحيح

3.2 WHEN يقوم المستخدم بالتمرير لأعلى بعد التمرير لأسفل THEN يجب أن يستمر النظام في إظهار الـ header مجدداً بسلاسة (floating behavior)

3.3 WHEN يكون الـ header ظاهراً بالكامل THEN يجب أن يستمر النظام في عرضه بالارتفاع الكامل `expandedHeight = 80.0`

3.4 WHEN يتبدل وضع الـ header بين `pinned` و`floating` (عند تحديد ملاحظات أو إلغاء تحديدها) THEN يجب أن يستمر النظام في التبديل بدون أي خطأ أو تشويه بصري
