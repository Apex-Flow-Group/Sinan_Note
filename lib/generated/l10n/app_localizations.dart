import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Sinan Note'**
  String get appName;

  /// No description provided for @newNote.
  ///
  /// In en, this message translates to:
  /// **'New Note'**
  String get newNote;

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get editNote;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @writeNote.
  ///
  /// In en, this message translates to:
  /// **'Write your note here...'**
  String get writeNote;

  /// No description provided for @deleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete Note'**
  String get deleteNote;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this note?'**
  String get deleteConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @movedToTrash.
  ///
  /// In en, this message translates to:
  /// **'Note moved to trash'**
  String get movedToTrash;

  /// No description provided for @textCopied.
  ///
  /// In en, this message translates to:
  /// **'Text copied'**
  String get textCopied;

  /// No description provided for @wordCount.
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get wordCount;

  /// No description provided for @charCount.
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get charCount;

  /// No description provided for @myNotes.
  ///
  /// In en, this message translates to:
  /// **'My Notes'**
  String get myNotes;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @trash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get trash;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @cloudUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload to Cloud'**
  String get cloudUpload;

  /// No description provided for @backupSoon.
  ///
  /// In en, this message translates to:
  /// **'Backup will be available soon'**
  String get backupSoon;

  /// No description provided for @noNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes'**
  String get noNotes;

  /// No description provided for @searchNotes.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchNotes;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copyCreated.
  ///
  /// In en, this message translates to:
  /// **'Copy created'**
  String get copyCreated;

  /// No description provided for @movedToArchive.
  ///
  /// In en, this message translates to:
  /// **'Note moved to archive'**
  String get movedToArchive;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export Backup'**
  String get exportBackup;

  /// No description provided for @exportBackupDesc.
  ///
  /// In en, this message translates to:
  /// **'Save notes as JSON file'**
  String get exportBackupDesc;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get importBackup;

  /// No description provided for @importBackupDesc.
  ///
  /// In en, this message translates to:
  /// **'Restore notes from JSON file'**
  String get importBackupDesc;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareApp;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Smart and Professional Notes App'**
  String get appDescription;

  /// No description provided for @allRightsReserved.
  ///
  /// In en, this message translates to:
  /// **'© 2025 All rights reserved.'**
  String get allRightsReserved;

  /// No description provided for @swipeGestures.
  ///
  /// In en, this message translates to:
  /// **'Swipe Gestures'**
  String get swipeGestures;

  /// No description provided for @swipeGesturesDesc.
  ///
  /// In en, this message translates to:
  /// **'Swipe to perform actions'**
  String get swipeGesturesDesc;

  /// No description provided for @swipeRight.
  ///
  /// In en, this message translates to:
  /// **'Swipe Right'**
  String get swipeRight;

  /// No description provided for @swipeLeft.
  ///
  /// In en, this message translates to:
  /// **'Swipe Left'**
  String get swipeLeft;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get actionArchive;

  /// No description provided for @actionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionShare;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @deleteNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Note'**
  String get deleteNoteTitle;

  /// No description provided for @deleteNoteMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete'**
  String get deleteNoteMessage;

  /// No description provided for @simpleNote.
  ///
  /// In en, this message translates to:
  /// **'Simple Note'**
  String get simpleNote;

  /// No description provided for @simpleNoteDesc.
  ///
  /// In en, this message translates to:
  /// **'Quick text without formatting'**
  String get simpleNoteDesc;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @reminderDesc.
  ///
  /// In en, this message translates to:
  /// **'Task with notification'**
  String get reminderDesc;

  /// No description provided for @proEditor.
  ///
  /// In en, this message translates to:
  /// **'Pro Editor'**
  String get proEditor;

  /// No description provided for @proEditorDesc.
  ///
  /// In en, this message translates to:
  /// **'Code highlighting and formatting'**
  String get proEditorDesc;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @lockedNote.
  ///
  /// In en, this message translates to:
  /// **'Locked Note'**
  String get lockedNote;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPassword;

  /// No description provided for @wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password'**
  String get wrongPassword;

  /// No description provided for @decryptionFailed.
  ///
  /// In en, this message translates to:
  /// **'Decryption failed'**
  String get decryptionFailed;

  /// No description provided for @lockNote.
  ///
  /// In en, this message translates to:
  /// **'Lock Note'**
  String get lockNote;

  /// No description provided for @unlockNote.
  ///
  /// In en, this message translates to:
  /// **'Unlock Note'**
  String get unlockNote;

  /// No description provided for @unlockNoteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Do you want to unlock this note and move it to regular notes?'**
  String get unlockNoteConfirmation;

  /// No description provided for @enterPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter password (4+ characters)'**
  String get enterPasswordHint;

  /// No description provided for @noteLocked.
  ///
  /// In en, this message translates to:
  /// **'Note locked'**
  String get noteLocked;

  /// No description provided for @noteUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get noteUnlocked;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password too short'**
  String get passwordTooShort;

  /// No description provided for @renameNote.
  ///
  /// In en, this message translates to:
  /// **'Rename Note'**
  String get renameNote;

  /// No description provided for @enterCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter custom title'**
  String get enterCustomTitle;

  /// No description provided for @automatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get automatic;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @addReminder.
  ///
  /// In en, this message translates to:
  /// **'Add Reminder'**
  String get addReminder;

  /// No description provided for @reminderAdded.
  ///
  /// In en, this message translates to:
  /// **'Reminder added'**
  String get reminderAdded;

  /// No description provided for @saveNoteFirst.
  ///
  /// In en, this message translates to:
  /// **'Save note first'**
  String get saveNoteFirst;

  /// No description provided for @chooseColor.
  ///
  /// In en, this message translates to:
  /// **'Choose Color'**
  String get chooseColor;

  /// No description provided for @encryptedContent.
  ///
  /// In en, this message translates to:
  /// **'🔒 Encrypted content'**
  String get encryptedContent;

  /// No description provided for @startWriting.
  ///
  /// In en, this message translates to:
  /// **'Start writing...'**
  String get startWriting;

  /// No description provided for @noteCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get noteCopy;

  /// No description provided for @importedNotes.
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get importedNotes;

  /// No description provided for @notesSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'notes successfully!'**
  String get notesSuccessfully;

  /// No description provided for @noNotesToExport.
  ///
  /// In en, this message translates to:
  /// **'No notes to export'**
  String get noNotesToExport;

  /// No description provided for @allNotesEmpty.
  ///
  /// In en, this message translates to:
  /// **'All notes are empty'**
  String get allNotesEmpty;

  /// No description provided for @noFileSelected.
  ///
  /// In en, this message translates to:
  /// **'No file selected'**
  String get noFileSelected;

  /// No description provided for @fileEmpty.
  ///
  /// In en, this message translates to:
  /// **'File is empty'**
  String get fileEmpty;

  /// No description provided for @noNotesInFile.
  ///
  /// In en, this message translates to:
  /// **'No notes in file'**
  String get noNotesInFile;

  /// No description provided for @allNotesInFileEmpty.
  ///
  /// In en, this message translates to:
  /// **'All notes in file are empty'**
  String get allNotesInFileEmpty;

  /// No description provided for @readFileFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to read file'**
  String get readFileFailed;

  /// No description provided for @shareFileFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to share file'**
  String get shareFileFailed;

  /// No description provided for @movedTo.
  ///
  /// In en, this message translates to:
  /// **'Moved'**
  String get movedTo;

  /// No description provided for @toTrash.
  ///
  /// In en, this message translates to:
  /// **'to trash'**
  String get toTrash;

  /// No description provided for @toArchive.
  ///
  /// In en, this message translates to:
  /// **'to archive'**
  String get toArchive;

  /// No description provided for @sum.
  ///
  /// In en, this message translates to:
  /// **'Sum'**
  String get sum;

  /// No description provided for @insert.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get insert;

  /// No description provided for @autoSaved.
  ///
  /// In en, this message translates to:
  /// **'Auto saved'**
  String get autoSaved;

  /// No description provided for @newNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'New Note'**
  String get newNoteTitle;

  /// No description provided for @savedToDownloads.
  ///
  /// In en, this message translates to:
  /// **'Saved in Downloads folder'**
  String get savedToDownloads;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning!'**
  String get warning;

  /// No description provided for @replaceAllNotes.
  ///
  /// In en, this message translates to:
  /// **'All current notes will be replaced. Are you sure?'**
  String get replaceAllNotes;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @restoredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Restored successfully'**
  String get restoredSuccessfully;

  /// No description provided for @importedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'notes imported successfully!'**
  String get importedSuccessfully;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @noteRestored.
  ///
  /// In en, this message translates to:
  /// **'Note restored'**
  String get noteRestored;

  /// No description provided for @notesRestored.
  ///
  /// In en, this message translates to:
  /// **'Notes restored'**
  String get notesRestored;

  /// No description provided for @permanentDelete.
  ///
  /// In en, this message translates to:
  /// **'Permanent Delete'**
  String get permanentDelete;

  /// No description provided for @confirmPermanentDelete.
  ///
  /// In en, this message translates to:
  /// **'Do you want to permanently delete this note? This action cannot be undone.'**
  String get confirmPermanentDelete;

  /// No description provided for @confirmPermanentDeleteMultiple.
  ///
  /// In en, this message translates to:
  /// **'Do you want to permanently delete'**
  String get confirmPermanentDeleteMultiple;

  /// No description provided for @notesQuestion.
  ///
  /// In en, this message translates to:
  /// **'notes?'**
  String get notesQuestion;

  /// No description provided for @noteDeleted.
  ///
  /// In en, this message translates to:
  /// **'Note permanently deleted'**
  String get noteDeleted;

  /// No description provided for @notesDeleted.
  ///
  /// In en, this message translates to:
  /// **'Notes permanently deleted'**
  String get notesDeleted;

  /// No description provided for @confirmDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Do you want to permanently delete all notes?'**
  String get confirmDeleteAll;

  /// No description provided for @emptyTrash.
  ///
  /// In en, this message translates to:
  /// **'Trash is empty'**
  String get emptyTrash;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get selected;

  /// No description provided for @backupSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get backupSaved;

  /// No description provided for @notesIn.
  ///
  /// In en, this message translates to:
  /// **'notes in:'**
  String get notesIn;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed:'**
  String get backupFailed;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Share failed:'**
  String get shareFailed;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'This feature is coming in the next update'**
  String get comingSoon;

  /// No description provided for @soon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get soon;

  /// No description provided for @signInSuccess.
  ///
  /// In en, this message translates to:
  /// **'Signed in successfully'**
  String get signInSuccess;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign in failed:'**
  String get signInFailed;

  /// No description provided for @syncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Synced successfully'**
  String get syncSuccess;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed:'**
  String get syncFailed;

  /// No description provided for @toHome.
  ///
  /// In en, this message translates to:
  /// **'to home'**
  String get toHome;

  /// No description provided for @unarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get unarchive;

  /// No description provided for @noArchivedNotes.
  ///
  /// In en, this message translates to:
  /// **'No archived notes'**
  String get noArchivedNotes;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get fillAllFields;

  /// No description provided for @cameraBlocked.
  ///
  /// In en, this message translates to:
  /// **'Camera blocked'**
  String get cameraBlocked;

  /// No description provided for @copiedOldVersion.
  ///
  /// In en, this message translates to:
  /// **'Copied old version text'**
  String get copiedOldVersion;

  /// No description provided for @textCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Text copied to clipboard'**
  String get textCopiedToClipboard;

  /// No description provided for @approximateSum.
  ///
  /// In en, this message translates to:
  /// **'Approximate Sum:'**
  String get approximateSum;

  /// No description provided for @experimental.
  ///
  /// In en, this message translates to:
  /// **'Experimental'**
  String get experimental;

  /// No description provided for @noNumbersFound.
  ///
  /// In en, this message translates to:
  /// **'No numbers found'**
  String get noNumbersFound;

  /// No description provided for @calculated.
  ///
  /// In en, this message translates to:
  /// **'Calculated'**
  String get calculated;

  /// No description provided for @noValidExpression.
  ///
  /// In en, this message translates to:
  /// **'No valid math expression found'**
  String get noValidExpression;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid code'**
  String get invalidCode;

  /// No description provided for @saveAsFile.
  ///
  /// In en, this message translates to:
  /// **'Save as File'**
  String get saveAsFile;

  /// No description provided for @savedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get savedSuccessfully;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get saveFailed;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @noteHistory.
  ///
  /// In en, this message translates to:
  /// **'Note History'**
  String get noteHistory;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No history'**
  String get noHistory;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get deleteFailed;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @remindersOnly.
  ///
  /// In en, this message translates to:
  /// **'Reminders Only'**
  String get remindersOnly;

  /// No description provided for @byColor.
  ///
  /// In en, this message translates to:
  /// **'By Color'**
  String get byColor;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @sortAZ.
  ///
  /// In en, this message translates to:
  /// **'Sort A-Z'**
  String get sortAZ;

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear Filter'**
  String get clearFilter;

  /// No description provided for @protectedContent.
  ///
  /// In en, this message translates to:
  /// **'Protected Content'**
  String get protectedContent;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @viewNote.
  ///
  /// In en, this message translates to:
  /// **'View Note'**
  String get viewNote;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @professional.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get professional;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @noUpcomingReminders.
  ///
  /// In en, this message translates to:
  /// **'No upcoming reminders'**
  String get noUpcomingReminders;

  /// No description provided for @noScheduledReminders.
  ///
  /// In en, this message translates to:
  /// **'No scheduled reminders'**
  String get noScheduledReminders;

  /// No description provided for @noExpiredReminders.
  ///
  /// In en, this message translates to:
  /// **'No expired reminders'**
  String get noExpiredReminders;

  /// No description provided for @noProfessionalNotes.
  ///
  /// In en, this message translates to:
  /// **'No professional notes'**
  String get noProfessionalNotes;

  /// No description provided for @noteSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get noteSaved;

  /// No description provided for @secureVault.
  ///
  /// In en, this message translates to:
  /// **'Secure Vault'**
  String get secureVault;

  /// No description provided for @importFromInside.
  ///
  /// In en, this message translates to:
  /// **'Import from Inside'**
  String get importFromInside;

  /// No description provided for @sessionProtection.
  ///
  /// In en, this message translates to:
  /// **'Session Protection'**
  String get sessionProtection;

  /// No description provided for @authenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication Failed'**
  String get authenticationFailed;

  /// No description provided for @noUnlockedNotes.
  ///
  /// In en, this message translates to:
  /// **'No unlocked notes available'**
  String get noUnlockedNotes;

  /// No description provided for @importNotes.
  ///
  /// In en, this message translates to:
  /// **'Import Notes'**
  String get importNotes;

  /// No description provided for @lockNotes.
  ///
  /// In en, this message translates to:
  /// **'Lock Note(s)'**
  String get lockNotes;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @chooseTextColor.
  ///
  /// In en, this message translates to:
  /// **'Choose Text Color'**
  String get chooseTextColor;

  /// No description provided for @formattingHint.
  ///
  /// In en, this message translates to:
  /// **'Formatting Hint'**
  String get formattingHint;

  /// No description provided for @formattingHintMessage.
  ///
  /// In en, this message translates to:
  /// **'Styles like Bold and Italic are shown as symbols here. They will be rendered beautifully when you save and view the note.'**
  String get formattingHintMessage;

  /// No description provided for @dontShowAgain.
  ///
  /// In en, this message translates to:
  /// **'Don\'t show this again'**
  String get dontShowAgain;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @output.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get output;

  /// No description provided for @fileMayContainErrors.
  ///
  /// In en, this message translates to:
  /// **'File may contain errors or is incorrect'**
  String get fileMayContainErrors;

  /// No description provided for @saveAnyway.
  ///
  /// In en, this message translates to:
  /// **'Save Anyway'**
  String get saveAnyway;

  /// No description provided for @saveAsMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Save as Markdown'**
  String get saveAsMarkdown;

  /// No description provided for @detected.
  ///
  /// In en, this message translates to:
  /// **'Detected: '**
  String get detected;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date: '**
  String get date;

  /// No description provided for @protectedNote.
  ///
  /// In en, this message translates to:
  /// **'Protected Note'**
  String get protectedNote;

  /// No description provided for @verifyingIdentity.
  ///
  /// In en, this message translates to:
  /// **'Verifying Identity...'**
  String get verifyingIdentity;

  /// No description provided for @transferSuccess.
  ///
  /// In en, this message translates to:
  /// **'Transfer Successful!'**
  String get transferSuccess;

  /// No description provided for @pleaseEnterIP.
  ///
  /// In en, this message translates to:
  /// **'Please enter IP address'**
  String get pleaseEnterIP;

  /// No description provided for @connectToDevice.
  ///
  /// In en, this message translates to:
  /// **'Connect to Device'**
  String get connectToDevice;

  /// No description provided for @requestingCameraPermission.
  ///
  /// In en, this message translates to:
  /// **'Requesting camera permission...'**
  String get requestingCameraPermission;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @sendNotes.
  ///
  /// In en, this message translates to:
  /// **'Send Notes'**
  String get sendNotes;

  /// No description provided for @unlockApp.
  ///
  /// In en, this message translates to:
  /// **'Unlock App'**
  String get unlockApp;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @noHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get noHistoryYet;

  /// No description provided for @googleDrive.
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get googleDrive;

  /// No description provided for @importedFile.
  ///
  /// In en, this message translates to:
  /// **'Imported File'**
  String get importedFile;

  /// No description provided for @simpleNotes.
  ///
  /// In en, this message translates to:
  /// **'Simple Notes'**
  String get simpleNotes;

  /// No description provided for @professionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Professional Notes'**
  String get professionalNotes;

  /// No description provided for @reminderNotes.
  ///
  /// In en, this message translates to:
  /// **'Reminder Notes'**
  String get reminderNotes;

  /// No description provided for @checklists.
  ///
  /// In en, this message translates to:
  /// **'Checklists'**
  String get checklists;

  /// No description provided for @pinnedOnly.
  ///
  /// In en, this message translates to:
  /// **'Pinned Only'**
  String get pinnedOnly;

  /// No description provided for @decryptingVault.
  ///
  /// In en, this message translates to:
  /// **'Decrypting Vault...'**
  String get decryptingVault;

  /// No description provided for @noLockedNotes.
  ///
  /// In en, this message translates to:
  /// **'No locked notes'**
  String get noLockedNotes;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @lockNotesCount.
  ///
  /// In en, this message translates to:
  /// **'Lock {count} Note(s)'**
  String lockNotesCount(int count);

  /// No description provided for @sortByDate.
  ///
  /// In en, this message translates to:
  /// **'Sort by Date'**
  String get sortByDate;

  /// No description provided for @sortByTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort by Title'**
  String get sortByTitle;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @poweredBy.
  ///
  /// In en, this message translates to:
  /// **'Powered by'**
  String get poweredBy;

  /// No description provided for @companyName.
  ///
  /// In en, this message translates to:
  /// **'Apex Flow Group'**
  String get companyName;

  /// No description provided for @copyrightNotice.
  ///
  /// In en, this message translates to:
  /// **'© 2025 Apex Flow Group'**
  String get copyrightNotice;

  /// No description provided for @transferTitle.
  ///
  /// In en, this message translates to:
  /// **'Sinan Transfer'**
  String get transferTitle;

  /// No description provided for @cameraPermissionMsg.
  ///
  /// In en, this message translates to:
  /// **'Requesting camera permission...'**
  String get cameraPermissionMsg;

  /// No description provided for @enterIpError.
  ///
  /// In en, this message translates to:
  /// **'Please enter IP address'**
  String get enterIpError;

  /// No description provided for @sortDoneToBottom.
  ///
  /// In en, this message translates to:
  /// **'Done to Bottom'**
  String get sortDoneToBottom;

  /// No description provided for @sortOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original Order'**
  String get sortOriginal;

  /// No description provided for @noNotesFound.
  ///
  /// In en, this message translates to:
  /// **'No notes available'**
  String get noNotesFound;

  /// No description provided for @transferError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get transferError;

  /// No description provided for @securityAlert.
  ///
  /// In en, this message translates to:
  /// **'Security Alert'**
  String get securityAlert;

  /// No description provided for @sortDoneToTop.
  ///
  /// In en, this message translates to:
  /// **'Done to Top'**
  String get sortDoneToTop;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @noNotesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No notes available'**
  String get noNotesAvailable;

  /// No description provided for @selectNote.
  ///
  /// In en, this message translates to:
  /// **'Select Note'**
  String get selectNote;

  /// No description provided for @tapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap to select +'**
  String get tapToSelect;

  /// No description provided for @selectList.
  ///
  /// In en, this message translates to:
  /// **'Select List'**
  String get selectList;

  /// No description provided for @authenticateAndEnter.
  ///
  /// In en, this message translates to:
  /// **'Authenticate & Enter'**
  String get authenticateAndEnter;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @noLockButtonsOutside.
  ///
  /// In en, this message translates to:
  /// **'No lock buttons outside. Enter the vault and drag the notes you want to protect.'**
  String get noLockButtonsOutside;

  /// No description provided for @dataEncryptedOnExit.
  ///
  /// In en, this message translates to:
  /// **'Once you exit, data is encrypted and memory is cleared immediately.'**
  String get dataEncryptedOnExit;

  /// No description provided for @precisePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Failed! Precise permission required. 💡'**
  String get precisePermissionRequired;

  /// No description provided for @fileContainsErrors.
  ///
  /// In en, this message translates to:
  /// **'The file you want to save may contain errors or is incorrect. It\'s better to save it as markdown.'**
  String get fileContainsErrors;

  /// No description provided for @savedAsMarkdownSuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved as Markdown'**
  String get savedAsMarkdownSuccess;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @securityCode.
  ///
  /// In en, this message translates to:
  /// **'Security Code'**
  String get securityCode;

  /// No description provided for @encryptionUsed.
  ///
  /// In en, this message translates to:
  /// **'Encryption Used'**
  String get encryptionUsed;

  /// No description provided for @cannotReadWithoutKey.
  ///
  /// In en, this message translates to:
  /// **'Cannot be read without your device\'s encryption key.'**
  String get cannotReadWithoutKey;

  /// No description provided for @uninstallWarning.
  ///
  /// In en, this message translates to:
  /// **'If you uninstall the app, the encryption key will be lost permanently.'**
  String get uninstallWarning;

  /// No description provided for @clearDataWarning.
  ///
  /// In en, this message translates to:
  /// **'If you clear app data, the encryption key will be lost permanently.'**
  String get clearDataWarning;

  /// No description provided for @backupUnencryptedAdvice.
  ///
  /// In en, this message translates to:
  /// **'Keep a backup of your important notes in unencrypted format (unlock first).'**
  String get backupUnencryptedAdvice;

  /// No description provided for @encryptionRiskWarning.
  ///
  /// In en, this message translates to:
  /// **'Encryption provides security but increases the risk of data loss if the key is lost.'**
  String get encryptionRiskWarning;

  /// No description provided for @biometricError.
  ///
  /// In en, this message translates to:
  /// **'Biometric check error'**
  String get biometricError;

  /// No description provided for @authenticateWithBiometric.
  ///
  /// In en, this message translates to:
  /// **'Authenticate using biometric or device password'**
  String get authenticateWithBiometric;

  /// No description provided for @pleaseAuthenticateToOpen.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to open the note'**
  String get pleaseAuthenticateToOpen;

  /// No description provided for @authenticationError.
  ///
  /// In en, this message translates to:
  /// **'Authentication error'**
  String get authenticationError;

  /// No description provided for @invalidSecurityCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid security code'**
  String get invalidSecurityCode;

  /// No description provided for @wontTransferForSecurity.
  ///
  /// In en, this message translates to:
  /// **'Won\'t be transferred for security.'**
  String get wontTransferForSecurity;

  /// No description provided for @openVaultTab.
  ///
  /// In en, this message translates to:
  /// **'Open vault tab.'**
  String get openVaultTab;

  /// No description provided for @swipeRightToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Swipe right on note → \"Unlock\".'**
  String get swipeRightToUnlock;

  /// No description provided for @chooseDefaultColor.
  ///
  /// In en, this message translates to:
  /// **'Choose Default Color'**
  String get chooseDefaultColor;

  /// No description provided for @hideContentInBackground.
  ///
  /// In en, this message translates to:
  /// **'Hide Content in Background'**
  String get hideContentInBackground;

  /// No description provided for @applyBlurEffect.
  ///
  /// In en, this message translates to:
  /// **'Apply blur effect in app list'**
  String get applyBlurEffect;

  /// No description provided for @restoreFromBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get restoreFromBackup;

  /// No description provided for @saveAsJsonFile.
  ///
  /// In en, this message translates to:
  /// **'Save as JSON file'**
  String get saveAsJsonFile;

  /// No description provided for @chooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose Theme'**
  String get chooseTheme;

  /// No description provided for @saveToFolder.
  ///
  /// In en, this message translates to:
  /// **'Save to Folder'**
  String get saveToFolder;

  /// No description provided for @importantBackupWarning.
  ///
  /// In en, this message translates to:
  /// **'Important Warning - Encrypted Notes Backup'**
  String get importantBackupWarning;

  /// No description provided for @lockedNotesCount.
  ///
  /// In en, this message translates to:
  /// **'You have {count} locked and encrypted notes.'**
  String lockedNotesCount(int count);

  /// No description provided for @noteType.
  ///
  /// In en, this message translates to:
  /// **'Note Type'**
  String get noteType;

  /// No description provided for @noteStatus.
  ///
  /// In en, this message translates to:
  /// **'Note Status'**
  String get noteStatus;

  /// No description provided for @noStartFresh.
  ///
  /// In en, this message translates to:
  /// **'No, Start Fresh'**
  String get noStartFresh;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @editor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get editor;

  /// No description provided for @noteColors.
  ///
  /// In en, this message translates to:
  /// **'Note Colors'**
  String get noteColors;

  /// No description provided for @cardShineEffect.
  ///
  /// In en, this message translates to:
  /// **'Card Shine Effect'**
  String get cardShineEffect;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @appLock.
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get appLock;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @localNetworkTransfer.
  ///
  /// In en, this message translates to:
  /// **'Local network transfer'**
  String get localNetworkTransfer;

  /// No description provided for @exportDatabase.
  ///
  /// In en, this message translates to:
  /// **'Export database'**
  String get exportDatabase;

  /// No description provided for @exportJson.
  ///
  /// In en, this message translates to:
  /// **'Export JSON'**
  String get exportJson;

  /// No description provided for @importJson.
  ///
  /// In en, this message translates to:
  /// **'Import JSON'**
  String get importJson;

  /// No description provided for @restoreFromJson.
  ///
  /// In en, this message translates to:
  /// **'Restore from JSON'**
  String get restoreFromJson;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactUs;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutApp;

  /// No description provided for @diagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get diagnostics;

  /// No description provided for @developersOnly.
  ///
  /// In en, this message translates to:
  /// **'Developers only'**
  String get developersOnly;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer'**
  String get disclaimer;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @merge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get merge;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @cleared.
  ///
  /// In en, this message translates to:
  /// **'Cleared'**
  String get cleared;

  /// No description provided for @errorLog.
  ///
  /// In en, this message translates to:
  /// **'Error Log'**
  String get errorLog;

  /// No description provided for @showIntroAgain.
  ///
  /// In en, this message translates to:
  /// **'Show Intro Again'**
  String get showIntroAgain;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @restoreSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Restore Successful'**
  String get restoreSuccessful;

  /// No description provided for @mergedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Merged successfully'**
  String get mergedSuccessfully;

  /// No description provided for @createNote.
  ///
  /// In en, this message translates to:
  /// **'Create Note'**
  String get createNote;

  /// No description provided for @startSending.
  ///
  /// In en, this message translates to:
  /// **'Start Sending'**
  String get startSending;

  /// No description provided for @manualEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual Entry'**
  String get manualEntry;

  /// No description provided for @dataConflict.
  ///
  /// In en, this message translates to:
  /// **'Data Conflict'**
  String get dataConflict;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @receive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receive;

  /// No description provided for @oldPhone.
  ///
  /// In en, this message translates to:
  /// **'Old Phone'**
  String get oldPhone;

  /// No description provided for @noNotesToShare.
  ///
  /// In en, this message translates to:
  /// **'No notes to share'**
  String get noNotesToShare;

  /// No description provided for @createNoteFirst.
  ///
  /// In en, this message translates to:
  /// **'Create a note first to enable sharing'**
  String get createNoteFirst;

  /// No description provided for @tapButtonToShare.
  ///
  /// In en, this message translates to:
  /// **'Tap the button to start sharing your notes'**
  String get tapButtonToShare;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQrCode;

  /// No description provided for @newPhone.
  ///
  /// In en, this message translates to:
  /// **'New Phone'**
  String get newPhone;

  /// No description provided for @chooseConnectionMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose connection method'**
  String get chooseConnectionMethod;

  /// No description provided for @viewTransferPolicy.
  ///
  /// In en, this message translates to:
  /// **'View Transfer Policy for Locked Notes'**
  String get viewTransferPolicy;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsavedChanges;

  /// No description provided for @unsavedChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. What would you like to do?'**
  String get unsavedChangesMessage;

  /// No description provided for @saveAndExit.
  ///
  /// In en, this message translates to:
  /// **'Save & Exit'**
  String get saveAndExit;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardChanges;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @tourPage1Title.
  ///
  /// In en, this message translates to:
  /// **'Note Types'**
  String get tourPage1Title;

  /// No description provided for @tourPage1Desc.
  ///
  /// In en, this message translates to:
  /// **'Choose the right type for your needs'**
  String get tourPage1Desc;

  /// No description provided for @tourPage2Title.
  ///
  /// In en, this message translates to:
  /// **'Smart Calculations'**
  String get tourPage2Title;

  /// No description provided for @tourPage2Desc.
  ///
  /// In en, this message translates to:
  /// **'Write math expression and press = to see result'**
  String get tourPage2Desc;

  /// No description provided for @tourPage3Title.
  ///
  /// In en, this message translates to:
  /// **'Smart Dates'**
  String get tourPage3Title;

  /// No description provided for @tourPage3Desc.
  ///
  /// In en, this message translates to:
  /// **'Type date keywords and they convert automatically'**
  String get tourPage3Desc;

  /// No description provided for @tourPage4Title.
  ///
  /// In en, this message translates to:
  /// **'Secure Vault'**
  String get tourPage4Title;

  /// No description provided for @tourPage4Desc.
  ///
  /// In en, this message translates to:
  /// **'Lock sensitive notes with strong encryption'**
  String get tourPage4Desc;

  /// No description provided for @tourPage5Title.
  ///
  /// In en, this message translates to:
  /// **'Transfer & Backup'**
  String get tourPage5Title;

  /// No description provided for @tourPage5Desc.
  ///
  /// In en, this message translates to:
  /// **'Transfer your notes between devices easily'**
  String get tourPage5Desc;

  /// No description provided for @tourPage6Title.
  ///
  /// In en, this message translates to:
  /// **'Customization'**
  String get tourPage6Title;

  /// No description provided for @tourPage6Desc.
  ///
  /// In en, this message translates to:
  /// **'Customize your experience as you like'**
  String get tourPage6Desc;

  /// No description provided for @startNow.
  ///
  /// In en, this message translates to:
  /// **'Start Now'**
  String get startNow;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @haveSavedNotes.
  ///
  /// In en, this message translates to:
  /// **'Have saved notes?'**
  String get haveSavedNotes;

  /// No description provided for @transferFromOldPhone.
  ///
  /// In en, this message translates to:
  /// **'Transfer from your old phone now'**
  String get transferFromOldPhone;

  /// No description provided for @yesRestoreNow.
  ///
  /// In en, this message translates to:
  /// **'Yes, Restore Now'**
  String get yesRestoreNow;

  /// No description provided for @simpleNoteMenu.
  ///
  /// In en, this message translates to:
  /// **'Simple Note'**
  String get simpleNoteMenu;

  /// No description provided for @richNoteMenu.
  ///
  /// In en, this message translates to:
  /// **'Rich Note'**
  String get richNoteMenu;

  /// No description provided for @codeEditorMenu.
  ///
  /// In en, this message translates to:
  /// **'Code Editor'**
  String get codeEditorMenu;

  /// No description provided for @checklistMenu.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get checklistMenu;

  /// No description provided for @attachDeviceInfo.
  ///
  /// In en, this message translates to:
  /// **'Attach Device Information'**
  String get attachDeviceInfo;

  /// No description provided for @helpsDiagnose.
  ///
  /// In en, this message translates to:
  /// **'Helps us diagnose the issue'**
  String get helpsDiagnose;

  /// No description provided for @canRemoveFromEmail.
  ///
  /// In en, this message translates to:
  /// **'You can remove it from the email before sending'**
  String get canRemoveFromEmail;

  /// No description provided for @privacyAndData.
  ///
  /// In en, this message translates to:
  /// **'Privacy and Data'**
  String get privacyAndData;

  /// No description provided for @privacyDescription.
  ///
  /// In en, this message translates to:
  /// **'We respect your privacy. Your data will only be used to improve technical support.'**
  String get privacyDescription;

  /// No description provided for @readPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Read Privacy Policy'**
  String get readPrivacyPolicy;

  /// No description provided for @agreeToPolicy.
  ///
  /// In en, this message translates to:
  /// **'I agree to the privacy policy'**
  String get agreeToPolicy;

  String get googleDriveSync;
  String get account;
  String get notSignedIn;
  String get signedInAs;
  String get signOut;
  String get syncStatus;
  String get lastSync;
  String get never;
  String get syncActions;
  String get uploadDatabase;
  String get uploadDatabaseDesc;
  String get downloadDatabase;
  String get downloadDatabaseDesc;
  String get autoSync;
  String get autoSyncDesc;
  String get syncHistory;
  String get noSyncHistory;
  String get uploaded;
  String get downloaded;
  String get failed;
  String get uploadSuccess;
  String get uploadFailed;
  String get downloadSuccess;
  String get downloadFailed;
  String get signOutSuccess;
  String get signOutFailed;
  String get confirmDownload;
  String get confirmDownloadMessage;
  String get download;
  String get upload;
  String get syncing;
  String get pleaseSignIn;
  String get justNow;
  String get lockDelay;
  String get lockDelayDesc;
  String get selectLockDelay;
  String get seconds30;
  String get minutes2;
  String get minutes3;
  String get minutes5;
  String get immediate;
  String get supportTerms;
  String get supportTermsDesc;
  String get supportSharedData;
  String get supportSharedDataDesc;
  String get supportReason;
  String get supportReasonDesc;
  String get privacyUsagePolicy;
  String get supportMessageSent;
  String get supportMessageFailed;
  String get supportCategory;
  String get supportSubject;
  String get supportMessage;
  String get checklistTitle;
  String get checklistItemHint;
  String get sort;
  String get checklist;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
