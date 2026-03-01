# lib/services/ — الخدمات

كل منطق الأعمال معزول هنا بعيداً عن الـ UI.

---

## الخدمات

### 📦 storage/
| الملف | الوظيفة |
|-------|---------|
| `isar_database_service.dart` | CRUD مباشر مع قاعدة Isar |
| `storage_service.dart` | تصدير/استيراد JSON |
| `backup_service.dart` | نسخ احتياطي كامل مع بيانات الخزنة |
| `compression_service.dart` | ضغط البيانات |

### 🔐 security/
| الملف | الوظيفة |
|-------|---------|
| `vault_service.dart` | تشفير/فك تشفير AES-256 |
| `biometric_service.dart` | مصادقة بصمة/وجه |
| `security_gate.dart` | بوابة الوصول للخزنة |

### 📝 note_services/
| الملف | الوظيفة |
|-------|---------|
| `note_state_service.dart` | حالة الملاحظة (archive, trash, pin...) |
| `note_security_service.dart` | تشفير/فك تشفير الملاحظات المقفلة |
| `note_batch_operations_service.dart` | عمليات جماعية (حذف/أرشفة متعدد) |
| `note_side_effect_service.dart` | التأثيرات الجانبية (إلغاء تذكير عند الحذف...) |

### ☁️ cloud/
| الملف | الوظيفة |
|-------|---------|
| `google_drive_service.dart` | مزامنة Google Drive |

### 🔍 search/
| الملف | الوظيفة |
|-------|---------|
| `smart_search_service.dart` | بحث ذكي مع ترتيب بالأولوية |

### 🔔 notifications/
| الملف | الوظيفة |
|-------|---------|
| `notification_service.dart` | جدولة التذكيرات المحلية |
| `unified_notification_service.dart` | عرض Toast/Snackbar موحد في الـ UI |

### 🛠️ أخرى
| الملف | الوظيفة |
|-------|---------|
| `language_detector.dart` | اكتشاف لغة الكود تلقائياً (25+ لغة) |
| `svg_service.dart` | معاينة SVG في المتصفح + تصدير |
| `code_executor.dart` | حفظ الكود كملف (التنفيذ معطّل أمنياً) |
| `smart_analyzer.dart` | تحليل رياضيات وتواريخ في النص |
| `version_control_service.dart` | تتبع تاريخ تعديلات الملاحظة |
| `version_history_service.dart` | استعادة إصدار سابق |
| `widget_service.dart` | Home Widget للشاشة الرئيسية |

---

## ملاحظات أمنية

- التنفيذ المحلي للكود **معطّل** في `code_executor.dart` — مخطط له Judge0 API
- كل تشفير يمر عبر `VaultService` فقط
- `BiometricService` يتحقق من الجلسة قبل فك التشفير
