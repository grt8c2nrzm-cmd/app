import SwiftUI

struct RelatorioView: View {
    @EnvironmentObject var app: AppState
    @State private var ini = Datas.somar(Datas.hoje, dias: -6)
    @State private var fim = Datas.hoje

    private struct Item { var emp: Emp; var lic: Licenca; var movs: [Mov] }

    private var grupos: [(String, [(Emp, [Item])])] {
        var porLR: [String: [String: [Item]]] = [:]
        var emps: [String: Emp] = [:]
        for l in app.dados.licencas where ["LO", "ALVARA", "AVCB", "OUTORGA"].contains(l.tipo) {
            guard let e = app.emp(l.empId) else { continue }
            let ms = (l.movimentacoes ?? []).filter { $0.data >= ini && $0.data <= fim }.sorted { $0.data < $1.data }
            if ms.isEmpty { continue }
            let lr = (e.lr ?? "").isEmpty ? "Sem LR" : e.lr!
            porLR[lr, default: [:]][e.id, default: []].append(Item(emp: e, lic: l, movs: ms))
            emps[e.id] = e
        }
        return porLR.keys.sorted().map { lr in
            let porEmp = porLR[lr]!
            let lista = porEmp.keys.compactMap { emps[$0] }.sorted { $0.sigla < $1.sigla }.map { e in (e, porEmp[e.id]!) }
            return (lr, lista)
        }
    }

    private var texto: String {
        var t = "MOVIMENTAÇÕES DE RENOVAÇÃO — \(Datas.br(ini)) a \(Datas.br(fim))\n"
        for (lr, emps) in grupos {
            t += "\nLR: \(lr)\n"
            for (e, itens) in emps {
                t += "\n\(e.sigla) — \(e.nome)\n"
                for it in itens {
                    t += "  \(Tipos.curto(it.lic.tipo))\(it.lic.numero.map { $0.isEmpty ? "" : " nº " + $0 } ?? "")\n"
                    for m in it.movs { t += "   • \(Datas.br(m.data)) — \(m.texto)\n" }
                }
            }
        }
        return t
    }

    var body: some View {
        NavigationStack {
            let g = grupos
            List {
                Section {
                    DataCampo(titulo: "De", valor: $ini)
                    DataCampo(titulo: "Até", valor: $fim)
                }
                if g.isEmpty {
                    Text("Sem movimentações no período. Registre andamentos dentro de cada licença.").foregroundStyle(.secondary)
                }
                ForEach(g, id: \.0) { (lr, emps) in
                    Section("LR: \(lr)") {
                        ForEach(emps, id: \.0.id) { (e, itens) in
                            VStack(alignment: .leading, spacing: 6) {
                                Text("\(e.sigla) — \(e.nome)").font(.subheadline.weight(.bold))
                                ForEach(itens, id: \.lic.id) { it in
                                    Text("\(Tipos.curto(it.lic.tipo))\(it.lic.numero.map { $0.isEmpty ? "" : " nº " + $0 } ?? "")")
                                        .font(.caption).foregroundStyle(.secondary)
                                    ForEach(it.movs) { m in
                                        Text("• \(Datas.br(m.data)) — \(m.texto)").font(.subheadline)
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .navigationTitle("Relatório semanal")
            .refreshable { await app.carregar() }
            .toolbar {
                if !g.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) { ShareLink(item: texto) { Image(systemName: "square.and.arrow.up") } }
                }
            }
        }
    }
}
