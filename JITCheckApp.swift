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
    @State private var busy = false

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
                Label("JIT aktivieren & testen", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .disabled(busy)
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
            if phase == .active && busy {
                // Give StikDebug a moment to finish attaching before we inspect the task.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { runTest() }
            }
        }
    }

    private func start() {
        busy = true
        message = "StikDebug wird geöffnet …"
        guard let bundleID = Bundle.main.bundleIdentifier,
              var parts = URLComponents(string: "stikdebug://enable-jit") else {
            busy = false
            message = "Fehler: Bundle-ID oder StikDebug-URL fehlt."
            return
        }
        parts.queryItems = [
            URLQueryItem(name: "bundle-id", value: bundleID),
            URLQueryItem(name: "pid", value: String(getpid())),
            URLQueryItem(name: "script-name", value: "universal.js")
        ]
        guard let url = parts.url else {
            busy = false
            message = "Fehler: StikDebug-URL konnte nicht erstellt werden."
            return
        }
        UIApplication.shared.open(url) { opened in
            if !opened {
                busy = false
                message = "StikDebug konnte nicht geöffnet werden. Prüfe Installation, Pairing und LiveContainer-Konfiguration."
            }
        }
    }

    private func runTest() {
        guard busy else { return }
        let status = JITCheckRun()
        busy = false
        message = status == 42
            ? "✅ JIT funktioniert. Der dynamische ARM64-Code hat 42 zurückgegeben."
            : "❌ JIT-Test fehlgeschlagen (Status \(status)). Prüfe StikDebug, universal.js und „Use LiveContainer’s Bundle ID“."
    }
}
