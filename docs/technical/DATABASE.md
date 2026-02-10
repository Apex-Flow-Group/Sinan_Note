# 💾 Database Design | تصميم قاعدة البيانات

## Schema | المخطط

```sql
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL,
  colorValue INTEGER DEFAULT 0xFFFFFFFF,
  isArchived INTEGER DEFAULT 0,
  isTrashed INTEGER DEFAULT 0,
  isLocked INTEGER DEFAULT 0,
  isPinned INTEGER DEFAULT 0,
  reminderDateTime INTEGER,
  noteType TEXT DEFAULT 'simple'
);

CREATE INDEX idx_locked ON notes(isLocked);
CREATE INDEX idx_updated ON notes(updatedAt DESC);
```

## Operations | العمليات

### CRUD
- **Create**: `insertNote()`
- **Read**: `getAllNotes()`
- **Update**: `updateNote()`
- **Delete**: `deleteNote()`

### Soft Delete
```dart
// Move to trash (recoverable)
await db.update('notes', {'isTrashed': 1}, where: 'id = ?');
```

## Performance | الأداء

- In-memory caching
- Indexed queries
- Batch operations

---

See [ARCHITECTURE.md](../../ARCHITECTURE.md) for details.
