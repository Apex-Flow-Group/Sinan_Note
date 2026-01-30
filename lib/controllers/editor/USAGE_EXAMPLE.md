# 📝 Editor Controllers Usage Examples

## TextDirectionController - دعم النصوص المختلطة

### مثال بسيط | Simple Example

```dart
import 'package:flutter/material.dart';
import 'package:apex_note/controllers/editor/text_direction_controller.dart';

class SimpleNoteEditor extends StatefulWidget {
  @override
  State<SimpleNoteEditor> createState() => _SimpleNoteEditorState();
}

class _SimpleNoteEditorState extends State<SimpleNoteEditor> {
  final TextEditingController _controller = TextEditingController();
  final TextDirectionController _textDirController = TextDirectionController();
  TextDirection _currentDirection = TextDirection.ltr;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('محرر بسيط | Simple Editor')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: TextField(
          controller: _controller,
          textDirection: _currentDirection,
          maxLines: null,
          decoration: InputDecoration(
            hintText: 'اكتب هنا... | Type here...',
            border: OutlineInputBorder(),
          ),
          onChanged: (text) {
            setState(() {
              // Update direction dynamically based on content
              _currentDirection = _textDirController.detectParagraphDirection(text);
            });
          },
        ),
      ),
    );
  }
}
```

---

## مثال متقدم | Advanced Example

### دعم فقرات متعددة | Multi-Paragraph Support

```dart
import 'package:flutter/material.dart';
import 'package:apex_note/controllers/editor/text_direction_controller.dart';

class AdvancedNoteEditor extends StatefulWidget {
  @override
  State<AdvancedNoteEditor> createState() => _AdvancedNoteEditorState();
}

class _AdvancedNoteEditorState extends State<AdvancedNoteEditor> {
  final TextEditingController _controller = TextEditingController();
  final TextDirectionController _textDirController = TextDirectionController();
  List<ParagraphDirection> _paragraphDirections = [];
  
  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateDirections);
  }
  
  void _updateDirections() {
    setState(() {
      _paragraphDirections = _textDirController.getParagraphDirections(
        _controller.text
      );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('محرر متقدم | Advanced Editor'),
        actions: [
          // Show paragraph count and directions
          Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                '${_paragraphDirections.length} فقرات | paragraphs',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Direction indicator
          Container(
            padding: EdgeInsets.all(8),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getDirectionInfo(),
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          
          // Editor
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'اكتب فقرات متعددة...\nWrite multiple paragraphs...',
                  border: OutlineInputBorder(),
                ),
                // Use overall direction for the field
                textDirection: _paragraphDirections.isEmpty
                    ? TextDirection.ltr
                    : _textDirController.detectOverallDirection(_controller.text),
              ),
            ),
          ),
          
          // Paragraph list
          if (_paragraphDirections.isNotEmpty)
            Container(
              height: 150,
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تحليل الفقرات | Paragraph Analysis:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _paragraphDirections.length,
                      itemBuilder: (context, index) {
                        final para = _paragraphDirections[index];
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            para.direction == TextDirection.rtl
                                ? Icons.format_align_right
                                : Icons.format_align_left,
                            size: 16,
                          ),
                          title: Text(
                            para.text.isEmpty ? '(فارغة | empty)' : para.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12),
                          ),
                          subtitle: Text(
                            para.direction == TextDirection.rtl ? 'RTL' : 'LTR',
                            style: TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  String _getDirectionInfo() {
    if (_paragraphDirections.isEmpty) {
      return 'لا توجد فقرات | No paragraphs';
    }
    
    final rtlCount = _paragraphDirections
        .where((p) => p.direction == TextDirection.rtl)
        .length;
    final ltrCount = _paragraphDirections.length - rtlCount;
    
    if (_textDirController.isMixedDirection(_controller.text)) {
      return 'نص مختلط | Mixed text: $rtlCount RTL, $ltrCount LTR';
    } else if (rtlCount > 0) {
      return 'نص عربي | Arabic text: $rtlCount فقرات';
    } else {
      return 'English text: $ltrCount paragraphs';
    }
  }
  
  @override
  void dispose() {
    _controller.removeListener(_updateDirections);
    _controller.dispose();
    super.dispose();
  }
}
```

---

## EditorStateManager - إدارة الحالة

### مثال أساسي | Basic Example

```dart
import 'package:flutter/material.dart';
import 'package:apex_note/controllers/editor/editor_state_manager.dart';
import 'package:apex_note/models/note.dart';

class StatefulNoteEditor extends StatefulWidget {
  final Note? note;
  
  const StatefulNoteEditor({Key? key, this.note}) : super(key: key);
  
  @override
  State<StatefulNoteEditor> createState() => _StatefulNoteEditorState();
}

class _StatefulNoteEditorState extends State<StatefulNoteEditor> {
  final TextEditingController _controller = TextEditingController();
  final EditorStateManager _stateManager = EditorStateManager();
  
  @override
  void initState() {
    super.initState();
    
    // Load from existing note
    if (widget.note != null) {
      _stateManager.loadFromNote(
        noteContent: widget.note!.content,
        noteTitle: widget.note!.title,
        noteColorIndex: widget.note!.colorIndex,
        noteReminderDateTime: widget.note!.reminderDateTime,
        noteRecurrenceRule: widget.note!.recurrenceRule,
      );
      _controller.text = widget.note!.content;
    }
    
    // Listen to changes
    _controller.addListener(_onContentChanged);
  }
  
  void _onContentChanged() {
    _stateManager.updateContent(_controller.text);
    setState(() {}); // Update UI
  }
  
  Future<bool> _onWillPop() async {
    // Check for unsaved changes
    if (_stateManager.hasChanges()) {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('حفظ التغييرات؟ | Save changes?'),
          content: Text('لديك تغييرات غير محفوظة | You have unsaved changes'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('تجاهل | Discard'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('حفظ | Save'),
            ),
          ],
        ),
      );
      
      if (shouldSave == true) {
        await _saveNote();
      }
    }
    
    return true;
  }
  
  Future<void> _saveNote() async {
    setState(() {
      _stateManager.isSaving = true;
    });
    
    try {
      // Save to database
      // ... save logic here
      
      // Update snapshot after successful save
      _stateManager.updateSnapshot();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم الحفظ | Saved')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الحفظ | Save error: $e')),
      );
    } finally {
      setState(() {
        _stateManager.isSaving = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('محرر الملاحظات | Note Editor'),
          actions: [
            // Dirty indicator
            if (_stateManager.isDirty)
              Padding(
                padding: EdgeInsets.all(16),
                child: Icon(Icons.circle, size: 8, color: Colors.orange),
              ),
            
            // Save button
            IconButton(
              icon: _stateManager.isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.save),
              onPressed: _stateManager.hasChanges() && !_stateManager.isSaving
                  ? _saveNote
                  : null,
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Status bar
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _stateManager.hasChanges()
                      ? Colors.orange.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _stateManager.hasChanges()
                          ? Icons.edit
                          : Icons.check_circle,
                      size: 16,
                      color: _stateManager.hasChanges()
                          ? Colors.orange
                          : Colors.green,
                    ),
                    SizedBox(width: 8),
                    Text(
                      _stateManager.hasChanges()
                          ? 'تغييرات غير محفوظة | Unsaved changes'
                          : 'محفوظ | Saved',
                      style: TextStyle(fontSize: 12),
                    ),
                    Spacer(),
                    Text(
                      '${_controller.text.length} حرف | chars',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 16),
              
              // Editor
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: 'اكتب ملاحظتك... | Write your note...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.removeListener(_onContentChanged);
    _controller.dispose();
    super.dispose();
  }
}
```

---

## دمج كامل | Full Integration

### مثال شامل يجمع كل شيء | Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:apex_note/controllers/editor/text_direction_controller.dart';
import 'package:apex_note/controllers/editor/editor_state_manager.dart';
import 'package:apex_note/models/note.dart';

class FullFeaturedEditor extends StatefulWidget {
  final Note? note;
  
  const FullFeaturedEditor({Key? key, this.note}) : super(key: key);
  
  @override
  State<FullFeaturedEditor> createState() => _FullFeaturedEditorState();
}

class _FullFeaturedEditorState extends State<FullFeaturedEditor> {
  final TextEditingController _controller = TextEditingController();
  final TextDirectionController _textDirController = TextDirectionController();
  final EditorStateManager _stateManager = EditorStateManager();
  
  TextDirection _currentDirection = TextDirection.ltr;
  List<ParagraphDirection> _paragraphDirections = [];
  
  @override
  void initState() {
    super.initState();
    
    // Load from note
    if (widget.note != null) {
      _stateManager.loadFromNote(
        noteContent: widget.note!.content,
        noteTitle: widget.note!.title,
        noteColorIndex: widget.note!.colorIndex,
      );
      _controller.text = widget.note!.content;
      _updateDirections();
    }
    
    _controller.addListener(_onContentChanged);
  }
  
  void _onContentChanged() {
    _stateManager.updateContent(_controller.text);
    _updateDirections();
    setState(() {});
  }
  
  void _updateDirections() {
    _paragraphDirections = _textDirController.getParagraphDirections(
      _controller.text
    );
    _currentDirection = _textDirController.detectOverallDirection(
      _controller.text
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('محرر متكامل | Full Editor'),
        actions: [
          // Direction indicator
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Chip(
                avatar: Icon(
                  _currentDirection == TextDirection.rtl
                      ? Icons.format_align_right
                      : Icons.format_align_left,
                  size: 16,
                ),
                label: Text(
                  _currentDirection == TextDirection.rtl ? 'RTL' : 'LTR',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
          
          // Dirty indicator
          if (_stateManager.isDirty)
            Icon(Icons.circle, size: 8, color: Colors.orange),
          
          // Save button
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _stateManager.hasChanges() ? _saveNote : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // Info bar
          Container(
            padding: EdgeInsets.all(12),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _getEditorInfo(),
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          
          // Editor
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                textDirection: _currentDirection,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'اكتب هنا... | Type here...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getEditorInfo() {
    final chars = _controller.text.length;
    final paragraphs = _paragraphDirections.length;
    final mixed = _textDirController.isMixedDirection(_controller.text);
    
    return '$chars حرف | chars • $paragraphs فقرات | paragraphs'
           '${mixed ? " • نص مختلط | mixed" : ""}';
  }
  
  Future<void> _saveNote() async {
    // Save logic here
    _stateManager.updateSnapshot();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم الحفظ | Saved')),
    );
  }
  
  @override
  void dispose() {
    _controller.removeListener(_onContentChanged);
    _controller.dispose();
    super.dispose();
  }
}
```

---

## نصائح | Tips

### 1. الأداء | Performance

```dart
// ✅ Good: Update direction on change
_controller.addListener(() {
  setState(() {
    _currentDirection = _textDirController.detectParagraphDirection(
      _controller.text
    );
  });
});

// ❌ Bad: Update on every frame
@override
Widget build(BuildContext context) {
  _currentDirection = _textDirController.detectParagraphDirection(
    _controller.text
  ); // Don't do this!
  return TextField(...);
}
```

### 2. الذاكرة | Memory

```dart
// ✅ Good: Dispose controllers
@override
void dispose() {
  _controller.dispose();
  _stateManager.clear();
  super.dispose();
}
```

### 3. الحفظ التلقائي | Autosave

```dart
Timer? _autosaveTimer;

void _onContentChanged() {
  _stateManager.updateContent(_controller.text);
  
  // Debounce autosave
  _autosaveTimer?.cancel();
  _autosaveTimer = Timer(Duration(milliseconds: 500), () {
    if (_stateManager.hasChanges()) {
      _saveNote();
    }
  });
}
```

---

## المزيد | More

راجع الملفات التالية | See these files:
- `REFACTORING_ARCHITECTURE.md` - البنية المعمارية الكاملة
- `lib/controllers/editor/text_direction_controller.dart` - الكود الكامل
- `lib/controllers/editor/editor_state_manager.dart` - الكود الكامل
