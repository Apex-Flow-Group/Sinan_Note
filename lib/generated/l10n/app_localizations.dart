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
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
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

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

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

  /// No description provided for @fontFamily.
  ///
  /// In en, this message translates to:
  /// **'Font Style'**
  String get fontFamily;

  /// No description provided for @fontFamilySystem.
  ///
  /// In en, this message translates to:
  /// **'System Font'**
  String get fontFamilySystem;

  /// No description provided for @fontFamilySystemDesc.
  ///
  /// In en, this message translates to:
  /// **'Device default font'**
  String get fontFamilySystemDesc;

  /// No description provided for @fontFamilyCairoDesc.
  ///
  /// In en, this message translates to:
  /// **'Modern Arabic & Latin font'**
  String get fontFamilyCairoDesc;

  /// No description provided for @fontFamilyTajawalDesc.
  ///
  /// In en, this message translates to:
  /// **'Light & contemporary Arabic font'**
  String get fontFamilyTajawalDesc;

  /// No description provided for @fontFamilyVazirmatnDesc.
  ///
  /// In en, this message translates to:
  /// **'Elegant Persian-Arabic balanced font'**
  String get fontFamilyVazirmatnDesc;

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

  /// No description provided for @checklistNote.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get checklistNote;

  /// No description provided for @checklistNoteDesc.
  ///
  /// In en, this message translates to:
  /// **'Checkable task list'**
  String get checklistNoteDesc;

  /// No description provided for @codeNote.
  ///
  /// In en, this message translates to:
  /// **'Code Editor'**
  String get codeNote;

  /// No description provided for @codeNoteDesc.
  ///
  /// In en, this message translates to:
  /// **'Code with syntax highlighting'**
  String get codeNoteDesc;

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
  /// **'Encrypted content'**
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
  /// **'Delete'**
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

  /// No description provided for @added.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get added;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview changes'**
  String get preview;

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

  /// No description provided for @hideProFromHome.
  ///
  /// In en, this message translates to:
  /// **'Hide from Home'**
  String get hideProFromHome;

  /// No description provided for @hiddenFromHomeDesc.
  ///
  /// In en, this message translates to:
  /// **'Visible in category only — won\'t be deleted'**
  String get hiddenFromHomeDesc;

  /// No description provided for @visibleInHomeDesc.
  ///
  /// In en, this message translates to:
  /// **'Visible in Home and category'**
  String get visibleInHomeDesc;

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
  /// **'Date'**
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

  /// No description provided for @noCategory.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get noCategory;

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

  /// No description provided for @pressBackToExit.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get pressBackToExit;

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

  /// No description provided for @vaultFullyEncrypted.
  ///
  /// In en, this message translates to:
  /// **'A fully encrypted space accessible only with your biometric.'**
  String get vaultFullyEncrypted;

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
  /// **'Restore from Backup'**
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

  /// No description provided for @heroAnimation.
  ///
  /// In en, this message translates to:
  /// **'Hero Animation'**
  String get heroAnimation;

  /// No description provided for @editorSettings.
  ///
  /// In en, this message translates to:
  /// **'Editor Settings'**
  String get editorSettings;

  /// No description provided for @doubleTapToEdit.
  ///
  /// In en, this message translates to:
  /// **'Double Tap to Edit'**
  String get doubleTapToEdit;

  /// No description provided for @doubleTapToEditDesc.
  ///
  /// In en, this message translates to:
  /// **'Double tap on note to open editor'**
  String get doubleTapToEditDesc;

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

  /// No description provided for @otherExtension.
  ///
  /// In en, this message translates to:
  /// **'Other (custom extension)'**
  String get otherExtension;

  /// No description provided for @tourPage1Title.
  ///
  /// In en, this message translates to:
  /// **'Note Types'**
  String get tourPage1Title;

  /// No description provided for @tourPage1Desc.
  ///
  /// In en, this message translates to:
  /// **'Five types of notes to suit every need'**
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
  /// **'Cloud Sync'**
  String get tourPage5Title;

  /// No description provided for @tourPage5Desc.
  ///
  /// In en, this message translates to:
  /// **'Sync your notes with Google Drive automatically'**
  String get tourPage5Desc;

  /// No description provided for @tourPage6Title.
  ///
  /// In en, this message translates to:
  /// **'Customization & More'**
  String get tourPage6Title;

  /// No description provided for @tourPage6Desc.
  ///
  /// In en, this message translates to:
  /// **'Powerful tools to personalize your experience'**
  String get tourPage6Desc;

  /// No description provided for @tourRichNote.
  ///
  /// In en, this message translates to:
  /// **'Rich Note: Formatted text with styling'**
  String get tourRichNote;

  /// No description provided for @tourGoogleDriveSync.
  ///
  /// In en, this message translates to:
  /// **'Automatic sync with Google Drive'**
  String get tourGoogleDriveSync;

  /// No description provided for @tourSmartMerge.
  ///
  /// In en, this message translates to:
  /// **'Smart merge when conflicts arise'**
  String get tourSmartMerge;

  /// No description provided for @tourCloudBackup.
  ///
  /// In en, this message translates to:
  /// **'Secure cloud backup'**
  String get tourCloudBackup;

  /// No description provided for @tourVersionHistory.
  ///
  /// In en, this message translates to:
  /// **'Version history for your notes'**
  String get tourVersionHistory;

  /// No description provided for @tourHomeWidget.
  ///
  /// In en, this message translates to:
  /// **'Home screen widget for quick access'**
  String get tourHomeWidget;

  /// No description provided for @tourNoteConversion.
  ///
  /// In en, this message translates to:
  /// **'Convert between note types easily'**
  String get tourNoteConversion;

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

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @preparingTransfer.
  ///
  /// In en, this message translates to:
  /// **'Preparing transfer...'**
  String get preparingTransfer;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server Error'**
  String get serverError;

  /// No description provided for @ipAddress.
  ///
  /// In en, this message translates to:
  /// **'IP Address'**
  String get ipAddress;

  /// No description provided for @keepScreenOpen.
  ///
  /// In en, this message translates to:
  /// **'Keep this screen open until transfer completes'**
  String get keepScreenOpen;

  /// No description provided for @youHave.
  ///
  /// In en, this message translates to:
  /// **'You have'**
  String get youHave;

  /// No description provided for @lockedNotes.
  ///
  /// In en, this message translates to:
  /// **'locked note(s)'**
  String get lockedNotes;

  /// No description provided for @willNotBeTransferred.
  ///
  /// In en, this message translates to:
  /// **'They won\'t be transferred for security'**
  String get willNotBeTransferred;

  /// No description provided for @onlyRegularNotes.
  ///
  /// In en, this message translates to:
  /// **'Only regular notes will be transferred'**
  String get onlyRegularNotes;

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

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'(Optional)'**
  String get optional;

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

  /// No description provided for @googleDriveSync.
  ///
  /// In en, this message translates to:
  /// **'Google Drive Sync'**
  String get googleDriveSync;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @notSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get notSignedIn;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as'**
  String get signedInAs;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @syncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync Status'**
  String get syncStatus;

  /// No description provided for @lastSync.
  ///
  /// In en, this message translates to:
  /// **'Last Sync'**
  String get lastSync;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @syncActions.
  ///
  /// In en, this message translates to:
  /// **'Sync Actions'**
  String get syncActions;

  /// No description provided for @uploadDatabase.
  ///
  /// In en, this message translates to:
  /// **'Upload Database'**
  String get uploadDatabase;

  /// No description provided for @uploadDatabaseDesc.
  ///
  /// In en, this message translates to:
  /// **'Upload all notes to Google Drive'**
  String get uploadDatabaseDesc;

  /// No description provided for @downloadDatabase.
  ///
  /// In en, this message translates to:
  /// **'Download Database'**
  String get downloadDatabase;

  /// No description provided for @downloadDatabaseDesc.
  ///
  /// In en, this message translates to:
  /// **'Restore notes from Google Drive'**
  String get downloadDatabaseDesc;

  /// No description provided for @autoSync.
  ///
  /// In en, this message translates to:
  /// **'Auto Sync'**
  String get autoSync;

  /// No description provided for @autoSyncDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically sync when app opens'**
  String get autoSyncDesc;

  /// No description provided for @syncHistory.
  ///
  /// In en, this message translates to:
  /// **'Sync History'**
  String get syncHistory;

  /// No description provided for @noSyncHistory.
  ///
  /// In en, this message translates to:
  /// **'No sync history'**
  String get noSyncHistory;

  /// No description provided for @uploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploaded;

  /// No description provided for @downloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloaded;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @uploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Database uploaded successfully'**
  String get uploadSuccess;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload database'**
  String get uploadFailed;

  /// No description provided for @downloadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Database downloaded successfully'**
  String get downloadSuccess;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download database'**
  String get downloadFailed;

  /// No description provided for @signOutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Signed out successfully'**
  String get signOutSuccess;

  /// No description provided for @signOutFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to sign out'**
  String get signOutFailed;

  /// No description provided for @confirmDownload.
  ///
  /// In en, this message translates to:
  /// **'Confirm Download'**
  String get confirmDownload;

  /// No description provided for @confirmDownloadMessage.
  ///
  /// In en, this message translates to:
  /// **'All current notes will be replaced with notes from Google Drive. Are you sure?'**
  String get confirmDownloadMessage;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get syncing;

  /// No description provided for @pleaseSignIn.
  ///
  /// In en, this message translates to:
  /// **'Please sign in first'**
  String get pleaseSignIn;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @lockDelay.
  ///
  /// In en, this message translates to:
  /// **'Lock Delay'**
  String get lockDelay;

  /// No description provided for @lockDelayDesc.
  ///
  /// In en, this message translates to:
  /// **'Delay app lock after going to background'**
  String get lockDelayDesc;

  /// No description provided for @selectLockDelay.
  ///
  /// In en, this message translates to:
  /// **'Select Lock Delay'**
  String get selectLockDelay;

  /// No description provided for @seconds30.
  ///
  /// In en, this message translates to:
  /// **'30 seconds'**
  String get seconds30;

  /// No description provided for @minutes2.
  ///
  /// In en, this message translates to:
  /// **'2 minutes'**
  String get minutes2;

  /// No description provided for @minutes3.
  ///
  /// In en, this message translates to:
  /// **'3 minutes'**
  String get minutes3;

  /// No description provided for @minutes5.
  ///
  /// In en, this message translates to:
  /// **'5 minutes'**
  String get minutes5;

  /// No description provided for @immediate.
  ///
  /// In en, this message translates to:
  /// **'Immediate'**
  String get immediate;

  /// No description provided for @supportTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get supportTerms;

  /// No description provided for @supportTermsDesc.
  ///
  /// In en, this message translates to:
  /// **'By sending this message, you agree to:\n• Share only the information you enter\n• Use your message to improve technical support\n• Comply with our privacy policy'**
  String get supportTermsDesc;

  /// No description provided for @supportSharedData.
  ///
  /// In en, this message translates to:
  /// **'Shared Data'**
  String get supportSharedData;

  /// No description provided for @supportSharedDataDesc.
  ///
  /// In en, this message translates to:
  /// **'Only the following will be sent:\n• Your name\n• Issue category\n• Your message\n\nNo device information will be collected automatically.'**
  String get supportSharedDataDesc;

  /// No description provided for @supportReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get supportReason;

  /// No description provided for @supportReasonDesc.
  ///
  /// In en, this message translates to:
  /// **'We use your message to:\n• Respond to your inquiries\n• Improve app quality\n• Provide better support'**
  String get supportReasonDesc;

  /// No description provided for @privacyUsagePolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Usage Policy'**
  String get privacyUsagePolicy;

  /// No description provided for @supportMessageSent.
  ///
  /// In en, this message translates to:
  /// **'Message sent successfully'**
  String get supportMessageSent;

  /// No description provided for @supportMessageFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message'**
  String get supportMessageFailed;

  /// No description provided for @supportCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get supportCategory;

  /// No description provided for @supportSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get supportSubject;

  /// No description provided for @supportMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get supportMessage;

  /// No description provided for @checklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Checklist Title'**
  String get checklistTitle;

  /// No description provided for @checklistItemHint.
  ///
  /// In en, this message translates to:
  /// **'Task...'**
  String get checklistItemHint;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// No description provided for @itemDeleted.
  ///
  /// In en, this message translates to:
  /// **'Item deleted'**
  String get itemDeleted;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @checklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get checklist;

  /// No description provided for @checklistMenu.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get checklistMenu;

  /// No description provided for @codeEditorMenu.
  ///
  /// In en, this message translates to:
  /// **'Code Editor'**
  String get codeEditorMenu;

  /// No description provided for @richNoteMenu.
  ///
  /// In en, this message translates to:
  /// **'Rich Note'**
  String get richNoteMenu;

  /// No description provided for @simpleNoteMenu.
  ///
  /// In en, this message translates to:
  /// **'Simple Note'**
  String get simpleNoteMenu;

  /// No description provided for @restoredToArchive.
  ///
  /// In en, this message translates to:
  /// **'Note restored to Archive'**
  String get restoredToArchive;

  /// No description provided for @restoredToHome.
  ///
  /// In en, this message translates to:
  /// **'Note restored to Home'**
  String get restoredToHome;

  /// No description provided for @notesRestoredMixed.
  ///
  /// In en, this message translates to:
  /// **'Notes restored'**
  String get notesRestoredMixed;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Your sharp and reliable note-taking companion'**
  String get appTagline;

  /// No description provided for @appTaglineAr.
  ///
  /// In en, this message translates to:
  /// **'رفيقك الحاد والموثوق للتدوين'**
  String get appTaglineAr;

  /// No description provided for @officialVersion.
  ///
  /// In en, this message translates to:
  /// **'Official Version - Google Play'**
  String get officialVersion;

  /// No description provided for @sinanAiNet.
  ///
  /// In en, this message translates to:
  /// **'SinanAi.net — Innovative Apps'**
  String get sinanAiNet;

  /// No description provided for @importantLinks.
  ///
  /// In en, this message translates to:
  /// **'Important Links'**
  String get importantLinks;

  /// No description provided for @appPageGooglePlay.
  ///
  /// In en, this message translates to:
  /// **'App Page on Google Play'**
  String get appPageGooglePlay;

  /// No description provided for @githubRepository.
  ///
  /// In en, this message translates to:
  /// **'GitHub Repository'**
  String get githubRepository;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @legalInfo.
  ///
  /// In en, this message translates to:
  /// **'Legal Information'**
  String get legalInfo;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'Copyright'**
  String get copyright;

  /// No description provided for @copyrightText.
  ///
  /// In en, this message translates to:
  /// **'© 2025 Apex Flow Group. All rights reserved.\nPersonal use permitted. Commercial use requires permission.'**
  String get copyrightText;

  /// No description provided for @disclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer'**
  String get disclaimerTitle;

  /// No description provided for @disclaimerText.
  ///
  /// In en, this message translates to:
  /// **'This app is provided \"as is\" without any warranties. Apex Flow Group is not responsible for any losses or damages resulting from the use of the app.'**
  String get disclaimerText;

  /// No description provided for @officialVersionTitle.
  ///
  /// In en, this message translates to:
  /// **'Official Version'**
  String get officialVersionTitle;

  /// No description provided for @officialVersionText.
  ///
  /// In en, this message translates to:
  /// **'This is the official certified version of Sinan Note available on Google Play Store. Beware of fake or unofficial copies.'**
  String get officialVersionText;

  /// No description provided for @librariesUsed.
  ///
  /// In en, this message translates to:
  /// **'Libraries Used'**
  String get librariesUsed;

  /// No description provided for @flutterFramework.
  ///
  /// In en, this message translates to:
  /// **'Framework from Google'**
  String get flutterFramework;

  /// No description provided for @dartLanguage.
  ///
  /// In en, this message translates to:
  /// **'Programming Language'**
  String get dartLanguage;

  /// No description provided for @providerStateManagement.
  ///
  /// In en, this message translates to:
  /// **'State Management'**
  String get providerStateManagement;

  /// No description provided for @localDatabase.
  ///
  /// In en, this message translates to:
  /// **'Local Database'**
  String get localDatabase;

  /// No description provided for @officialGooglePlay.
  ///
  /// In en, this message translates to:
  /// **'Official certified version from Google Play Store\nAutomatic updates and guaranteed security'**
  String get officialGooglePlay;

  /// No description provided for @fdroidVersion.
  ///
  /// In en, this message translates to:
  /// **'F-Droid Version - Open Source\nWiFi sharing feature available'**
  String get fdroidVersion;

  /// No description provided for @madeWithLove.
  ///
  /// In en, this message translates to:
  /// **'Made with'**
  String get madeWithLove;

  /// No description provided for @inArabWorld.
  ///
  /// In en, this message translates to:
  /// **'in the Arab World'**
  String get inArabWorld;

  /// No description provided for @contactEmail.
  ///
  /// In en, this message translates to:
  /// **'contact.apex.flow@gmail.com'**
  String get contactEmail;

  /// No description provided for @agreeToTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms of Service'**
  String get agreeToTerms;

  /// No description provided for @widgetPinned.
  ///
  /// In en, this message translates to:
  /// **'Widget pinned:'**
  String get widgetPinned;

  /// No description provided for @pinToWidget.
  ///
  /// In en, this message translates to:
  /// **'Pin to Widget'**
  String get pinToWidget;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @permissionsRequired.
  ///
  /// In en, this message translates to:
  /// **'Permissions Required'**
  String get permissionsRequired;

  /// No description provided for @reminderPermissionsDesc.
  ///
  /// In en, this message translates to:
  /// **'To use reminders, this app needs permission to:\n• Send notifications\n• Schedule exact alarms\n\nThese permissions ensure your reminders work reliably.'**
  String get reminderPermissionsDesc;

  /// No description provided for @grantPermissions.
  ///
  /// In en, this message translates to:
  /// **'Grant Permissions'**
  String get grantPermissions;

  /// No description provided for @permissionsDenied.
  ///
  /// In en, this message translates to:
  /// **'Permissions denied. Reminders may not work.'**
  String get permissionsDenied;

  /// No description provided for @removeReminder.
  ///
  /// In en, this message translates to:
  /// **'Remove Reminder'**
  String get removeReminder;

  /// No description provided for @reminderRemoved.
  ///
  /// In en, this message translates to:
  /// **'Reminder removed'**
  String get reminderRemoved;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @doesNotRepeat.
  ///
  /// In en, this message translates to:
  /// **'Does not repeat'**
  String get doesNotRepeat;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @nextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next Week'**
  String get nextWeek;

  /// No description provided for @notesPinned.
  ///
  /// In en, this message translates to:
  /// **'note(s) pinned'**
  String get notesPinned;

  /// No description provided for @notesArchived.
  ///
  /// In en, this message translates to:
  /// **'note(s) archived'**
  String get notesArchived;

  /// No description provided for @unableToDetectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Unable to detect language'**
  String get unableToDetectLanguage;

  /// No description provided for @executingCode.
  ///
  /// In en, this message translates to:
  /// **'Executing code...'**
  String get executingCode;

  /// No description provided for @databaseError.
  ///
  /// In en, this message translates to:
  /// **'Database error'**
  String get databaseError;

  /// No description provided for @confirmRestore.
  ///
  /// In en, this message translates to:
  /// **'Confirm Restore'**
  String get confirmRestore;

  /// No description provided for @restoreWarning.
  ///
  /// In en, this message translates to:
  /// **'Current version will be saved automatically before restore. Continue?'**
  String get restoreWarning;

  /// No description provided for @setupVault.
  ///
  /// In en, this message translates to:
  /// **'Setup Vault'**
  String get setupVault;

  /// No description provided for @createPassword.
  ///
  /// In en, this message translates to:
  /// **'Create Password'**
  String get createPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @recoveryCode.
  ///
  /// In en, this message translates to:
  /// **'Recovery Code'**
  String get recoveryCode;

  /// No description provided for @recoveryCodeWarning.
  ///
  /// In en, this message translates to:
  /// **'This is your ONLY way to recover access if you forget your password.'**
  String get recoveryCodeWarning;

  /// No description provided for @recoveryCodeOwnership.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Important: This code is YOUR personal property. We do NOT have access to it and CANNOT recover it for you.'**
  String get recoveryCodeOwnership;

  /// No description provided for @recoveryCodeLoss.
  ///
  /// In en, this message translates to:
  /// **'If you lose this code AND forget your password, your locked notes will be permanently inaccessible.'**
  String get recoveryCodeLoss;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy Code'**
  String get copyCode;

  /// No description provided for @saveAsPDF.
  ///
  /// In en, this message translates to:
  /// **'Save as PDF'**
  String get saveAsPDF;

  /// No description provided for @saveToGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Save to Google Drive'**
  String get saveToGoogleDrive;

  /// No description provided for @iHaveSavedCode.
  ///
  /// In en, this message translates to:
  /// **'I have saved the recovery code in a safe place'**
  String get iHaveSavedCode;

  /// No description provided for @enableBiometric.
  ///
  /// In en, this message translates to:
  /// **'Enable Biometric Quick Access'**
  String get enableBiometric;

  /// No description provided for @biometricOptional.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint/face to unlock vault quickly (optional)'**
  String get biometricOptional;

  /// No description provided for @enableBiometricAccess.
  ///
  /// In en, this message translates to:
  /// **'Enable Biometric Access'**
  String get enableBiometricAccess;

  /// No description provided for @skipBiometric.
  ///
  /// In en, this message translates to:
  /// **'Skip for Now'**
  String get skipBiometric;

  /// No description provided for @biometricLoginHint.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint or face as an alternative to password'**
  String get biometricLoginHint;

  /// No description provided for @orText.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orText;

  /// No description provided for @vaultSetupComplete.
  ///
  /// In en, this message translates to:
  /// **'Vault Setup Complete'**
  String get vaultSetupComplete;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Recovery code copied to clipboard'**
  String get codeCopied;

  /// No description provided for @mustSaveCode.
  ///
  /// In en, this message translates to:
  /// **'Please confirm you have saved the recovery code'**
  String get mustSaveCode;

  /// No description provided for @enterVaultPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter Vault Password'**
  String get enterVaultPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @recoverVault.
  ///
  /// In en, this message translates to:
  /// **'Recover Vault'**
  String get recoverVault;

  /// No description provided for @enterRecoveryCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Recovery Code'**
  String get enterRecoveryCode;

  /// No description provided for @invalidRecoveryCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid recovery code'**
  String get invalidRecoveryCode;

  /// No description provided for @vaultRecovered.
  ///
  /// In en, this message translates to:
  /// **'Vault recovered successfully'**
  String get vaultRecovered;

  /// No description provided for @setNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get setNewPassword;

  /// No description provided for @googleDriveSyncTerms.
  ///
  /// In en, this message translates to:
  /// **'Google Drive Sync Terms'**
  String get googleDriveSyncTerms;

  /// No description provided for @syncTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Google Drive Sync Agreement'**
  String get syncTermsTitle;

  /// No description provided for @syncTermsRegularNotes.
  ///
  /// In en, this message translates to:
  /// **'Regular Notes: Synced without encryption for easy access across devices'**
  String get syncTermsRegularNotes;

  /// No description provided for @syncTermsVaultNotes.
  ///
  /// In en, this message translates to:
  /// **'Vault Notes: Remain fully encrypted with device-specific keys'**
  String get syncTermsVaultNotes;

  /// No description provided for @syncTermsGoogleAccess.
  ///
  /// In en, this message translates to:
  /// **'Privacy Notice'**
  String get syncTermsGoogleAccess;

  /// No description provided for @syncTermsRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Regular notes are stored on Google Drive and may be accessible to Google as per their privacy policy. For sensitive information, we recommend using the Vault feature.'**
  String get syncTermsRecommendation;

  /// No description provided for @syncTermsGoogleTOS.
  ///
  /// In en, this message translates to:
  /// **'By enabling sync, you agree to Google Drive\'s Terms of Service and Privacy Policy.'**
  String get syncTermsGoogleTOS;

  /// No description provided for @readPrivacyPolicyLink.
  ///
  /// In en, this message translates to:
  /// **'Read Privacy Policy'**
  String get readPrivacyPolicyLink;

  /// No description provided for @agreeAndEnable.
  ///
  /// In en, this message translates to:
  /// **'Agree & Enable'**
  String get agreeAndEnable;

  /// No description provided for @compressionEnabled.
  ///
  /// In en, this message translates to:
  /// **'ZIP compression enabled to save space'**
  String get compressionEnabled;

  /// No description provided for @vaultUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Vault Upgrade'**
  String get vaultUpgrade;

  /// No description provided for @vaultUpgradeInfo.
  ///
  /// In en, this message translates to:
  /// **'Your vault needs to be upgraded to the new secure system with recovery code support.'**
  String get vaultUpgradeInfo;

  /// No description provided for @oldPassword.
  ///
  /// In en, this message translates to:
  /// **'Old Password'**
  String get oldPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @migrating.
  ///
  /// In en, this message translates to:
  /// **'Migrating...'**
  String get migrating;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @incorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get incorrectPassword;

  /// No description provided for @syncWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Important Sync Warning'**
  String get syncWarningTitle;

  /// No description provided for @syncWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'Locked notes cannot be opened after restoring from Google Drive on another device!\n\nReason: Encryption keys are not uploaded to the cloud (to protect your privacy)\n\nSolution: Save this code or unlock notes before syncing'**
  String get syncWarningMessage;

  /// No description provided for @importantWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Important Warning'**
  String get importantWarning;

  /// No description provided for @recoveryCodeWarningFull.
  ///
  /// In en, this message translates to:
  /// **'• This code is YOUR personal property. We do NOT have access to it.\n• If you forget your password, use this code to recover access.\n• IMPORTANT: If you restore from Google Drive on another device, locked notes CANNOT be opened even with this code (encryption keys stay on your device only for privacy).\n• Solution: Unlock notes before syncing, or keep them on the same device.'**
  String get recoveryCodeWarningFull;

  /// No description provided for @vaultFoundInDrive.
  ///
  /// In en, this message translates to:
  /// **'☁️ Vault found in Google Drive'**
  String get vaultFoundInDrive;

  /// No description provided for @restoreVaultFromDrive.
  ///
  /// In en, this message translates to:
  /// **'Restore Vault from Drive'**
  String get restoreVaultFromDrive;

  /// No description provided for @importantInfo.
  ///
  /// In en, this message translates to:
  /// **'Important Information'**
  String get importantInfo;

  /// No description provided for @recoveryCodeInfo.
  ///
  /// In en, this message translates to:
  /// **'• Save this code securely - it\'s your backup key if you forget your password.\n\n• This code works only on this device. If you switch devices or restore from cloud backup, you\'ll need to unlock notes first.\n\n• Why? Encryption keys stay on your device for maximum privacy and security.\n\n• Tip: Before syncing to another device, unlock your notes or keep them on this device only.'**
  String get recoveryCodeInfo;

  /// No description provided for @uploadOptions.
  ///
  /// In en, this message translates to:
  /// **'Upload Options'**
  String get uploadOptions;

  /// No description provided for @uploadOptionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose what to upload to Google Drive:'**
  String get uploadOptionsDesc;

  /// No description provided for @uploadMasterKey.
  ///
  /// In en, this message translates to:
  /// **'Upload Master Encryption Key'**
  String get uploadMasterKey;

  /// No description provided for @uploadMasterKeyDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows opening locked notes on other devices. Less secure but more convenient.'**
  String get uploadMasterKeyDesc;

  /// No description provided for @uploadVault.
  ///
  /// In en, this message translates to:
  /// **'Upload Vault (Locked Notes)'**
  String get uploadVault;

  /// No description provided for @uploadVaultDesc.
  ///
  /// In en, this message translates to:
  /// **'Upload encrypted vault data. Only works if master key is also uploaded.'**
  String get uploadVaultDesc;

  /// No description provided for @uploadWarning.
  ///
  /// In en, this message translates to:
  /// **'Without master key: Locked notes cannot be opened on other devices even with recovery code.'**
  String get uploadWarning;

  /// No description provided for @syncConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync Conflict Detected'**
  String get syncConflictTitle;

  /// No description provided for @syncConflictDesc.
  ///
  /// In en, this message translates to:
  /// **'Different versions found. Choose how to proceed:'**
  String get syncConflictDesc;

  /// No description provided for @onDevice.
  ///
  /// In en, this message translates to:
  /// **'On Device'**
  String get onDevice;

  /// No description provided for @onDrive.
  ///
  /// In en, this message translates to:
  /// **'On Drive'**
  String get onDrive;

  /// No description provided for @notesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} notes'**
  String notesCount(int count);

  /// No description provided for @chooseAction.
  ///
  /// In en, this message translates to:
  /// **'Choose Action'**
  String get chooseAction;

  /// No description provided for @useDrive.
  ///
  /// In en, this message translates to:
  /// **'Use Drive Version'**
  String get useDrive;

  /// No description provided for @useDevice.
  ///
  /// In en, this message translates to:
  /// **'Use Device Version'**
  String get useDevice;

  /// No description provided for @smartMerge.
  ///
  /// In en, this message translates to:
  /// **'Smart Merge'**
  String get smartMerge;

  /// No description provided for @smartMergeDesc.
  ///
  /// In en, this message translates to:
  /// **'Combines both versions, keeping the most recent changes for each note'**
  String get smartMergeDesc;

  /// No description provided for @googleDriveVaultWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠️ The developer and Google are not responsible for your security key (Recovery Code).\n\n🔑 You must keep the key in a safe place.\n\n📥 When restoring from Google Drive, you will need to enter the key to unlock encrypted notes.'**
  String get googleDriveVaultWarning;

  /// No description provided for @dontShowAgain.
  ///
  /// In en, this message translates to:
  /// **'Don\'t show this again'**
  String get dontShowAgain;

  /// No description provided for @makeCopy.
  ///
  /// In en, this message translates to:
  /// **'Make a Copy'**
  String get makeCopy;

  /// No description provided for @saveAs.
  ///
  /// In en, this message translates to:
  /// **'Save As'**
  String get saveAs;

  /// No description provided for @noteCopied.
  ///
  /// In en, this message translates to:
  /// **'Note copied'**
  String get noteCopied;

  /// No description provided for @searchInArchive.
  ///
  /// In en, this message translates to:
  /// **'Search in Archive'**
  String get searchInArchive;

  /// No description provided for @searchInTrash.
  ///
  /// In en, this message translates to:
  /// **'Search in Trash'**
  String get searchInTrash;

  /// No description provided for @searchInVault.
  ///
  /// In en, this message translates to:
  /// **'Search in Vault'**
  String get searchInVault;

  /// No description provided for @errorOpeningNote.
  ///
  /// In en, this message translates to:
  /// **'Error opening note'**
  String get errorOpeningNote;

  /// No description provided for @convertTo.
  ///
  /// In en, this message translates to:
  /// **'Convert To'**
  String get convertTo;

  /// No description provided for @richText.
  ///
  /// In en, this message translates to:
  /// **'Rich Text'**
  String get richText;

  /// No description provided for @convertToChecklist.
  ///
  /// In en, this message translates to:
  /// **'Convert to Checklist'**
  String get convertToChecklist;

  /// No description provided for @convertToPlain.
  ///
  /// In en, this message translates to:
  /// **'Convert to Plain Text'**
  String get convertToPlain;

  /// No description provided for @convertConfirmChecklist.
  ///
  /// In en, this message translates to:
  /// **'Each line will become a checklist item. Continue?'**
  String get convertConfirmChecklist;

  /// No description provided for @convertConfirmPlain.
  ///
  /// In en, this message translates to:
  /// **'Checklist will become plain text. Continue?'**
  String get convertConfirmPlain;

  /// No description provided for @noteConverted.
  ///
  /// In en, this message translates to:
  /// **'Note converted successfully'**
  String get noteConverted;

  /// No description provided for @file.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @pullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh'**
  String get pullToRefresh;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pin;

  /// No description provided for @unpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpin;

  /// No description provided for @lock.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get lock;

  /// No description provided for @clipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Clipboard is empty or contains an image'**
  String get clipboardEmpty;

  /// No description provided for @clipboardTruncated.
  ///
  /// In en, this message translates to:
  /// **'Text was truncated (50,000 character limit)'**
  String get clipboardTruncated;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @allNotes.
  ///
  /// In en, this message translates to:
  /// **'All Notes'**
  String get allNotes;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get addCategory;

  /// No description provided for @categoryNameHint.
  ///
  /// In en, this message translates to:
  /// **'Category name...'**
  String get categoryNameHint;

  /// No description provided for @maxCategoriesReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum 20 categories reached'**
  String get maxCategoriesReached;

  /// No description provided for @renameCategory.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameCategory;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteCategory;

  /// No description provided for @catWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get catWork;

  /// No description provided for @catPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get catPersonal;

  /// No description provided for @catIdeas.
  ///
  /// In en, this message translates to:
  /// **'Ideas'**
  String get catIdeas;

  /// No description provided for @catTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get catTasks;

  /// No description provided for @tourPage8Title.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get tourPage8Title;

  /// No description provided for @tourPage8Desc.
  ///
  /// In en, this message translates to:
  /// **'Organize your notes into categories to find them quickly'**
  String get tourPage8Desc;

  /// No description provided for @tourCatCreate.
  ///
  /// In en, this message translates to:
  /// **'Create custom categories like Work, Personal, and Ideas'**
  String get tourCatCreate;

  /// No description provided for @tourCatFilter.
  ///
  /// In en, this message translates to:
  /// **'Tap a category to view only its notes'**
  String get tourCatFilter;

  /// No description provided for @tourCatEdit.
  ///
  /// In en, this message translates to:
  /// **'Rename or delete categories easily'**
  String get tourCatEdit;

  /// No description provided for @tourCatAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign a note to multiple categories at once'**
  String get tourCatAssign;

  /// No description provided for @driveSignIn.
  ///
  /// In en, this message translates to:
  /// **'Tap to sign in'**
  String get driveSignIn;

  /// No description provided for @driveSyncOn.
  ///
  /// In en, this message translates to:
  /// **'Sync is active'**
  String get driveSyncOn;

  /// No description provided for @driveSyncOff.
  ///
  /// In en, this message translates to:
  /// **'Sync is off'**
  String get driveSyncOff;

  /// No description provided for @selectNoteToViewHistory.
  ///
  /// In en, this message translates to:
  /// **'Select a note to view its history'**
  String get selectNoteToViewHistory;

  /// No description provided for @selectVersionToViewDiff.
  ///
  /// In en, this message translates to:
  /// **'Select a version to view changes'**
  String get selectVersionToViewDiff;

  /// No description provided for @selectNoteToViewHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a note from the list'**
  String get selectNoteToViewHistoryHint;

  /// No description provided for @resetVault.
  ///
  /// In en, this message translates to:
  /// **'Reset Vault Encryption'**
  String get resetVault;

  /// No description provided for @resetVaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Re-encrypt all notes with a new key'**
  String get resetVaultSubtitle;

  /// No description provided for @resetVaultWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Vault Encryption'**
  String get resetVaultWarningTitle;

  /// No description provided for @resetVaultWarningBody.
  ///
  /// In en, this message translates to:
  /// **'This will re-encrypt all your locked notes with a new encryption key. Your current password and recovery code will be replaced.'**
  String get resetVaultWarningBody;

  /// No description provided for @resetVaultBackupHint.
  ///
  /// In en, this message translates to:
  /// **'Make sure you have a backup of your notes before proceeding. This operation cannot be undone.'**
  String get resetVaultBackupHint;

  /// No description provided for @authenticateAndProceed.
  ///
  /// In en, this message translates to:
  /// **'Authenticate & Proceed'**
  String get authenticateAndProceed;

  /// No description provided for @resetVaultNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Create a new password for your vault. This will replace the old one.'**
  String get resetVaultNewPasswordHint;

  /// No description provided for @startReset.
  ///
  /// In en, this message translates to:
  /// **'Start Reset'**
  String get startReset;

  /// No description provided for @resetVaultDoNotClose.
  ///
  /// In en, this message translates to:
  /// **'Do not close the app or turn off your phone until the process is complete.'**
  String get resetVaultDoNotClose;

  /// No description provided for @resetStatusPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing...'**
  String get resetStatusPreparing;

  /// No description provided for @resetStatusBackingUp.
  ///
  /// In en, this message translates to:
  /// **'Reading encryption key...'**
  String get resetStatusBackingUp;

  /// No description provided for @resetStatusDecrypting.
  ///
  /// In en, this message translates to:
  /// **'Decrypting notes...'**
  String get resetStatusDecrypting;

  /// No description provided for @resetStatusGeneratingKey.
  ///
  /// In en, this message translates to:
  /// **'Generating new encryption key...'**
  String get resetStatusGeneratingKey;

  /// No description provided for @resetStatusReEncrypting.
  ///
  /// In en, this message translates to:
  /// **'Re-encrypting notes...'**
  String get resetStatusReEncrypting;

  /// No description provided for @resetStatusReplacing.
  ///
  /// In en, this message translates to:
  /// **'Finalizing...'**
  String get resetStatusReplacing;

  /// No description provided for @resetVaultSuccess.
  ///
  /// In en, this message translates to:
  /// **'Vault Reset Complete!'**
  String get resetVaultSuccess;

  /// No description provided for @saveCodeFirst.
  ///
  /// In en, this message translates to:
  /// **'Please save the recovery code first'**
  String get saveCodeFirst;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @destroyVault.
  ///
  /// In en, this message translates to:
  /// **'Destroy Vault'**
  String get destroyVault;

  /// No description provided for @destroyVaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete the vault and its keys'**
  String get destroyVaultSubtitle;

  /// No description provided for @destroyVaultWarning.
  ///
  /// In en, this message translates to:
  /// **'This action is irreversible. Make sure you have a backup or have unlocked important notes before proceeding.'**
  String get destroyVaultWarning;

  /// No description provided for @decryptAndDestroy.
  ///
  /// In en, this message translates to:
  /// **'Decrypt & Destroy'**
  String get decryptAndDestroy;

  /// No description provided for @decryptAndDestroyDesc.
  ///
  /// In en, this message translates to:
  /// **'Unlock all notes and move them to regular notes, then destroy the vault'**
  String get decryptAndDestroyDesc;

  /// No description provided for @decryptAndDestroyConfirm.
  ///
  /// In en, this message translates to:
  /// **'All locked notes will be decrypted and moved to regular notes. The vault and its encryption keys will be permanently deleted. Continue?'**
  String get decryptAndDestroyConfirm;

  /// No description provided for @destroyWithContent.
  ///
  /// In en, this message translates to:
  /// **'Destroy with Content'**
  String get destroyWithContent;

  /// No description provided for @destroyWithContentDesc.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete all locked notes and destroy the vault'**
  String get destroyWithContentDesc;

  /// No description provided for @destroyWithContentConfirm.
  ///
  /// In en, this message translates to:
  /// **'All locked notes will be PERMANENTLY DELETED along with the vault. This cannot be undone. Continue?'**
  String get destroyWithContentConfirm;

  /// No description provided for @vaultDestroyed.
  ///
  /// In en, this message translates to:
  /// **'Vault destroyed successfully'**
  String get vaultDestroyed;

  /// No description provided for @confirmDestroyCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I understand this action is irreversible'**
  String get confirmDestroyCheckbox;

  /// No description provided for @deviceSecurityRequired.
  ///
  /// In en, this message translates to:
  /// **'You must set up a screen lock (PIN, pattern, or biometric) on your device first'**
  String get deviceSecurityRequired;

  /// No description provided for @deviceSecurityRequiredDesc.
  ///
  /// In en, this message translates to:
  /// **'To use the app lock feature, your device must be protected with a screen lock (PIN, pattern, fingerprint, or face recognition). Go to your device Settings > Security to set it up.'**
  String get deviceSecurityRequiredDesc;

  /// No description provided for @enterPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPinTitle;

  /// No description provided for @enterPinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN to unlock the app'**
  String get enterPinSubtitle;

  /// No description provided for @createPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Create PIN'**
  String get createPinTitle;

  /// No description provided for @createPinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a PIN to protect your app'**
  String get createPinSubtitle;

  /// No description provided for @confirmPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPinTitle;

  /// No description provided for @confirmPinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your PIN to confirm'**
  String get confirmPinSubtitle;

  /// No description provided for @pinLabel.
  ///
  /// In en, this message translates to:
  /// **'PIN (4-6 digits)'**
  String get pinLabel;

  /// No description provided for @confirmPinLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPinLabel;

  /// No description provided for @pinRequirement.
  ///
  /// In en, this message translates to:
  /// **'4 to 6 digits only'**
  String get pinRequirement;

  /// No description provided for @savePinButton.
  ///
  /// In en, this message translates to:
  /// **'Save PIN'**
  String get savePinButton;

  /// No description provided for @pinLengthError.
  ///
  /// In en, this message translates to:
  /// **'PIN must be 4 to 6 digits'**
  String get pinLengthError;

  /// No description provided for @pinMismatchError.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match'**
  String get pinMismatchError;

  /// No description provided for @pinIncorrectError.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get pinIncorrectError;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts'**
  String get tooManyAttempts;

  /// No description provided for @tryAgainIn.
  ///
  /// In en, this message translates to:
  /// **'Try again in'**
  String get tryAgainIn;

  /// No description provided for @attemptsRemaining.
  ///
  /// In en, this message translates to:
  /// **'attempts remaining'**
  String get attemptsRemaining;

  /// No description provided for @showBiometricButton.
  ///
  /// In en, this message translates to:
  /// **'Unlock with Biometric'**
  String get showBiometricButton;

  /// No description provided for @showBiometricButtonDesc.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint or face recognition'**
  String get showBiometricButtonDesc;

  /// No description provided for @unlockWithBiometric.
  ///
  /// In en, this message translates to:
  /// **'Unlock with Biometric'**
  String get unlockWithBiometric;

  /// No description provided for @unlockWithBiometricDesc.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint or face recognition'**
  String get unlockWithBiometricDesc;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @bold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get bold;

  /// No description provided for @italic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get italic;

  /// No description provided for @underline.
  ///
  /// In en, this message translates to:
  /// **'Underline'**
  String get underline;

  /// No description provided for @strikethrough.
  ///
  /// In en, this message translates to:
  /// **'Strikethrough'**
  String get strikethrough;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @noteDuplicated.
  ///
  /// In en, this message translates to:
  /// **'Note duplicated'**
  String get noteDuplicated;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @toggleView.
  ///
  /// In en, this message translates to:
  /// **'Toggle View'**
  String get toggleView;

  /// No description provided for @readingMode.
  ///
  /// In en, this message translates to:
  /// **'Reading Mode'**
  String get readingMode;

  /// No description provided for @saveReadingPosition.
  ///
  /// In en, this message translates to:
  /// **'Save Position'**
  String get saveReadingPosition;

  /// No description provided for @readingPositionSaved.
  ///
  /// In en, this message translates to:
  /// **'Position saved'**
  String get readingPositionSaved;

  /// No description provided for @readingProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get readingProgress;

  /// No description provided for @comfortableFont.
  ///
  /// In en, this message translates to:
  /// **'Comfortable font'**
  String get comfortableFont;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
