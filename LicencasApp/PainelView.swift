import SwiftUI

struct PainelView: View {
    @EnvironmentObject var app: AppState
    @State private var rtSel = ""   // só admin: "" = todos

    private var rtId: String? { app.admin ? (rtSel.isEmpty ? nil : rtSel) : app.me?.id }
    private var linhas: [(Licenca, Emp, Sit)] {
        app.dados.licencas.compactMap { l in
            guard let e = app.emp(l.empId) else { return nil }
            if let r = rtId, !(e.rts ?? []).contains(r) { return nil }
            return (l, e, app.sit(l))
        }
    }

    var body: some View {
        NavigationStack {
            let todas = linhas
            let pend = todas.filter { $0.2.atencao }.sorted { a, b in
                a.2.ordem != b.2.ordem ? a.2.ordem < b.2.ordem : (a.2.dias ?? 99999) < (b.2.dias ?? 99999)
            }
            let conds = app.condicionantesPendentes(rt: rtId)
            List {
                Section {
                    HStack(spacing: 10) {
                        stat(todas.filter { $0.2.cor == .vermelho }.count, "Vermelho", .red)
                        stat(todas.filter { $0.2.cor == .ambar }.count, "Renovação", .orange)
                        stat(todas.filter { $0.2.cor == .verde }.count, "Em dia", .green)
                        stat(conds.count, "Condic.", .secondary)
                    }
                    .listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                }
                Section("01 · Licenças") {
                    if pend.isEmpty { Text("Nada pendente.").foregroundStyle(.secondary) }
                    ForEach(pend, id: \.0.id) { (l, e, s) in
                        NavigationLink(value: l.id) {
                            VStack(alignment: .leading, spacing: 5) {
                                HStack { Etiqueta(texto: Tipos.curto(l.tipo)); Text("\(e.sigla) · \(e.nome)").font(.subheadline.weight(.semibold)).lineLimit(1) }
                                HStack { Chip(sit: s); Spacer(); Text(Datas.diasTxt(s.dias)).font(.caption).foregroundStyle(.secondary) }
                                if let n = s.nota { Text(n).font(.caption).foregroundStyle(.secondary) }
                            }
                        }
                    }
                }
                Section("02 · Condicionantes") {
                    if conds.isEmpty { Text("Nenhuma nos próximos \(app.dados.cfg.avisoCondicionante) dias.").foregroundStyle(.secondary) }
                    ForEach(conds) { p in
                        HStack(alignment: .top) {
                            NavigationLink(value: p.lic.id) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Etiqueta(texto: p.cond.tipo == "recorrente" ? (p.cond.periodicidade == "semestral" ? "Semestral" : "Anual") : "Prazo")
                                        Text(p.emp.sigla).font(.subheadline.weight(.semibold))
                                    }
                                    Text(p.cond.descricao).font(.subheadline).lineLimit(3)
                                    Text("\(p.cond.tipo == "recorrente" ? "Próxima entrega" : "Prazo") \(Datas.br(p.cond.prazo ?? p.cond.proxima)) · \(p.dias < 0 ? "atrasada \(-p.dias) d" : "em \(p.dias) d")")
                                        .font(.caption).foregroundStyle(p.dias < 0 ? .red : .secondary)
                                }
                            }
                            Button(p.cond.tipo == "recorrente" ? "Entregue" : "Concluir") {
                                Task { try? await app.concluir(p) }
                            }
                            .buttonStyle(.bordered).font(.caption.weight(.semibold))
                        }
                    }
                }
            }
            .navigationTitle("Painel")
            .navigationDestination(for: String.self) { id in DetalheLoader(id: id) }
            .refreshable { await app.carregar() }
            .toolbar {
                if app.admin {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Picker("RT", selection: $rtSel) {
                                Text("Todos os RTs").tag("")
                                ForEach(app.dados.usuarios.filter { $0.role == "rt" }) { u in Text(u.nome).tag(u.id) }
                            }
                        } label: { Image(systemName: rtSel.isEmpty ? "person.2" : "person.2.fill") }
                    }
                }
            }
        }
    }

    func stat(_ n: Int, _ t: String, _ c: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(n)").font(.title2.bold()).foregroundStyle(c)
            Text(t).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
    }
}

struct DetalheLoader: View {
    @EnvironmentObject var app: AppState
    var id: String
    var body: some View {
        if let l = app.dados.licencas.first(where: { $0.id == id }) {
            LicencaDetalhe(l: l, novo: false).id(l.rev)
        } else {
            Text("Licença não encontrada.").foregroundStyle(.secondary)
        }
    }
}
