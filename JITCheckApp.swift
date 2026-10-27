import SwiftUI
import UIKit
import Darwin

@main
struct JITCheckApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var message = "Bereit für den JIT-Test."
    @State private var openingStikDebug = false

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "memorychip.fill")
                .font(.system(size: 56))
                .foregroundStyle(.blue)
            Text("JIT Check")
                .font(.largeTitle.bold())
            Text("Prüft, ob StikDebug JIT für diese App aktiviert hat, und führt anschließend einen kleinen ARM64-Codeblock aus.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button(action: start) {
                Label("StikDebug öffnen & JIT aktivieren", systemImage: "arrow.up.right.square")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .disabled(openingStikDebug)
            Button(action: runTest) {
                Label("JIT jetzt testen", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)
            .disabled(openingStikDebug)
            Text(message)
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
            Spacer()
            Text("Für LiveContainer: „Launch with JIT“ einschalten und universal.js als JIT-Skript auswählen.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active && openingStikDebug {
                // Some LiveContainer versions don't deliver UIApplication.open's
                // completion consistently when switching between app containers.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    guard openingStikDebug else { return }
                    openingStikDebug = false
                    message = "Zurück aus StikDebug. Tippe jetzt auf „JIT jetzt testen“."
                }
            }
        }
    }

    private func start() {
        openingStikDebug = true
        message = "StikDebug wird geöffnet …"
        guard let bundleID = Bundle.main.bundleIdentifier,
              var parts = URLComponents(string: "stikdebug://enable-jit") else {
            openingStikDebug = false
            message = "Fehler: Bundle-ID oder StikDebug-URL fehlt."
            return
        }
        parts.queryItems = [
            URLQueryItem(name: "bundle-id", value: bundleID),
            URLQueryItem(name: "pid", value: String(getpid())),
            URLQueryItem(name: "script-name", value: "universal.js")
        ]
        guard let url = parts.url else {
            openingStikDebug = false
            message = "Fehler: StikDebug-URL konnte nicht erstellt werden."
            return
        }
        UIApplication.shared.open(url) { opened in
            DispatchQueue.main.async {
                openingStikDebug = false
                if opened {
                    message = "StikDebug wurde geöffnet. Aktiviere dort JIT und tippe nach der Rückkehr auf „JIT jetzt testen“."
                } else {
                    message = "StikDebug konnte nicht geöffnet werden. Prüfe Installation, Pairing und LiveContainer-Konfiguration."
                }
            }
        }
    }

    private func runTest() {
        message = "JIT wird geprüft …"
        let status = JITCheckRun()
        switch status {
        case 42:
            message = "✅ JIT funktioniert. Der dynamische ARM64-Code hat 42 zurückgegeben."
        case -1:
            message = "❌ Dieser Test benötigt ein ARM64-iPhone oder iPad."
        case -2:
            message = "❌ StikDebug hat diesen App-Prozess nicht als Debugger markiert. Prüfe „Use LiveContainer’s Bundle ID“ und starte die App über LiveContainer mit JIT."
        case -3:
            message = "❌ JIT-Test: Es konnte keine Test-Speicherseite angelegt werden."
        case -4:
            message = "❌ universal.js hat die Test-Speicherseite nicht vorbereitet. Prüfe das ausgewählte Skript und aktiviere JIT erneut."
        default:
            message = "❌ JIT-Test fehlgeschlagen (Status \(status))."
        }
    }
}
