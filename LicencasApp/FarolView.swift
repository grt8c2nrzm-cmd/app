import SwiftUI

/// Uma linha por empreendimento, com a situação de cada licença por cor.
struct FarolView: View {
    @EnvironmentObject var app: AppState
    @State private var busca = ""

    private enum Estado { case vermelho, ambar, verde, cinza, nenhuma, naoSeAplica }

    private func estado(_ e: Emp, _ tipo: String) -> (Estado, Int) {
        if tipo == "OUTORGA" && e.semPoco == true { return (.naoSeAplica, 9) }
        let ls = app.dados.licencas.filter { $0.empId == e.id && $0.tipo == tipo }
        if ls.isEmpty { return (.nenhuma, 9) }
        let pior = ls.map { app.sit($0) }.min { $0.ordem < $1.ordem }!
        switch pior.cor {
        case .vermelho: return (.vermelho, pior.ordem)
        case .ambar: return (.ambar, pior.ordem)
        case .verde: return (.verde, pior.ordem)
        case .cinza: return (.cinza, pior.ordem)
        }
    }

    private func geral(_ e: Emp) -> Int {
        Tipos.todos.map { estado(e, $0) }.filter { $0.0 != .nenhuma && $0.0 != .naoSeAplica }.map { $0.1 }.min() ?? 9
    }

    private var emps: [Emp] {
        let q = busca.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
        return app.dados.empreendimentos.filter { e in
            q.isEmpty || [e.sigla, e.nome, e.regional ?? "", e.ls ?? "", e.lr ?? ""].joined(separator: " ")
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil).contains(q)
        }.sorted { a, b in
            let ga = geral(a), gb = geral(b)
            return ga != gb ? ga < gb : a.sigla < b.sigla
        }
    }

    private func bolinha(_ s: Estado) -> some View {
        Group {
            switch s {
            case .vermelho: Circle().fill(Color.red)
            case .ambar: Circle().fill(Color.orange)
            case .verde: Circle().fill(Color.green)
            case .cinza: Circle().fill(Color.gray)
            case .nenhuma: Circle().strokeBorder(Color.secondary, lineWidth: 1.5)
            case .naoSeAplica: Circle().fill(Color.secondary.opacity(0.25))
            }
        }
        .frame(width: 18, height: 18)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 10) {
                        legenda(.vermelho, "Vencida"); legenda(.ambar, "Renovação"); legenda(.verde, "Em dia")
                        legenda(.nenhuma, "Sem cadastro"); legenda(.naoSeAplica, "N/A")
                    }
                    .font(.caption2)
                }
                ForEach(emps) { e in
                    NavigationLink(value: e) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(e.sigla).font(.headline)
                                Text(e.nome).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                                if e.semPoco == true { Etiqueta(texto: "sem poço") }
                            }
                            HStack(spacing: 0) {
                                ForEach(Tipos.todos, id: \.self) { t in
                                    VStack(spacing: 4) {
                                        bolinha(estado(e, t).0)
                                        Text(Tipos.curto(t)).font(.caption2).foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Farol")
            .navigationDestination(for: Emp.self) { e in FarolDetalhe(emp: e) }
            .navigationDestination(for: String.self) { id in DetalheLoader(id: id) }
            .searchable(text: $busca, prompt: "Sigla, unidade, LS, LR…")
            .refreshable { await app.carregar() }
        }
    }

    private func legenda(_ s: Estado, _ t: String) -> some View {
        HStack(spacing: 4) {
            bolinha(s).scaleEffect(0.6).frame(width: 12, height: 12)
            Text(t)
        }
    }
}

struct FarolDetalhe: View {
    @EnvironmentObject var app: AppState
    var emp: Emp
    var body: some View {
        let ls = app.dados.licencas.filter { $0.empId == emp.id }.sorted { $0.tipo < $1.tipo }
        List {
            Section {
                LabeledContent("Regional / LS / LR", value: [emp.regional, emp.ls, emp.lr].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "))
                if emp.semPoco == true { LabeledContent("Poço", value: "Sem poço (não exige outorga)") }
            }
            Section("Licenças") {
                if ls.isEmpty { Text("Nenhuma licença cadastrada.").foregroundStyle(.secondary) }
                ForEach(ls) { l in
                    NavigationLink(value: l.id) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack { Etiqueta(texto: Tipos.curto(l.tipo)); Text(l.numero ?? "s/ nº").font(.subheadline.weight(.semibold)); Spacer(); Chip(sit: app.sit(l)) }
                            Text("Validade: \(l.validadeTxt)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(emp.sigla)
    }
}
