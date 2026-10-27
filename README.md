# JIT Check

Eine kleine iOS-App, die beim Start einen ARM64-Codeblock vorbereitet und ausführt. Der Test läuft automatisch beim App-Start, damit `universal.js` den dafür nötigen Breakpoint während des JIT-Starts behandeln kann. Es gibt keinen manuellen Trap-Aufruf nach dem Wechsel zu StikDebug.

## LiveContainer

1. Die IPA aus dem GitHub-Actions-Artefakt herunterladen und in LiveContainer importieren.
2. Für JITCheck **Launch with JIT** einschalten und `universal.js` als JIT-Launch-Skript auswählen.
3. JITCheck direkt über LiveContainer starten. Nicht erst in JITCheck zu StikDebug wechseln und danach den Testknopf drücken: Das Skript kann zu diesem Zeitpunkt bereits vom Prozess getrennt sein.
4. Die App zeigt nach dem Start an, ob der Testcode `42` zurückgegeben hat oder welche Vorbedingung fehlte.

Der Test wartet bis zu fünf Sekunden auf einen aktiven Debugger und prüft zusätzlich, dass der Prozess noch tatsächlich verfolgt wird. Ohne diese beiden Bedingungen wird kein `BRK` ausgeführt. Bei einem JIT-Start mit aktivem Debugger fordert die App über `universal.js` eine RX-Seite an, erstellt dafür einen getrennten RW-Alias, schreibt den Code, lässt das Skript kontrolliert detach-en und führt erst danach den Code aus.

## Build

Der GitHub-Actions-Workflow unter `.github/workflows/ios-build.yml` baut auf einem macOS-Runner und legt `JITCheck.ipa` als Actions-Artefakt ab. Die IPA ist unsigniert; LiveContainer muss sie beim Import passend signieren. Das Projekt wurde auf Linux erstellt; dort sind weder Xcode noch iOS SDK verfügbar, daher kann hier keine iOS-App/IPA gelinkt werden.
