; ============================================================
;  CoccOs - Installeur Windows (NSIS)
;  Plateforme educative libre pour l'enfant
;  (c) 2026 IA&TIC - CC BY-SA 4.0 - Freddy Maillard / NET&TIC
; ============================================================

Unicode true
!include "MUI2.nsh"

; --- Metadonnees ---
!define APP_NAME        "CoccOs"
; La version s'injecte depuis la ligne de commande :
;   makensis -DAPP_VERSION=0.1.31.40 coccos_installer.nsi
; Le defaut ci-dessous ne sert qu'a une compilation manuelle.
!ifndef APP_VERSION
  !define APP_VERSION   "0.0.0.0"
!endif
!define APP_PUBLISHER   "NET&TIC"
!define APP_EXE         "coccos.exe"
!define APP_ICON        "coccos.ico"

Name "${APP_NAME} ${APP_VERSION}"
OutFile "coccos_setup_${APP_VERSION}.exe"
InstallDir "$PROGRAMFILES64\${APP_NAME}"
InstallDirRegKey HKLM "Software\${APP_NAME}" "InstallDir"
RequestExecutionLevel admin
SetCompressor /SOLID lzma

; --- Interface Modern UI ---
!define MUI_ICON   "${APP_ICON}"
!define MUI_UNICON "${APP_ICON}"
!define MUI_ABORTWARNING

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_RUN "$INSTDIR\${APP_EXE}"
!define MUI_FINISHPAGE_RUN_TEXT "Lancer CoccOs maintenant"
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "French"

; --- Section d'installation ---
Section "CoccOs (requis)" SecMain
  SectionIn RO
  SetOutPath "$INSTDIR"

  File "coccos.exe"
  File "coccos.pck"
  File "coccos.ico"

  ; Convertisseur video de "Ma tele" (import avec conversion automatique).
  ; Deposer ffmpeg.exe (build officiel Windows, licence GPL) + sa licence dans
  ; ce dossier avant compilation - /nonfatal : le build passe aussi sans eux
  ; (CoccOs affichera alors "convertisseur manquant" dans Reglages -> Tele).
  File /nonfatal "ffmpeg.exe"
  File /nonfatal "ffmpeg_LICENSE.txt"

  ; Raccourci menu Demarrer
  CreateDirectory "$SMPROGRAMS\${APP_NAME}"
  CreateShortcut "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_ICON}" 0
  ; Icone directe "Mon classeur" (lancement sans passer par le bureau CoccOs) —
  ; les arguments apres "--" arrivent dans les user args de Godot
  CreateShortcut "$SMPROGRAMS\${APP_NAME}\Mon classeur.lnk" "$INSTDIR\${APP_EXE}" "-- --app classeur" "$INSTDIR\${APP_ICON}" 0
  CreateShortcut "$SMPROGRAMS\${APP_NAME}\Desinstaller ${APP_NAME}.lnk" "$INSTDIR\uninstall.exe"

  ; Raccourci bureau
  CreateShortcut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_ICON}" 0

  ; Desinstalleur + entree "Ajout/Suppression de programmes"
  WriteUninstaller "$INSTDIR\uninstall.exe"
  WriteRegStr HKLM "Software\${APP_NAME}" "InstallDir" "$INSTDIR"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayName" "${APP_NAME}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayVersion" "${APP_VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "Publisher" "${APP_PUBLISHER}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayIcon" "$INSTDIR\${APP_ICON}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "UninstallString" "$INSTDIR\uninstall.exe"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "NoRepair" 1
SectionEnd

; --- Section de desinstallation ---
Section "Uninstall"
  Delete "$INSTDIR\coccos.exe"
  Delete "$INSTDIR\coccos.pck"
  Delete "$INSTDIR\coccos.ico"
  Delete "$INSTDIR\ffmpeg.exe"
  Delete "$INSTDIR\ffmpeg_LICENSE.txt"
  Delete "$INSTDIR\uninstall.exe"
  RMDir "$INSTDIR"

  Delete "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk"
  Delete "$SMPROGRAMS\${APP_NAME}\Mon classeur.lnk"
  Delete "$SMPROGRAMS\${APP_NAME}\Desinstaller ${APP_NAME}.lnk"
  RMDir "$SMPROGRAMS\${APP_NAME}"
  Delete "$DESKTOP\${APP_NAME}.lnk"

  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"
  DeleteRegKey HKLM "Software\${APP_NAME}"
SectionEnd
