; SHIPS2-Go Windows Installer Script
; Built with NSIS (Nullsoft Scriptable Install System)

!define PRODUCT_NAME "SHIPS2-Go"
!define PRODUCT_VERSION "${VERSION}"
!define PRODUCT_PUBLISHER "SHIPS2-Go Project"
!define PRODUCT_WEB_SITE "https://github.com/jottavia/ships-go"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\shipsc.exe"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"

; Modern UI
!include "MUI2.nsh"

; Privileges
RequestExecutionLevel admin

; General settings
Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "SHIPS2-Go-${PRODUCT_VERSION}-installer.exe"
InstallDir "$PROGRAMFILES\Ships"
InstallDirRegKey HKLM "${PRODUCT_DIR_REGKEY}" ""
ShowInstDetails show
ShowUnInstDetails show

; Interface Settings
!define MUI_ABORTWARNING
!define MUI_ICON "ships2-go.ico"
!define MUI_UNICON "ships2-go.ico"

; Welcome page
!insertmacro MUI_PAGE_WELCOME

; License page
!define MUI_LICENSEPAGE_CHECKBOX
!insertmacro MUI_PAGE_LICENSE "..\..\LICENSE"

; Components page
!insertmacro MUI_PAGE_COMPONENTS

; Directory page
!insertmacro MUI_PAGE_DIRECTORY

; Installation page
!insertmacro MUI_PAGE_INSTFILES

; Finish page
!define MUI_FINISHPAGE_RUN "$INSTDIR\shipsc.exe"
!define MUI_FINISHPAGE_RUN_PARAMETERS "version"
!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\README.txt"
!insertmacro MUI_PAGE_FINISH

; Uninstaller pages
!insertmacro MUI_UNPAGE_INSTFILES

; Language files
!insertmacro MUI_LANGUAGE "English"

; Version information
VIProductVersion "${PRODUCT_VERSION}.0"
VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductName" "${PRODUCT_NAME}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "Comments" "Secure password escrow for workgroup environments"
VIAddVersionKey /LANG=${LANG_ENGLISH} "CompanyName" "${PRODUCT_PUBLISHER}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalTrademarks" ""
VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalCopyright" "© 2025 Joseph V. Ottaviano"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileDescription" "${PRODUCT_NAME} Installer"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileVersion" "${PRODUCT_VERSION}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductVersion" "${PRODUCT_VERSION}"

Section "SHIPS2-Go Client (Required)" SEC01
  SectionIn RO
  
  ; Set output path to the installation directory
  SetOutPath "$INSTDIR"
  
  ; Install files
  File "..\..\dist\shipsc-windows-amd64.exe"
  Rename "$INSTDIR\shipsc-windows-amd64.exe" "$INSTDIR\shipsc.exe"
  
  ; Install documentation
  File "..\..\README.md"
  Rename "$INSTDIR\README.md" "$INSTDIR\README.txt"
  File "..\..\RELEASE_NOTES_v1.0.0.md"
  Rename "$INSTDIR\RELEASE_NOTES_v1.0.0.md" "$INSTDIR\RELEASE_NOTES.txt"
  
  ; Install scheduled task XML
  File "..\..\docs\client_task.xml"
SectionEnd

Section "Scheduled Task" SEC02
  ; Import the scheduled task
  DetailPrint "Importing SHIPS2-Go scheduled task..."
  ExecWait 'schtasks /create /xml "$INSTDIR\client_task.xml" /tn "SHIPS2-Go Daily Rotation" /f' $0
  
  ${If} $0 == 0
    DetailPrint "Scheduled task imported successfully"
  ${Else}
    DetailPrint "Warning: Failed to import scheduled task (Error: $0)"
    DetailPrint "You can manually import client_task.xml using Task Scheduler"
  ${EndIf}
SectionEnd

Section "Windows Event Log Source" SEC03
  ; Create event log source for SHIPS2-Go
  DetailPrint "Creating Windows Event Log source..."
  WriteRegStr HKLM "SYSTEM\CurrentControlSet\Services\EventLog\Application\SHIPS2-Go" "EventMessageFile" "$INSTDIR\shipsc.exe"
  WriteRegDWORD HKLM "SYSTEM\CurrentControlSet\Services\EventLog\Application\SHIPS2-Go" "TypesSupported" 7
SectionEnd

Section "Environment Variables" SEC04
  ; Add installation directory to PATH (optional)
  DetailPrint "Adding SHIPS2-Go to system PATH..."
  
  ; Read current PATH
  ReadRegStr $0 HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "PATH"
  
  ; Check if already in PATH
  ${StrContains} $1 "$INSTDIR" "$0"
  ${If} $1 == ""
    ; Add to PATH
    WriteRegExpandStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "PATH" "$0;$INSTDIR"
    ; Broadcast change
    SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
  ${EndIf}
SectionEnd

Section -AdditionalIcons
  ; Create Start Menu shortcuts
  CreateDirectory "$SMPROGRAMS\SHIPS2-Go"
  CreateShortCut "$SMPROGRAMS\SHIPS2-Go\SHIPS2-Go Client.lnk" "$INSTDIR\shipsc.exe" "version"
  CreateShortCut "$SMPROGRAMS\SHIPS2-Go\Documentation.lnk" "$INSTDIR\README.txt"
  CreateShortCut "$SMPROGRAMS\SHIPS2-Go\Uninstall.lnk" "$INSTDIR\uninst.exe"
SectionEnd

Section -Post
  ; Write installation info to registry
  WriteUninstaller "$INSTDIR\uninst.exe"
  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\shipsc.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "$(^Name)"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninst.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\shipsc.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
SectionEnd

; Section descriptions
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC01} "SHIPS2-Go client executable (shipsc.exe) and documentation"
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC02} "Automatically imports the scheduled task for daily password rotation"
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC03} "Creates Windows Event Log source for SHIPS2-Go logging"
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC04} "Adds SHIPS2-Go installation directory to system PATH"
!insertmacro MUI_FUNCTION_DESCRIPTION_END

Function un.onUninstSuccess
  HideWindow
  MessageBox MB_ICONINFORMATION|MB_OK "$(^Name) was successfully removed from your computer."
FunctionEnd

Function un.onInit
  MessageBox MB_ICONQUESTION|MB_YESNO|MB_DEFBUTTON2 "Are you sure you want to completely remove $(^Name) and all of its components?" IDYES +2
  Abort
FunctionEnd

Section Uninstall
  ; Remove scheduled task
  ExecWait 'schtasks /delete /tn "SHIPS2-Go Daily Rotation" /f'
  
  ; Remove files
  Delete "$INSTDIR\shipsc.exe"
  Delete "$INSTDIR\README.txt"
  Delete "$INSTDIR\RELEASE_NOTES.txt"
  Delete "$INSTDIR\client_task.xml"
  Delete "$INSTDIR\uninst.exe"
  
  ; Remove directories
  RMDir "$INSTDIR"
  
  ; Remove Start Menu items
  Delete "$SMPROGRAMS\SHIPS2-Go\*.*"
  RMDir "$SMPROGRAMS\SHIPS2-Go"
  
  ; Remove from PATH
  ReadRegStr $0 HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "PATH"
  ${StrRep} $0 $0 ";$INSTDIR" ""
  ${StrRep} $0 $0 "$INSTDIR;" ""
  ${StrRep} $0 $0 "$INSTDIR" ""
  WriteRegExpandStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "PATH" "$0"
  
  ; Remove registry keys
  DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"
  DeleteRegKey HKLM "SYSTEM\CurrentControlSet\Services\EventLog\Application\SHIPS2-Go"
  
  ; Broadcast PATH change
  SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
  
  SetAutoClose true
SectionEnd