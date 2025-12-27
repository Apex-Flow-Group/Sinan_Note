# 🔐 معلومات التوقيع - Google Play Store

## 📱 معلومات التطبيق
- **اسم التطبيق:** Sinan Note
- **Package ID:** com.apexflow.app.sinan
- **الإصدار:** 2.1.9+3277
- **Target SDK:** 35
- **Min SDK:** 21

## 🔑 معلومات التوقيع

### Upload Certificate (SHA-256)
```
FE:3E:75:EC:AC:DF:3B:2B:A1:2A:C0:A0:DD:9B:F2:95:B7:22:38:68:51:64:EE:0E:04:8E:75:E9:9B:0F:85:6C
```

### Upload Certificate (SHA-1)
```
62:AA:DE:BB:38:85:91:F0:21:1B:82:70:49:A4:5C:99:D7:86:31:CC
```

### ملفات التوقيع
- **Keystore:** upload-keystore.jks
- **Certificate:** upload_certificate.pem
- **Key Alias:** upload
- **Store Password:** tOOp_59376
- **Key Password:** tOOp_59376

## 🏗️ إعدادات البناء

### Flavors المتاحة
1. **googlePlay** - للنشر على Google Play Store
2. **fDroid** - للنشر على F-Droid

### أوامر البناء
```bash
# بناء APK للـ Google Play
flutter build apk --flavor googlePlay --release

# بناء AAB للـ Google Play (مفضل)
flutter build appbundle --flavor googlePlay --release
```

## ⚠️ ملاحظات مهمة

1. **التوقيع صحيح ومُعد بشكل سليم**
2. **الشهادة صالحة حتى 2053**
3. **تم حظر MANAGE_EXTERNAL_STORAGE permission (متوافق مع سياسة Google Play)**
4. **Target SDK 35 (Android 15) - محدث**

## 📋 قائمة التحقق قبل الرفع

- ✅ التوقيع مُعد بشكل صحيح
- ✅ الشهادة صالحة
- ✅ Package name فريد
- ✅ Target SDK محدث
- ✅ Permissions متوافقة مع سياسة Google Play
- ✅ App Bundle جاهز للرفع

## 🚀 خطوات الرفع على Google Play

1. بناء App Bundle:
   ```bash
   flutter build appbundle --flavor googlePlay --release
   ```

2. الملف سيكون في:
   ```
   build/app/outputs/bundle/googlePlayRelease/app-googlePlay-release.aab
   ```

3. رفع الملف على Google Play Console
4. إدخال SHA-256 fingerprint في Console إذا طُلب
5. مراجعة وإرسال للمراجعة

---
**تم إنشاء هذا الملف في:** $(date)