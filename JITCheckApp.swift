import SwiftUI
import Darwin

@main
struct JITCheckApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var message = "Warte auf den JIT-Start …"
    @State private var hasRun = false
    @State private var isRunning = false

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "memorychip.fill")
                .font(.system(size: 56))
                .foregroundStyle(.blue)
            Text("JIT Check")
                .font(.largeTitle.bold())
            Text("Der Test läuft automatisch einmal direkt nach dem Start. So kann universal.js den nötigen Breakpoint während des JIT-Starts behandeln.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            if isRunning {
                ProgressView("JIT wird geprüft …")
            }
            Text(message)
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
            Spacer()
            Text("In LiveContainer für diese App „Launch with JIT“ aktivieren und universal.js auswählen. Danach die App über LiveContainer starten.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .onAppear(perform: scheduleTest)
        .onChange(of: scenePhase) { _, phase in
            // A JIT launch can finish its debugger attach just after the first
            // SwiftUI appearance. Retry once on activation, never after a
            // manual StikDebug handoff where universal.js may have detached.
            if phase == .active { scheduleTest() }
        }
    }

    private func scheduleTest() {
        guard !hasRun && !isRunning else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            guard !hasRun && !isRunning else { return }
            hasRun = true
            isRunning = true
            message = "Prüfe, ob LiveContainer den JIT-Start aktiviert hat …"

            DispatchQueue.global(qos: .userInitiated).async {
                let status = JITCheckRun()
                DispatchQueue.main.async {
                    isRunning = false
                    switch status {
                    case 42:
                        message = "✅ JIT funktioniert. Der dynamische ARM64-Code hat 42 zurückgegeben."
                    case -1:
                        message = "❌ Dieser Test benötigt ein ARM64-iPhone oder iPad."
                    case -2:
                        message = "❌ Kein aktiver Debugger erkannt. Aktiviere in LiveContainer „Launch with JIT“ und wähle universal.js für JITCheck. Starte die App anschließend über LiveContainer neu."
                    case -3:
                        message = "❌ Es konnte keine Test-Speicherseite angelegt werden."
                    case -4:
                        message = "❌ universal.js hat die Test-Speicherseite nicht vorbereitet. Prüfe das ausgewählte Skript und starte die App erneut mit JIT."
                    case -5:
                        message = "❌ Die Debugger-Verbindung wurde vor Abschluss der Vorbereitung getrennt. Starte JITCheck erneut über LiveContainer mit universal.js."
                    default:
                        message = "❌ JIT-Test fehlgeschlagen (Status \(status))."
                    }
                }
            }
        }
    }
}
