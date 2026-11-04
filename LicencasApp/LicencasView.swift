import SwiftUI

struct LicencasView: View {
    @EnvironmentObject var app: AppState
    @State private var categoria: String        // "" = todas
    @State private var busca = ""
    @State private var fSit = ""             // "", atencao, vermelho, ambar, verde
    @State private var fReg = ""
    @State private var fLR = ""
    @State private var nova = false

    init(categoria: String = "") { _categoria = State(initialValue: categoria) }

    private var regs: [String] { Array(Set(app.dados.empreendimentos.compactMap { $0.regional }.filter { !$0.isEmpty })).sorted() }
    private var lrs: [String] { Array(Set(app.dados.empreendimentos.compactMap { $0.lr }.filter { !$0.isEmpty })).sorted() }

    private var linhas: [(Licenca, Emp, Sit)] {
        let q = busca.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
        let r: [(Licenca, Emp, Sit)] = app.dados.licencas.compactMap { l in
            guard categoria.isEmpty || l.tipo == categoria, let e = app.emp(l.empId) else { return nil }
            if !fReg.isEmpty && e.regional != fReg { return nil }
            if !fLR.isEmpty && e.lr != fLR { return nil }
            let s = situacao(l, app.dados.cfg)
            switch fSit {
            case "atencao": if !s.atencao { return nil }
            case "vermelho": if s.cor != .vermelho { return nil }
            case "ambar": if s.cor != .ambar { return nil }
            case "verde": if s.cor != .verde { return nil }
            default: break
            }
            if !q.isEmpty {
                let alvo = [e.sigla, e.nome, e.regional ?? "", e.ls ?? "", e.lr ?? "", l.numero ?? "", l.processo ?? ""].joined(separator: " ")
                    .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
                if !alvo.contains(q) { return nil }
            }
            return (l, e, s)
        }
        return r.sorted { a, b in
            a.2.ordem != b.2.ordem ? a.2.ordem < b.2.ordem : (a.2.dias ?? 99999) < (b.2.dias ?? 99999)
        }
    }

    var body: some View {
        NavigationStack {
            let rows = linhas
            List {
                if rows.isEmpty {
                    Text(busca.isEmpty && fSit.isEmpty && fReg.isEmpty && fLR.isEmpty ? "Nenhuma licença cadastrada." : "Nada encontrado.")
                        .foregroundStyle(.secondary)
                }
                ForEach(rows, id: \.0.id) { (l, e, s) in
                    NavigationLink(value: l.id) {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(e.sigla).font(.headline)
                                if categoria.isEmpty { Etiqueta(texto: Tipos.curto(l.tipo)) }
                                Spacer()
                                Text(Datas.diasTxt(s.dias)).font(.caption).foregroundStyle(.secondary)
                            }
                            Text(e.nome).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                            HStack {
                                Chip(sit: s)
                                Spacer()
                                Text("\(l.numero ?? "s/ nº") · \(Datas.br(l.validade))").font(.caption).foregroundStyle(.secondary)
                            }
                            Text([e.regional, e.ls, e.lr].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "))
                                .font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .navigationTitle(categoria.isEmpty ? "Todas" : Tipos.curto(categoria))
            .navigationDestination(for: String.self) { id in DetalheLoader(id: id) }
            .searchable(text: $busca, prompt: "Sigla, unidade, LS, LR, nº…")
            .refreshable { await app.carregar() }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Categoria", selection: $categoria) {
                            Label("Todas as licenças", systemImage: "square.stack").tag("")
                            ForEach(Tipos.todos, id: \.self) { t in Label(Tipos.nome(t), systemImage: Tipos.icone(t)).tag(t) }
                        }
                    } label: { Label("Categoria", systemImage: "line.3.horizontal.decrease.circle.fill") }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Picker("Situação", selection: $fSit) {
                            Text("Qualquer situação").tag("")
                            Text("Precisam de atenção").tag("atencao")
                            Text("Vermelho").tag("vermelho")
                            Text("Em renovação").tag("ambar")
                            Text("Em dia").tag("verde")
                        }
                        Picker("Regional", selection: $fReg) {
                            Text("Todas as regionais").tag("")
                            ForEach(regs, id: \.self) { Text($0).tag($0) }
                        }
                        Picker("LR", selection: $fLR) {
                            Text("Todos os LR").tag("")
                            ForEach(lrs, id: \.self) { Text($0).tag($0) }
                        }
                        Button("Limpar filtros", role: .destructive) { fSit = ""; fReg = ""; fLR = "" }
                    } label: {
                        Image(systemName: (fSit.isEmpty && fReg.isEmpty && fLR.isEmpty) ? "line.3.horizontal.decrease" : "line.3.horizontal.decrease.circle.fill")
                    }
                    Button { nova = true } label: { Image(systemName: "plus") }
                        .disabled(app.dados.empreendimentos.isEmpty)
                }
            }
            .sheet(isPresented: $nova) {
                NavigationStack {
                    LicencaDetalhe(l: .vazia(categoria.isEmpty ? "LO" : categoria), novo: true)
                }
            }
        }
    }
}
