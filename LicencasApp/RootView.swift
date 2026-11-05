import SwiftUI

enum Destino: Hashable {
    case painel
    case farol
    case categoria(String)     // "" = todas
    case relatorio
    case mais
}

struct RootView: View {
    @Environment(\.horizontalSizeClass) private var tamanho
    var body: some View {
        if tamanho == .regular {
            IPadRoot()
        } else {
            TabView {
                PainelView().tabItem { Label("Painel", systemImage: "square.grid.2x2") }
                FarolView().tabItem { Label("Farol", systemImage: "circle.grid.3x3.fill") }
                LicencasView().tabItem { Label("Licenças", systemImage: "doc.text") }
                RelatorioView().tabItem { Label("Relatório", systemImage: "chart.bar.doc.horizontal") }
                MaisView().tabItem { Label("Mais", systemImage: "ellipsis.circle") }
            }
        }
    }
}

/// iPad: barra lateral + conteúdo, como no site.
struct IPadRoot: View {
    @EnvironmentObject var app: AppState
    @State private var destino: Destino? = .painel

    var body: some View {
        NavigationSplitView {
            List(selection: $destino) {
                Label("Painel", systemImage: "square.grid.2x2").tag(Destino.painel)
                Label("Farol das unidades", systemImage: "circle.grid.3x3.fill").tag(Destino.farol)
                Section("Licenças") {
                    ForEach(Tipos.todos, id: \.self) { t in
                        Label(Tipos.nome(t), systemImage: Tipos.icone(t)).tag(Destino.categoria(t))
                    }
                    Label("Todas", systemImage: "square.stack").tag(Destino.categoria(""))
                }
                Section("Gestão") {
                    Label("Relatório semanal", systemImage: "chart.bar.doc.horizontal").tag(Destino.relatorio)
                    Label("Empreendimentos e ajustes", systemImage: "ellipsis.circle").tag(Destino.mais)
                }
            }
            .navigationTitle("Licenças")
            .refreshable { await app.carregar() }
        } detail: {
            switch destino ?? .painel {
            case .painel: PainelView()
            case .farol: FarolView()
            case .categoria(let c): LicencasView(categoria: c).id(c)
            case .relatorio: RelatorioView()
            case .mais: MaisView()
            }
        }
    }
}
