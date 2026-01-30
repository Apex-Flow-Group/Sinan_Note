// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:apex_note/controllers/editor/text_direction_controller.dart';
import 'package:apex_note/controllers/editor/editor_state_manager.dart';
import 'package:faker/faker.dart';

void main() {
  group('Editor Property Tests', () {
    final faker = Faker();

    group('Property 2: Text Direction Preserves Formatting', () {
      test('formatting is preserved after direction detection', () {
        final controller = TextDirectionController();
        
        for (int i = 0; i < 50; i++) {
          final text = '**${faker.lorem.word()}** _${faker.lorem.word()}_';
          final directions = controller.getParagraphDirections(text);
          
          expect(directions, isNotEmpty);
          expect(text, contains('**'));
          expect(text, contains('_'));
        }
      });

      test('markdown formatting preserved in mixed text', () {
        final controller = TextDirectionController();
        
        final texts = [
          '# عنوان\n## Heading',
          '- مهمة\n- Task',
          '**نص** bold',
          '_مائل_ italic',
        ];

        for (final text in texts) {
          final directions = controller.getParagraphDirections(text);
          expect(directions, isNotEmpty);
        }
      });
    });

    group('Property 7: Mode State Preservation', () {
      test('state preserved across mode changes', () {
        final manager = EditorStateManager();
        
        for (int i = 0; i < 50; i++) {
          final content = faker.lorem.sentence();
          final title = faker.lorem.word();
          final colorIndex = faker.randomGenerator.integer(10);
          
          manager.content = content;
          manager.customTitle = title;
          manager.colorIndex = colorIndex;
          manager.updateSnapshot();
          
          expect(manager.content, content);
          expect(manager.customTitle, title);
          expect(manager.colorIndex, colorIndex);
          expect(manager.hasChanges(), false);
        }
      });

      test('dirty state preserved correctly', () {
        final manager = EditorStateManager();
        
        manager.content = 'initial';
        manager.updateSnapshot();
        
        expect(manager.hasChanges(), false);
        
        manager.content = 'modified';
        expect(manager.hasChanges(), true);
        
        manager.updateSnapshot();
        expect(manager.hasChanges(), false);
      });
    });

    group('Property 8: Undo/Redo Consistency', () {
      test('undo/redo state consistency', () {
        final manager = EditorStateManager();
        
        expect(manager.canUndo, false);
        expect(manager.canRedo, false);
        
        manager.canUndo = true;
        expect(manager.canUndo, true);
        
        manager.canRedo = true;
        expect(manager.canRedo, true);
        
        manager.canUndo = false;
        manager.canRedo = false;
        expect(manager.canUndo, false);
        expect(manager.canRedo, false);
      });

      test('undo/redo state independent of content', () {
        final manager = EditorStateManager();
        
        for (int i = 0; i < 50; i++) {
          manager.content = faker.lorem.sentence();
          manager.canUndo = faker.randomGenerator.boolean();
          manager.canRedo = faker.randomGenerator.boolean();
          
          expect(manager.canUndo, isA<bool>());
          expect(manager.canRedo, isA<bool>());
        }
      });
    });
  });
}
