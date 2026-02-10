# 🔐 Security System | نظام الأمان

## Overview | نظرة عامة

Sinan Note uses multi-layer security:
- AES-256 encryption
- Biometric authentication
- Session management
- Memory protection

## Encryption | التشفير

### AES-256
```dart
// Key stored in Android Keystore
final key = await _getOrCreateKey();
final iv = IV.fromSecureRandom(16);
final encrypted = encrypter.encrypt(plainText, iv: iv);
return '${iv.base64}:${encrypted.base64}';
```

### Storage
- Android: Hardware-backed Keystore
- Linux/Windows: Encrypted preferences

## Session Management | إدارة الجلسة

- Auto-lock after 5 minutes
- Lock on app background
- Memory wipe on lock

## Best Practices | أفضل الممارسات

1. Never store keys in code
2. Use biometric when available
3. Clear sensitive data from memory
4. Validate encryption/decryption

---

See [ARCHITECTURE.md](../../ARCHITECTURE.md) for details.
