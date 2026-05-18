; Sinan Note — Inno Setup Script
; Copyright © 2025 Apex Flow Group. All rights reserved.

#define AppName "Sinan Note"
#define AppPublisher "Apex Flow Group"
#define AppURL "https://sinanai.net"
#define AppExeName "sinan_note.exe"
#define SourceDir "build\windows\x64\runner\Release"
#define AppVersion GetVersionNumbersString(SourceDir + "\" + AppExeName)

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
AllowNoIcons=yes
OutputDir=installer
OutputBaseFilename=SinanNote_Setup_{#AppVersion}
SetupIconFile=windows\runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}
VersionInfoVersion={#AppVersion}
VersionInfoCompany={#AppPublisher}
VersionInfoDescription={#AppName} Installer
VersionInfoCopyright=Copyright © 2025 {#AppPublisher}

[Languages]
Name: "arabic"; MessagesFile: "compiler:Languages\Arabic.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "startupicon"; Description: "تشغيل مع بدء Windows"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#SourceDir}\{#AppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\dynamic_color_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\flutter_local_notifications_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\flutter_secure_storage_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\flutter_timezone_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\local_auth_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\permission_handler_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\share_plus_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\url_launcher_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon
Name: "{userstartup}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: startupicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
