# 🧪 Testing Guide | دليل الاختبار

## Test Structure | هيكل الاختبارات

```
test/
├── unit/           # Unit tests
├── integration/    # Integration tests
├── property/       # Property-based tests
└── performance/    # Performance tests
```

## Running Tests | تشغيل الاختبارات

```bash
# All tests
flutter test

# Specific test
flutter test test/unit/services/encryption_service_test.dart

# With coverage
flutter test --coverage
```

## Unit Tests | اختبارات الوحدة

```dart
test('should encrypt and decrypt', () async {
  final encrypted = await EncryptionService.encrypt('test');
  final decrypted = await EncryptionService.decrypt(encrypted);
  expect(decrypted, equals('test'));
});
```

## Widget Tests | اختبارات الواجهة

```dart
testWidgets('displays note title', (tester) async {
  await tester.pumpWidget(MaterialApp(home: NoteCard(note: note)));
  expect(find.text('Test'), findsOneWidget);
});
```

## Best Practices | أفضل الممارسات

1. Test business logic thoroughly
2. Mock external dependencies
3. Use descriptive test names
4. Aim for 80%+ coverage

---

See [ARCHITECTURE.md](../../ARCHITECTURE.md) for details.
