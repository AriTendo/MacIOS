# JIT Check

Eine kleine iOS-App, die StikDebug mit `universal.js` für ihren laufenden Prozess aufruft und danach eine vorbereitete ARM64-Speicherseite ausführt. Der Testcode gibt `42` zurück.

## LiveContainer

1. Die IPA aus dem GitHub-Actions-Artefakt herunterladen.
2. Die IPA in LiveContainer importieren. Für die App „Launch with JIT“ aktivieren und `universal.js` als JIT-Launch-Skript auswählen.
3. In LiveContainer „Use LiveContainer's Bundle ID“ einschalten, falls StikDebug die App nicht zurückfindet.
4. Die App starten und „JIT aktivieren & testen“ antippen. StikDebug muss bereits gekoppelt und einsatzbereit sein.

Die App prüft `CS_DEBUGGED`, bevor sie den Breakpoint an `universal.js` sendet. Ohne aktiven Debugger wird der Breakpoint nicht ausgeführt, damit die App nicht durch einen unbehandelten `brk` abstürzt.

## Build

Der GitHub-Actions-Workflow unter `.github/workflows/ios-build.yml` baut auf einem macOS-Runner und legt `JITCheck.ipa` als Actions-Artefakt ab. Dazu den Inhalt dieses Ordners in ein GitHub-Repository pushen und den Workflow unter **Actions → Build iOS app → Run workflow** starten. Die IPA ist unsigniert; LiveContainer muss sie beim Import passend signieren. Dieses Projekt wurde auf Linux erstellt; dort sind weder Xcode noch iOS SDK verfügbar, daher kann hier keine iOS-App/IPA gelinkt werden.
