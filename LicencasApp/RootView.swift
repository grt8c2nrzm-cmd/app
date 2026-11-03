import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            PainelView().tabItem { Label("Painel", systemImage: "square.grid.2x2") }
            LicencasView().tabItem { Label("Licenças", systemImage: "doc.text") }
            RelatorioView().tabItem { Label("Relatório", systemImage: "chart.bar.doc.horizontal") }
            MaisView().tabItem { Label("Mais", systemImage: "ellipsis.circle") }
        }
    }
}
