// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';import 'package:sinan_note/core/utils/checklist_formatter.dart'; import 'package:sinan_note/core/utils/note_content_utils.dart'; import 'package:sinan_note/models/note.dart'; import 'package:sinan_note/services/notification_service.dart'; import 'package:sinan_note/services/widget_service.dart';
/// Service responsible for handling side effects of note operations.
///
/// This service manages external system interactions that occur as a result
/// of note operations, such as scheduling notifications and updating widgets.
///
/// **Responsibilities:**
/// - Schedule/cancel reminder notifications
/// - Update home screen widgets
/// - Handle permission checking for notifications
/// - Format notification content
///
/// **Side Effects Handled:**
/// - **Reminders:** Schedule notifications for future reminders
/// - **Widgets:** Update Android home screen widgets when pinned notes change
/// - **Recurrence:** Handle repeating reminders (daily, weekly, monthly)
class NoteSideEffectService {
  /// Handle reminder side effect for a note
  ///
  /// **Flow:**
  /// 1. Cancel any existing reminder for this note
  /// 2. If note has a future reminder, schedule new notification
  /// 3. Check exact alarm permission (Android 12+)
  /// 4. Format notification body (special handling for checklists)
  /// 5. Schedule notification with recurrence rule if applicable
  ///
  /// **Permission Handling:**
  /// - Android 12+ requires SCHEDULE_EXACT_ALARM permission
  /// - If permission is denied, scheduling fails silently
  /// - Returns false if permission check fails
  ///
  /// **Checklist Formatting:**
  /// - Checklists are formatted using ChecklistFormatter
  /// - Shows task completion status in notification
  ///
  /// **Parameters:**
  /// - `note`: The note to handle reminder for
  ///
  /// **Returns:** true if successful, false if permission denied or error
  Future<bool> handleReminderSideEffect(Note note) async {
    // Only handle reminders on mobile platforms
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    try {
      final notificationService = NotificationService();

      // Cancel old reminder first
      await notificationService.cancelNotification(note.id!);

      // Schedule new reminder if exists and is future
      if (note.reminderDateTime != null &&
          note.reminderDateTime!.isAfter(DateTime.now()) &&
          !note.isTrashed &&
          !note.isArchived) {
        // Check exact alarm permission (Android 12+)
        final hasPermission =
            await notificationService.checkExactAlarmPermission();
        if (!hasPermission) {
          return false;
        }

        // Format notification body — convert Delta/Checklist to plain text
        String notificationBody;
        if (note.isChecklist) {
          // Special formatting for checklists
          notificationBody =
              ChecklistFormatter.formatForSharing(note.title, note.content);
          if (notificationBody.length > 100) {
            notificationBody = '${notificationBody.substring(0, 100)}...';
          }
        } else {
          // Convert Delta JSON (or plain text) to readable plain text
          notificationBody = NoteContentUtils.toDisplayText(
            note.content,
            maxChars: 100,
          );
        }

        // Schedule notification
        await notificationService.scheduleNotification(
          id: note.id!,
          title: note.title.isEmpty ? 'تذكير' : note.title,
          body: notificationBody,
          scheduledTime: note.reminderDateTime!,
          recurrenceRule: note.recurrenceRule,
          payload: note.id.toString(),
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Cancel reminder for a note
  ///
  /// **Use Cases:**
  /// - Note is trashed
  /// - Note is archived
  /// - Reminder is removed
  /// - Note is deleted
  ///
  /// **Parameters:**
  /// - `noteId`: ID of the note to cancel reminder for
  Future<void> cancelReminderSideEffect(int noteId) async {
    // Only handle reminders on mobile platforms
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      await NotificationService().cancelNotification(noteId);
    
    } catch (_) {}
  }

  /// Update widget side effect
  ///
  /// **Note:** Currently skipped during batch operations to prevent
  /// unnecessary database reloads. Widget will update on next app launch
  /// or when a note is manually pinned.
  ///
  /// **Use Cases:**
  /// - Note is pinned/unpinned
  /// - Pinned note is modified
  /// - Pinned note is deleted
  ///
  /// **Platform:** Android only
  Future<void> updateWidgetSideEffect() async {}

  /// Check and update widget if note is pinned
  ///
  /// **Flow:**
  /// 1. Check if note is pinned
  /// 2. If pinned, update widget with note data
  ///
  /// **Parameters:**
  /// - `note`: The note to check and update widget for
  Future<void> checkAndUpdateIfPinned(Note note) async {
    if (!Platform.isAndroid) return;

    try {
      await WidgetService.checkAndUpdateIfPinned(note);
      
    } catch (_) {}
  }

  /// Check and reset widget if pinned note is deleted
  ///
  /// **Flow:**
  /// 1. Check if deleted note was pinned
  /// 2. If pinned, reset widget to default state
  ///
  /// **Parameters:**
  /// - `noteId`: ID of the deleted note
  Future<void> checkAndResetIfPinned(int noteId) async {
    if (!Platform.isAndroid) return;

    try {
      await WidgetService.checkAndResetIfPinned(noteId);
      
    } catch (_) {}
  }
}

