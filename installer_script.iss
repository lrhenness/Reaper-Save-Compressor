; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

[Setup]
; NOTE: The value of AppId uniquely identifies this application. Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{15742D86-18B8-486F-8579-8C4528EFF072}
AppName=reaper_save_compressor
AppVersion=1.0
;AppVerName=reaper_save_compressor 1.0
AppPublisher=stigs@stigsdomain.com
DefaultDirName={autopf}\reaper_save_compressor
DefaultGroupName=reaper_save_compressor
AllowNoIcons=yes
; Remove the following line to run in administrative install mode (install for all users.)
PrivilegesRequired=lowest
OutputBaseFilename=reaper_save_compressor_installer
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: ".\reaper_save_compressor.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: ".\README.pdf"; DestDir: "{app}"; Flags: ignoreversion
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{group}\{cm:UninstallProgram,reaper_save_compressor}"; Filename: "{uninstallexe}"
[Icons]
Name: "{group}\{cm:UninstallProgram,Reaper Save Compressor}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Reaper Save Compressor"; Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-ExecutionPolicy Bypass -NoExit -File ""{app}\reaper_save_compressor.ps1"""; WorkingDir: "{app}"

[Run]
Filename: "explorer"; Parameters: """{app}\README.pdf"""; Description: "View the user guide"; Flags: postinstall skipifsilent