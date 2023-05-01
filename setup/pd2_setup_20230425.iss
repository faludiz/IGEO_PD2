[Setup]
AppName=IGEO.PD
ChangesAssociations=true
PrivilegesRequired=none
DefaultDirName={userappdata}\igeo.pd
AllowUNCPath=false
AppID={{3C393C41-294E-493F-924E-AE470585908D}
AppVerName=IGEO.PD 2.0
AppCopyright=INTELLIGEO Kft

AppSupportURL=https://intelligeo.hu

AppVersion=22.12.03
OutputBaseFilename=pd2_setup_20230425

UninstallDisplayIcon={app}\pd_document.ico
UninstallDisplayName=IGEO.PD2
DefaultGroupName=IGEO.PD2
Compression=lzma/ultra
InternalCompressLevel=ultra
ShowLanguageDialog=no
DisableDirPage=true
DisableProgramGroupPage=true

[Files]
Source: ..\bin\igeo_pd2.exe; DestDir: {app}; Flags: ignoreversion
Source: ..\bin\sqlite3.*; DestDir: {app}; Flags: ignoreversion
Source: ..\source\pd_document.ico; DestDir: {app}

[Run]
Filename: {app}\igeo_pd2.exe; WorkingDir: {app}; Flags: nowait

[Registry]
Root: HKCR; SubKey: .PD; ValueType: string; ValueData: PD; Flags: uninsdeletekey
Root: HKCR; SubKey: PD; ValueType: string; ValueData: PD; Flags: uninsdeletekey
Root: HKCR; SubKey: PD\Shell\Open\Command; ValueType: string; ValueData: """{app}\igeo_pd2.exe"" ""%1"""; Flags: uninsdeletevalue
Root: HKCR; Subkey: PD\DefaultIcon; ValueType: string; ValueData: {app}\pd_document.ico,0; Flags: uninsdeletevalue

[Icons]
Name: {group}\IGEO.PD2 Beállítások; Filename: {app}\igeo_pd2.exe; IconFilename: {app}\pd_document.ico; IconIndex: 0
