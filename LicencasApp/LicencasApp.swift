import SwiftUI

@main
struct LicencasApp: App {
    @StateObject private var app = AppState()
    @AppStorage("tema") private var temaRaw = Tema.sistema.rawValue
    var body: some Scene {
        WindowGroup {
            Group {
                if app.restaurando {
                    ZStack { Fundo(); ProgressView("Entrando…") }
                } else if app.logado {
                    RootView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(app)
            .tint(laranja)
            .preferredColorScheme((Tema(rawValue: temaRaw) ?? .sistema).esquema)
            .task { await app.restaurarSessao() }
        }
    }
}
