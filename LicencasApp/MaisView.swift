import SwiftUI

struct MaisView: View {
    @EnvironmentObject var app: AppState
    @AppStorage("tema") private var temaRaw = Tema.sistema.rawValue
    @State private var busca = ""

    private var emps: [Emp] {
        let q = busca.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
        return app.dados.empreendimentos.filter { e in
            q.isEmpty || [e.sigla, e.nome, e.regional ?? "", e.ls ?? "", e.lr ?? ""].joined(separator: " ")
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil).contains(q)
        }.sorted { $0.sigla < $1.sigla }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Aparência") {
                    Picker("Tema", selection: $temaRaw) {
                        ForEach(Tema.allCases) { Text($0.titulo).tag($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Empreendimentos (\(emps.count))") {
                    ForEach(emps) { e in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(e.sigla) — \(e.nome)\(e.semPoco == true ? " · sem poço" : "")").font(.subheadline.weight(.semibold))
                            Text([e.regional, e.ls, e.lr].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Text("Cadastro e edição de empreendimentos, usuários e prazos: pelo site (administrador).")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section {
                    LabeledContent("Conectado como", value: app.me?.nome ?? "")
                    Button("Sair", role: .destructive) { app.sair() }
                }
            }
            .navigationTitle("Mais")
            .searchable(text: $busca, prompt: "Buscar empreendimento")
        }
    }
}
